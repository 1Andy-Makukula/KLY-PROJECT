# KithLy Global Protocol - Setup Guide 🛠️

## 1. Prerequisites (Manual Installation Required)

Before running the project, please ensure the following tools are installed:

### A. Flutter SDK (Essential for Mobile App)
1.  **Download**: [Flutter Windows Install](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip)
2.  **Extract**: Unzip to `C:\src\flutter` (Create folder if needed).
3.  **Update Path**:
    *   Search "Edit environment variables for your account" in Windows Start.
    *   Edit `Path` variable.
    *   Add new entry: `C:\src\flutter\bin`.
4.  **Verify**: Open new terminal and run `flutter doctor`.

### B. PostgreSQL (Database)
1.  **Download**: [PostgreSQL 16](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads)
2.  **Install**: Use default settings (Port 5432). Remember your password (default `postgres`).
3.  **Extension**: Open "Stack Builder" (installed with Postgres) and install **PostGIS**.

### C. C++ Compiler (For Engine)
*   **MinGW-w64**: [Download Installer](https://sourceforge.net/projects/mingw-w64/)
*   **Or Visual Studio**: Install "Desktop development with C++" workload.

---

## 2. Automated Setup (Script)

Once prerequisites are installed, run the automated setup script to configure Python and dependencies:

```powershell
.\setup_env.ps1
```

This script will:
1.  Create a Python virtual environment (`03_gateway/venv`).
2.  Install all Python dependencies (`fastapi`, `asyncpg`, etc.).
3.  Check connection to Flutter and C++ tools.

---

## 3. Running the Project

### Terminal 1: Database & Backend
```bash
cd 03_gateway
.\venv\Scripts\activate
uvicorn main:app --reload
```

### Terminal 2: Flutter App
```bash
cd 04_skin
flutter run
```

### Terminal 3: C++ Engine (Optional for Dev)
```bash
cd 02_engine
g++ src/orchestrator.cpp -o orchestrator.exe
.\orchestrator.exe
```
