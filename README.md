# PostgreSQL Backup & Script Runner Pipeline

A clean, self-service Jenkins pipeline and automation scripts for developers to:
1. **DUMP**: Export a database backup from the Docker container and download it directly from Jenkins.
2. **RUN_SCRIPT**: Paste and execute SQL commands/queries directly inside the PostgreSQL Docker container without wiping or restoring the entire database.

---

## 🔒 Security & Simplicity

- **Zero Server Access for Devs:** Server credentials, SSH keys, host IPs, and container details are securely stored in the pipeline environment. Developers never see or need them.
- **No File Uploads Needed:** Developers only select **`DUMP`** or **`RUN_SCRIPT`** and paste their SQL in a simple text area.

---

## 📋 Build Parameters in Jenkins

When developers click **Build with Parameters**, they only see two fields:

| Parameter | Type | Description |
| :--- | :--- | :--- |
| **`ACTION`** | Choice | `DUMP` (Backup DB) or `RUN_SCRIPT` (Execute SQL) |
| **`SQL_SCRIPT`** | Multi-line Text | Paste your SQL queries here (Only required for `RUN_SCRIPT`) |

---

## 🚀 How Developers Use It

### 1. To Get a Database Dump:
1. Open Jenkins job -> Click **Build with Parameters**.
2. Select **`ACTION = DUMP`**.
3. Click **Build**.
4. Once completed, open the build page and download the `.dump` file from **Build Artifacts**.

### 2. To Run a Script on the Database:
1. Open Jenkins job -> Click **Build with Parameters**.
2. Select **`ACTION = RUN_SCRIPT`**.
3. Paste your SQL script in the **`SQL_SCRIPT`** text box (e.g., `UPDATE ...;`, `ALTER TABLE ...;`, or migrations).
4. Click **Build**.
5. Check the console output to view execution results and affected rows.

---

## 🛠️ CLI / Local Execution

You can also run the scripts directly from the terminal if needed:

```bash
# Take a backup dump:
./dump.sh

# Run an SQL script inside the container:
./run-script.sh my_query.sql
```
