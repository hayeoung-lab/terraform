# Mini Project 2 - 3-Tier 구조 (ALB - ASG - RDS Cluster)

ELB(ALB) - TG(ASG(EC2 WEB/WAS x2)) - DB Cluster(RDS MySQL x2) 구조의
3-Tier 웹 인프라를 Terraform 모듈 기반으로 설계 및 구현한 프로젝트입니다.

- 리전: ap-northeast-2 (서울)
- VPC: 신규 생성 (Public Subnet x2, Private Subnet x2, 서로 다른 가용영역)
- state 관리: S3 + DynamoDB를 활용한 원격 백엔드 구성

## 구조

```
mini2/
├── global/s3/                 # state 저장소 (S3 + DynamoDB)
├── modules/
│   ├── net/                    # VPC, Public/Private Subnet 생성
│   ├── db/                     # RDS Primary/Replica 클러스터 생성
│   └── web/                    # ALB + ASG(EC2 WEB/WAS) 생성
└── data-stores/db-cluster/     # net + db 모듈을 조립하여 실제 배포
```

## 아키텍처

```
                        Internet
                            │
                            ▼
                    Internet Gateway
                            │
┌───────────────────── VPC: db-vpc ─────────────────────────┐
│                            │                                 │
│                    ALB (web-alb) : 80                        │
│                            │                                 │
│                    Target Group : 8080                       │
│                            │                                 │
│   ┌── Public Subnet-0 ──┐   ┌── Public Subnet-1 ──┐         │
│   │ EC2 (WEB/WAS)         │   │ EC2 (WEB/WAS)         │         │
│   │ httpd + php           │   │ httpd + php           │         │
│   └───────────┬──────────┘   └───────────┬──────────┘         │
│               │  VPC 내부 local 라우팅        │                    │
│               ▼                             ▼                    │
│   ┌── Private Subnet-0 ──┐   ┌── Private Subnet-1 ──┐         │
│   │ RDS Primary (MySQL)   │──▶│ RDS Replica (읽기전용) │         │
│   └───────────────────────┘   └───────────────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────┘
```

## 구성 순서와 그 이유

| 순서 | 작업 | 이유 |
|---|---|---|
| 1 | `global/s3` (S3 + DynamoDB) | 이후 모든 프로젝트가 state를 저장/공유할 창고가 먼저 존재해야 함 |
| 2 | `modules/net`, `modules/db`, `modules/web` 작성 | 반복되는 인프라 패턴을 재사용 가능한 부품으로 미리 설계 (실행은 하지 않음) |
| 3 | `data-stores/db-cluster` (net + db 모듈 조립) | VPC/Subnet과 RDS를 실제로 생성. 웹서버가 DB 정보를 참조하려면 DB가 먼저 존재해야 함 |
| 4 | (예정) 웹서버 배포 시 `web` 모듈에서 db-cluster의 output(vpc_id, public_subnet_ids)을 `terraform_remote_state`로 참조 | 별도 VPC를 새로 만들지 않고, DB가 만든 VPC의 Public Subnet을 그대로 재사용하여 Web↔DB가 같은 네트워크(local 라우팅)로 통신 가능하도록 구성 |

## 생성한 모듈과 역할

### modules/net — 네트워크 기반 모듈

- VPC, Internet Gateway, Public/Private Subnet, Route Table 생성
- CIDR, 가용영역, 서브넷 개수를 변수로 받아 재사용 가능하도록 설계
- Public Subnet에 `map_public_ip_on_launch = true`, Public Route Table에 `0.0.0.0/0 → IGW` 등록
- output으로 `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids` 노출

### modules/db — 데이터베이스 모듈

- RDS(MySQL) Primary/Replica 인스턴스와 관련 보안 그룹 생성
- `aws_db_subnet_group`으로 Private Subnet에만 DB 배치 (외부 노출 차단)
- SG는 VPC 내부 CIDR에서만 3306 포트 접근 허용
- Primary + Replica 구조로 DB 이중화(클러스터) 구성 (`backup_retention_period` 필수 설정)
- 계정 정보는 `sensitive = true` 처리, 환경변수(`TF_VAR_`)로 주입
- output으로 `primary_address`, `primary_port` 노출 → 웹서버 모듈이 참조

### modules/web — 웹서버 클러스터 모듈

- ALB, Target Group, ASG(EC2 WEB/WAS)를 생성
- ALB용 SG(80 인바운드)와 EC2용 SG(ALB로부터만 8080 허용)를 분리하여 최소 권한 원칙 적용
- Launch Template의 user_data로 httpd, php 설치 및 DB 접속 정보 페이지 자동 구성
- ASG min/max를 2로 고정하여 WEB/WAS 이중화 구성
- `db_address`, `db_port`를 입력변수로 받아 `templatefile()`로 user_data에 동적 삽입

## 트러블슈팅

- **RDS Replica 생성 실패 (InvalidDBInstanceState)**: Primary에 자동 백업(`backup_retention_period`)이
  비활성화된 상태에서는 Read Replica를 생성할 수 없음. `backup_retention_period = 1` 이상으로 설정 필요
- **설정 변경이 "보류 중"으로 남는 문제**: RDS 콘솔에서 변경사항이 기본적으로 다음 유지관리 시간대에
  적용되도록 예약됨. `--apply-immediately` 옵션으로 즉시 반영 강제 가능

## 보안 및 운영 고려사항

- state 파일에는 DB 계정 정보가 평문으로 남으므로, S3 버킷에 서버측 암호화(SSE-S3)와
  퍼블릭 액세스 차단 적용
- DynamoDB를 통한 state 잠금으로 동시 apply 충돌 방지
- DB는 Private Subnet에만 위치시켜 외부에서 직접 접근 불가능하도록 구성
- 삭제 시 웹서버 → DB → state 저장소 순으로 역순 삭제

## 사용법

```bash
# 1) 저장소
cd global/s3 && terraform init && terraform apply -auto-approve

# 2) DB (S3 버킷 이름을 1단계 결과에 맞춰 backend 수정 후)
cd ../../data-stores/db-cluster
export TF_VAR_dbuser="admin"
export TF_VAR_dbpassword="password"
terraform init && terraform apply -auto-approve
```

## 정리 (역순 필수)

```bash
cd data-stores/db-cluster && terraform destroy -auto-approve
cd ../../global/s3 && terraform destroy -auto-approve
```
