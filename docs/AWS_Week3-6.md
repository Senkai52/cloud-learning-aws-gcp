# AWS Woche 3–6: APIs & Serverless

## 🎯 Ziele
- FastAPI CRUD-App lokal entwickeln (SQLAlchemy, Alembic).
- Erste Lambda-Funktion + API Gateway.
- FastAPI über SAM auf Lambda deployen.

---

## ⚙️ Übungen

### FastAPI lokal
- CRUD für `products` mit SQLAlchemy + Alembic.

### Lambda Hello World
```python
def handler(event, context):
    return {"statusCode": 200, "body": "Hello World"}
```

### FastAPI auf Lambda (SAM)
```bash
sam build && sam deploy --guided
```

---

## 📚 Ressourcen
- LinkedIn Learning: Building APIs with FastAPI, AWS Developer: Lambda & API Gateway
- YouTube: FastAPI Crash Course, Lambda Basics
- AWS Docs: [Lambda Getting Started](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html), [AWS SAM](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/)
