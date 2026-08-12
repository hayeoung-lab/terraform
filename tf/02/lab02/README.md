# Learn Terraform variables

You can use input variables to customize your Terraform configuration with
values that can be assigned by end users of your configuration. Input variables
allow users to re-use and customize configuration by providing a consistent
interface to change how a given configuration behaves.

Follow along with this [Learn Terraform variables](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables) tutorial.

## 서브넷 개수 설계 (2개 ~ 8개)

`public_subnet_cidr_blocks`, `private_subnet_cidr_blocks` 변수에 CIDR 후보를
**8개까지 미리 정의**해두고, 실제로 몇 개를 쓸지는
`public_subnet_count`, `private_subnet_count` 변수로 별도 지정한다.

```hcl
variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default = [
    "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24",
    "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24",
  ]
}

variable "public_subnet_count" {
  description = "Number of public subnets."
  type        = number
  default     = 2
}
```

- 최대 8개인 이유: AWS 리전당 가용영역(AZ)이 보통 3~6개 수준이라, 그 이상 늘릴 일이 거의 없어 여유값으로 8개
- 최소 2개인 이유: 서로 다른 AZ에 최소 2개는 있어야 고가용성 확보 (ALB도 최소 2개 서브넷 요구)

## slice()를 쓴 이유

CIDR 후보 리스트(list)와 실제 사용 개수(count)를 분리해서 관리하기 위해.
개수만 바꾸면 CIDR을 재작성하지 않아도 서브넷 수를 유연하게 조절할 수 있음.

```hcl
public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)
private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
```
