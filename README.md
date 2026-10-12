# PostgreSQL Backup & Script Runner Tool

Simple, clean bash scripts and Jenkins pipeline to:
1. **DUMP**: Create database backups from Docker container and download them.
2. **RUN_SCRIPT**: Execute SQL scripts directly inside the PostgreSQL Docker container without dropping/wiping the entire database.

---

## 📁 Repository Files

- **`dump.sh`**: Dumps database from PostgreSQL Docker container and downloads it to workspace.
- **`run-script.sh`**: Executes a `.sql` or `.sh` script directly inside the Docker container via `psql`.
- **`restore.sh`**: Helper script supporting both script execution and full dump restores.
- **`Jenkinsfile`**: Self-service pipeline for Jenkins.

---

## 💻 Running Locally

### 1. Take DB Dump:
```bash
./dump.sh
```

### 2. Run SQL Script on Container:
```bash
./run-script.sh update_data.sql
```

---

## 🚀 Running in Jenkins

### Action 1: `DUMP`
- Takes a fresh PostgreSQL dump and archives it for download under Jenkins Build Artifacts.

### Action 2: `RUN_SCRIPT`
Executes SQL queries or scripts inside the container without touching the rest of the database:
- **Option A (File Upload):** Upload a `.sql` file via `SCRIPT_FILE_UPLOAD`.
- **Option B (Paste SQL):** Paste SQL statements directly into the `SQL_QUERY_OR_SCRIPT` text box.
- **Option C (File Path):** Specify a script path in `SCRIPT_FILE_PATH`.
