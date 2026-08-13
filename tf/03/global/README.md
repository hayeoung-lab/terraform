# S3 원격 상태 스토리지 (Remote Backend)

로컬에만 저장되던 `terraform.tfstate`를 팀원들과 공유 가능한 AWS S3로 옮기고,
DynamoDB로 동시 작업 시 충돌을 방지하는 실습입니다.

## 왜 필요한가

로컬 state로 여러 명이 같은 인프라를 관리하면 3가지 문제가 생깁니다.

- **공유 문제**: state가 내 컴퓨터에만 있어 다른 팀원이 볼 수 없음
- **잠금 문제**: 두 명이 동시에 apply하면 state 파일이 충돌하거나 손상됨
- **시크릿 문제**: state 파일은 평문 저장이라 Git에 올리면 DB 비밀번호 등이 노출됨

## 구조

```
global/
├── s3/          # 공용 state 저장소 (S3 버킷 + DynamoDB 락 테이블)
│   └── main.tf
└── instance/    # 위 S3를 backend로 사용하는 테스트 프로젝트
    └── main.tf
```

## 핵심 개념

| 구성요소 | 역할 |
|---|---|
| S3 버킷 | tfstate 파일을 보관하는 공유 창고 |
| DynamoDB 테이블 | apply 중 락(lock)을 걸어 동시 접근 차단 |
| `backend "s3"` | "내 state는 여기(S3)에 저장해라"는 설정 |

## global/s3 — 저장소 생성

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "<유일한 버킷 이름>"   # 전 세계에서 유일해야 함
  force_destroy = true
}

resource "aws_dynamodb_table" "terraform-locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

## global/instance — backend 연결

```hcl
terraform {
  backend "s3" {
    bucket         = "<위와 동일한 버킷 이름>"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

`terraform init` 실행 시 아래 질문에 `yes` 하면 로컬 state가 S3로 이관됩니다.

```
Do you want to copy existing state to the new backend?
```

## 트러블슈팅

- **BucketAlreadyExists**: S3 버킷 이름은 AWS 전체(전 세계)에서 유일해야 함. 겹치면 이름에 고유 접미사 추가
- **Deprecated Parameter (dynamodb_table)**: 최신 AWS provider는 `use_lockfile = true`를 권장. 당장은 경고일 뿐 동작에는 문제없음

## 사용법

```bash
# 1) 저장소 생성
cd global/s3
terraform init && terraform apply

# 2) backend 연결 테스트
cd ../instance
terraform init   # "yes" 입력 시 로컬 state를 S3로 이관
terraform apply
```

## 확인

AWS 콘솔 → S3 → 생성한 버킷 → `global/s3/terraform.tfstate` 파일 존재 확인
AWS 콘솔 → DynamoDB → `terraform-locks` 테이블 확인 (apply 중일 때 락 레코드 생성됨)

## 정리 (역순 필수)

```bash
cd global/instance
terraform destroy -auto-approve

cd ../s3
terraform destroy -auto-approve
```
