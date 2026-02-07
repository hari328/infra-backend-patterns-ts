# infra-backend-patterns-ts
contains all the code to setup aws account for backend deployment

this folder will be deployed using terraform and github actions.

we are preparing a base aws infra and also observability tools like prometheus, loki, tempo, grafana.

we are deploying the services in the github repo: https://github.com/hari328/backend-patterns-ts

I have thought about how it should look the base-infra in the folder has the details needed.

---

I want to use terragrunt here not terraform


---
## the structure of the terraform folder

```
terraform/
├── modules/
│   ├── base-infra/
│   │   ├── networking/
│   │   ├── ecs-cluster/
│   │   ├── alb/
│   │   ├── dns-ssl/
│   │   ├── efs/
│   │   └── cognito/
│   └── monitoring/
│       ├── prometheus/
│       ├── loki/
│       ├── tempo/
│       ├── grafana/
│       └── otel/
├── stage/
│   ├── env.yaml
│   └── us-east-1/
│       ├── base-infra/
│       │   ├── networking/terragrunt.hcl
│       │   ├── ecs-cluster/terragrunt.hcl
│       │   └── ...
│       └── monitoring/
│           ├── prometheus/terragrunt.hcl
│           └── ...
├── prod/
│   ├── env.yaml
│   └── us-east-1/
│       ├── base-infra/
│       │   └── ...
│       └── monitoring/
│           └── ...
└── terragrunt.hcl
```

