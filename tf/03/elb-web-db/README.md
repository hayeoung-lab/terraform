# 3-Tier 구조 실습: ALB - ASG(EC2) - MySQL

`terraform_remote_state`를 활용해 서로 독립된 Terraform 프로젝트(DB팀 / 웹서버팀)가
S3에 저장된 state를 통해 정보를 주고받는 실습입니다.

## 구조

```
elb-web-db/
├── global/s3/                    # 공용 state 저장소 (S3 + DynamoDB)
└── stage/
    ├── data-stores/mysql/        # MySQL DB (S3에 자기 state 저장)
    └── services/webserver-cluster/  # ALB + ASG 웹서버 (mysql의 output을 remote_state로 참조)
```

## 만드는 순서 (반드시 이 순서대로)

```
1. global/s3               S3 버킷 + DynamoDB 락 테이블 생성
2. stage/data-stores/mysql  DB 생성, 자기 state를 위 S3에 저장 (backend "s3")
3. stage/services/webserver-cluster  DB의 output(address, port)을 remote_state로 읽어와 웹서버 구성
```

앞 단계가 완료되어야 다음 단계가 참조할 대상(S3 버킷, DB state)이 존재합니다.

## 핵심 흐름

```
DB 프로젝트
  └─ output "address", "port" 선언
  └─ backend "s3"로 자기 state를 S3에 저장
        │
        ▼
웹서버 프로젝트
  └─ data "terraform_remote_state"로 DB의 state를 읽어옴
  └─ templatefile(user-data.sh)에 db_address, db_port를 삽입
  └─ ASG가 관리하는 EC2들이 이 정보를 표시하는 웹서버로 동작
```

## 웹서버 구성 순서 (webserver-cluster/main.tf)

```
1. Default VPC/Subnet 조회 (data source)
2. (1) ALB 생성
   ① SG 생성 (80 인바운드 허용)
   ② Target Group 생성 (헬스체크: "/" 200 응답, 15초 간격)
   ③ LB(ALB) 생성 (위 SG 연결)
   ④ Listener 생성 (80포트, 기본 404)
   ⑤ Listener Rule 생성 (모든 경로 → Target Group forward)
3. (2) ASG 생성
   ① SG 생성 (8080 인바운드 허용)
   ② Launch Configuration 생성 (AMI + user_data로 DB 정보 삽입)
   ③ ASG 생성 (min=2, max=10, target_group_arns로 TG 연결)
```

## 비밀번호 관리

DB 계정 정보는 `.tf` 코드에 직접 쓰지 않고 환경변수로 주입합니다.

```bash
# db_credentials.sh (git에 올리지 않음, .gitignore 대상)
export TF_VAR_dbuser="admin"
export TF_VAR_dbpassword="password"
```

```bash
source db_credentials.sh
terraform apply
```

> `sensitive = true`는 화면 출력만 가려줄 뿐, tfstate 파일에는 평문으로 저장됩니다.
> 그래서 state를 저장하는 S3 버킷에는 암호화(SSE-S3), 퍼블릭 액세스 차단을 반드시 설정합니다.

## 사용법

```bash
# 1) 저장소
cd global/s3 && terraform init && terraform apply -auto-approve

# 2) DB (버킷 이름을 1단계 결과에 맞춰 backend 수정 후)
cd ../../stage/data-stores/mysql
source db_credentials.sh
terraform init && terraform apply -auto-approve

# 3) 웹서버 (버킷/key 경로를 2단계 DB의 state 경로로 맞춰 수정 후)
cd ../../services/webserver-cluster
terraform init && terraform apply -auto-approve

curl $(terraform output -raw alb_dns_name)
```

## 정리 (역순 필수)

```bash
cd stage/services/webserver-cluster && terraform destroy -auto-approve
cd ../../data-stores/mysql && terraform destroy -auto-approve
cd ../../../global/s3 && terraform destroy -auto-approve
```
