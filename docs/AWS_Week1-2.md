# AWS Woche 1–2: Grundlagen (EC2, S3, RDS)

## 🎯 Ziele
- EC2: Linux-VM starten und per SSH verbinden.
- S3: Bucket anlegen, Datei hochladen, Versioning + Lifecycle.
- RDS: PostgreSQL-Datenbank anlegen und mit psql verbinden.

---

## ⚙️ Übungen

### EC2
1. Starte `t2.micro` (Amazon Linux 2, Free Tier).
2. Security Group: Port 22 öffnen.
3. SSH:
```bash
ssh -i mykey.pem ec2-user@<EC2-IP>
uname -a && whoami
```

### S3
```bash
aws s3 mb s3://mein-bucket-$RANDOM
echo "Hello AWS" > hello.txt
aws s3 cp hello.txt s3://mein-bucket-XYZ/
```
- Versioning aktivieren.
- Lifecycle-Rule: 30 Tage → Standard-IA.

### RDS PostgreSQL
1. DB-Instance (db.t3.micro, Free Tier) starten.
2. Port 5432 öffnen.
3. Mit psql verbinden:
```bash
psql -h <endpoint> -U <user> -d <dbname>
```

---

## 📚 Ressourcen
- LinkedIn Learning: AWS für Einsteiger, EC2 + S3 + RDS Kapitel
- YouTube: [EC2 Basics](https://www.youtube.com/watch?v=Uu36v75fQ6Y), [S3 Tutorial](https://www.youtube.com/watch?v=77qj5k5N_48), [RDS Tutorial](https://www.youtube.com/watch?v=HjvUq8L2JxI)
- AWS Docs: [EC2 Getting Started](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html), [S3 Getting Started](https://docs.aws.amazon.com/AmazonS3/latest/gsg/GetStartedWithS3.html), [RDS Postgres Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.PostgreSQL.html)

---

## 🏆 Optional
- Apache/Nginx auf EC2 installieren.
- Statische Website auf S3 hosten.
- RDS: Backup & Restore ausprobieren.
