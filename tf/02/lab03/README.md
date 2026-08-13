# Learn Terraform outputs

This repo is a companion repo to the [Learn Terraform outputs](https://developer.hashicorp.com/terraform/tutorials/configuration-language/outputs) tutorial.
It contains Terraform configuration you can use to learn how Terraform output values allow you to export structured data about your resources.

# Output 변수 실무 실습 (VPC/ELB/EC2)

Terraform 출력 값(output)을 사용하여 리소스 정보를 구조화된 형태로 내보내는 실습입니다.
VPC, 로드밸런서, EC2, DB로 구성된 인프라를 배포하고 output으로 필요한 정보를 확인합니다.

## 구조

```
module.vpc          → VPC 생성
module.elb_http     → 로드밸런서 생성
module.ec2_instances → EC2 여러 대 생성 (로컬 모듈: modules/aws-instance)
aws_db_instance      → DB 생성 (민감정보 포함)
```

## outputs.tf 핵심

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "lb_url" {
  value = "http://${module.elb_http.elb_dns_name}/"
}

output "web_server_count" {
  value = length(module.ec2_instances.instance_ids)
}

output "db_username" {
  value     = aws_db_instance.database.username
  sensitive = true
}

output "db_password" {
  value     = aws_db_instance.database.password
  sensitive = true
}
```

## 핵심 개념

- **모듈 output 재노출**: 자식 모듈(`module.vpc`)의 output을 루트 모듈에서 다시 `output`으로 꺼내야 밖에서 조회 가능
- **표현식을 사용한 output**: 문자열 보간(`"http://${...}/"`), 함수(`length()`) 적용 가능
- **sensitive = true의 한계**: 화면 출력만 가려짐. `terraform output db_password`로 직접 조회하면 그대로 노출되고, `terraform.tfstate` 파일에도 평문으로 저장됨 → 진짜 보안은 remote backend(S3 암호화) + Vault 등 시크릿 관리 도구로 해결해야 함
- **JSON 출력**: `terraform output -json`으로 자동화 도구가 파싱하기 좋은 형태 제공

## 사용법

```bash
terraform init
terraform apply -auto-approve

terraform output                      # 전체 조회
terraform output -raw lb_url          # 값만 추출
curl $(terraform output -raw lb_url)  # 바로 테스트

terraform output -json                # JSON 형식
```

## 정리

```bash
terraform destroy
```
