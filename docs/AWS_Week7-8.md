# AWS Woche 7–8: Container & Deployment

## 🎯 Ziele
- Dockerize API + Push zu ECR.
- ECS Fargate Service mit ALB.

---

## ⚙️ Übungen

### Docker + ECR
```bash
aws ecr create-repository --repository-name fastapi-demo
docker build -t fastapi-demo:latest .
docker push <acct>.dkr.ecr.<region>.amazonaws.com/fastapi-demo:latest
```

### ECS Fargate
- Cluster & Task Definition anlegen.
- Service mit ALB erstellen.

---

## 📚 Ressourcen
- LinkedIn Learning: Docker for Developers, AWS ECS Deep Dive
- YouTube: Docker + ECR, ECS Fargate Tutorial
- AWS Docs: [ECR Push Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html), [ECS Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
