# ASG + ALB Web Server Cluster

Auto Scaling Group과 Application Load Balancer를 연동한 실습입니다.
SPOF(단일 장애점) 문제를 해결하기 위해 EC2를 자동으로 관리하고, 그 앞에 로드밸런서를 배치합니다.

## 구조

```
사용자
  │
  ▼
ALB (Listener:80)
  │  target_group_arns로 연결
  ▼
Target Group (health_check: "/" 200 확인, 15초 간격)
  │
  ▼
ASG (min=2, max=10, health_check_type="ELB")
  │  launch_configuration
  ▼
EC2 x N대 (busybox 웹서버, 8080 포트)
```

## 파일 구성

| 파일 | 역할 |
|---|---|
| `main.tf` | Provider, Data Source, ASG, ALB 리소스 정의 |
| `variables.tf` | 포트, 이름 등 입력 변수 |
| `outputs.tf` | ALB DNS 이름 출력 |

## 핵심 개념

- **Data Source**: `aws_vpc`/`aws_subnets`로 기본 VPC 조회, `aws_ami`로 최신 AMI 자동 조회 (하드코딩 방지)
- **Launch Configuration**: EC2 설계도. `lifecycle { create_before_destroy = true }`로 교체 시 다운타임 최소화
- **health_check_type = "ELB"**: EC2 자체 상태보다 정밀하게 장애 감지 (메모리 부족 등도 포함)
- **target_group_arns**: ASG가 만든 EC2를 Target Group에 자동 등록/해제

## 사용법

```bash
terraform init
terraform plan
terraform apply

curl http://$(terraform output -raw alb_dns_name)
```

## 정리

```bash
terraform destroy -auto-approve
```
