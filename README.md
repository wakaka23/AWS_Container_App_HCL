## システム構成図
![image](https://github.com/user-attachments/assets/4c709327-a84f-4f2e-bb7b-7e41beab9b5d)
![image](https://github.com/user-attachments/assets/3503428e-935e-4c5d-ac76-14c4f4893eb2)
<br><br>

## ディレクトリ構成
```
├─ environments
│  ├─ prd
│  ├─ stg
│  └─ dev
│     ├─ main.tf
│     ├─ local.tf
│     ├─ variable.tf
│     └─ (terraform.tfvars)
│
└─ modules(各Moduleにmain.tf,variable.tf,output.tfが存在)
      ├─ alb_ingress(Public ALB関連のリソース）
      ├─ alb_internal(Private ALB関連のリソース）
      ├─ ec2(管理EC2関連のリソース）
      ├─ ecr(ECR関連のリソース）
      ├─ ecs_backend(Backend ECS関連のリソース）
      ├─ ecs_frontend(Frontend ECS関連のリソース）
      ├─ initializer（tfstate用S3バケット作成）
      ├─ network（VPC、Subnet、VPNなどネットワーク全般のリソース）
      ├─ rds（RDS関連のリソース）
      └─ secrets_manager（Secrets Manager関連のリソース）
```
