# Jenkins Self-Service PostgreSQL Database Backup & Restore Pipeline

This repository provides an automated **Jenkins CI/CD Self-Service Pipeline** and **Modular Bash Automation Scripts** for PostgreSQL databases running in Docker containers behind restricted firewalls.

---

## 📥 1. Where Developer Gets (Downloads) the DB Dump

When a developer triggers `ACTION = DUMP`:

1. Jenkins connects to the DB server, runs `pg_dump`, and fetches the generated `.dump` file.
2. Jenkins saves it as a **Build Artifact**.
3. **Where to download:**
   - Go to **Jenkins UI** -> Job `Database-Self-Service`.
   - Click on the completed build number (e.g. **Build #12**).
   - Under **Build Artifacts** at the top of the page, click on the `.dump` file (e.g. `postgres_local_20261008_112000.dump`).
   - The file will download directly to the developer's laptop!

```text
Jenkins Job Page -> Build #12 -> Build Artifacts -> 📥 postgres_local_20261008_112000.dump
```

---

## 📤 2. Where Developer Uploads the DB Dump to Restore

When a developer triggers `ACTION = RESTORE`:

1. Go to **Jenkins UI** -> Click **Build with Parameters**.
2. Select **ACTION**: `RESTORE`.
3. **Option A (Direct File Upload from Laptop):**
   - Click the **Choose File / Browse** button next to `DUMP_FILE_UPLOAD`.
   - Select the `.dump` file from their local laptop.
4. **Option B (Using Existing Dump File):**
   - Enter the file path in `RESTORE_DUMP_FILE` (e.g. `dumps/postgres_local_20261008_112000.dump`).
5. Click **Build**.
6. Jenkins will automatically transfer the file to the target DB server and execute `pg_restore` into the container.

---

## 🛡️ Security & Architecture

```text
  [ Developer Laptop ]
          │
          │ (1) Browser Interaction (Upload dump / Download dump artifact)
          ▼
┌─────────────────────────────────────────────────────────────┐
│                       JENKINS SERVER                        │
│  - Whitelisted in DB Server Firewall                        │
│  - Holds SSH Private Key (db-server-ssh-key)               │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               │ (2) SSH connection over whitelisted IP
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    TARGET DB SERVER                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Docker Container: landmark-db (PostgreSQL)            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

- **No SSH for Devs:** Developers never get SSH credentials or IP access to the database server.
- **Firewall Compliant:** Communication with the DB server strictly happens over Jenkins' whitelisted IP.
- **Pre-Restore Safety Snapshot:** Before wiping and restoring a database, an automated safety backup is created on the server.

---

## 📁 Repository Structure

```text
dump_cicd/
├── Jenkinsfile           # Jenkins Pipeline (Handles DUMP, RESTORE & File Uploads)
├── config.env            # Server and container default configurations
├── dump-db.sh            # Main executable for database dump
├── restore-db.sh         # Main executable for database restore
├── lib/
│   ├── common.sh         # Shared utilities (logging, SSH check, safety snapshot)
│   ├── dump_func.sh      # Database dump module
│   └── restore_func.sh   # Database restore module
├── README.md             # Complete DevOps & Developer Guide
└── .gitignore            # Prevents local .dump files from being committed
```
