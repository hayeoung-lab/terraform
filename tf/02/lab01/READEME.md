# Terraform VPC Public/Private Network Lab

AWS VPC 기반 Public/Private 네트워크 구성 및 EC2 배포 실습입니다.
`main` → `main2` → `main3` 순서로 단계별로 네트워크 구조를 완성합니다.

## 구조 개요

```
myVPC
 ├─ Public Subnet  ── myPubEC2 (직접 인터넷 접속 가능)
 │                 └─ NAT-GW (Private용 중계)
 └─ Private Subnet ── myPriEC2 (NAT 통해서만 나감, 외부 노출 안 됨)
```

## 단계별 구성

### 1. main - VPC / Subnet / RT (Public 네트워크 골격)

```
myVPC (10.0.0.0/16)
 ├─ myIGW
 ├─ myPubSN (10.0.1.0/24)
 └─ myPubRT → IGW (0.0.0.0/0)
```

| 리소스 | 역할 |
|---|---|
| `myVPC` | 가상 네트워크 (10.0.0.0/16) |
| `myIGW` | 인터넷과 VPC를 연결하는 관문 |
| `myPubSN` | 공인 IP 자동 할당되는 서브넷 |
| `myPubRT` | 0.0.0.0/0 트래픽을 IGW로 라우팅 |

### 2. main2 - SG / EC2 (Public 서버 배포)

```
mySG (22/80/443 허용)
mykeypair (SSH 접속용)
   ↓
myPubEC2 (Public Subnet 위치)
 - httpd 자동 설치/기동
```

| 리소스 | 역할 |
|---|---|
| `mySG` | 22(SSH), 80(HTTP), 443(HTTPS) 인바운드 허용 |
| `mykeypair` | SSH 접속용 키페어 |
| `myPubEC2` | Public Subnet에 위치한 웹서버 |

### 3. main3 - NAT Gateway / Private Subnet / EC2 (Private 서버 배포)

```
myEIP + myNAT-GW (Public Subnet)
   ↓
myPriSN (10.0.2.0/24)
myPriRT → NAT-GW (0.0.0.0/0)
   ↓
mySG2 (22/80/443 허용)
myPriEC2 (Private, 공인 IP 없음)
 - httpd 자동 설치/기동
```

| 리소스 | 역할 |
|---|---|
| `myEIP` | NAT Gateway 전용 고정 공인 IP |
| `myNAT-GW` | Private Subnet의 아웃바운드 트래픽만 허용 (인바운드 차단) |
| `myPriSN` | 외부에서 직접 접근 불가능한 서브넷 |
| `myPriRT` | 0.0.0.0/0 트래픽을 NAT Gateway로 라우팅 |
| `myPriEC2` | Private Subnet에 위치한 내부 서버 |

## IGW vs NAT Gateway

| | IGW | NAT Gateway |
|---|---|---|
| 인바운드(외부→내부) | 가능 | 불가능 |
| 아웃바운드(내부→외부) | 가능 | 가능 |
| 적용 대상 | Public Subnet | Private Subnet |
| 목적 | 외부 노출이 필요한 서버 (웹서버 등) | 외부로부터 숨겨야 하는 서버 (DB 등) |

## 사용법

```bash
terraform init
terraform plan
terraform apply
```

## 삭제

```bash
terraform destroy
```
