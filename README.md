# PostgreSQL Backup & Restore Tool

Simple, clean bash scripts and Jenkins pipeline to take database dumps and restore them on remote servers running Docker.

---

## 📁 Repository Files

- **`dump.sh`**: Takes a PostgreSQL dump inside the Docker container and downloads it locally via `scp`.
- **`restore.sh`**: Uploads a `.dump` file and restores it into the Docker container using `pg_restore`.
- **`Jenkinsfile`**: Self-service pipeline for Jenkins (supports dump artifact downloading and file upload restores).

---

## 💻 Running Locally

### Take DB Dump:
```bash
./dump.sh
```

### Restore DB Dump:
```bash
./restore.sh dumps/postgres_local_20261008_140000.dump
```

---

## 🚀 Running in Jenkins

1. Push this repository to Git.
2. Create a Pipeline Job in Jenkins pointing to `Jenkinsfile`.
3. Add SSH Private Key credential `db-server-ssh-key`.
4. Click **Build with Parameters** -> Choose **DUMP** or **RESTORE**.
