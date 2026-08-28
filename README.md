# 📱 Smart Finance Tracker

A 100% offline, privacy-first personal finance management application powered by Flutter, SQLite, and On-Device Machine Learning. Automatically track your bank transactions, analyze spending habits, and manage budgets — with zero data ever leaving your phone.

---

## ✨ Features

- ⚡ **Automated SMS & Notification Tracking**: Intercepts bank SMS and UPI notifications on Android to record debits, credits, and transfers automatically.
- 🧠 **On-Device Machine Learning**: Uses a fast 2-Gram Perceptron classifier that learns your spending habits and categorizes merchants automatically.
- 🔒 **100% Offline & Private**: Runs entirely on your device with no internet connection (`android.permission.INTERNET` is omitted).
- 📊 **Interactive Analytics**: Gain insights with Donut category charts and Bar trend charts. Filter by *This Month*, *This Week*, *This Year*, or custom date ranges.
- 📥 **Inbox Verification**: Review auto-captured drafts, edit categories or accounts, and confirm transactions with a single tap.
- 📁 **Backup & Restore**: Easily back up your entire database to a JSON file or export your transactions to a CSV spreadsheet.
- 🌐 **Multi-Language Support**: Seamlessly switch between **English** and **Telugu** (`తెలుగు`).

---

## 🚀 Getting Started

### Prerequisites
- Android device running Android 8.0 (API level 26) or higher.
- Flutter SDK (version 3.x+).

### Quick Setup

1. **Install and Launch App**: Open Smart Finance Tracker on your Android device.
2. **Grant Notification Permission**:
   - Navigate to **Settings $\rightarrow$ Smart Tracking**.
   - Tap **Grant Notification Access** and enable permission for **Smart Finance Tracker**.
3. **Select Tracked Apps**: Choose which banking and UPI apps (e.g., GPay, PhonePe, Paytm, SMS) to monitor.

---

## 📖 How to Use

### 1. Auto-Capturing Transactions
When you pay or receive money via UPI/SMS, the app captures the details and stages a draft in your **Inbox** tab. If the machine learning model is confident ($\ge 85\%$), the transaction is auto-confirmed immediately!

### 2. Reviewing Drafts in Inbox
Open the **Inbox** tab to review pending drafts:
- **Confirm**: Accepts the transaction and teaches the ML model your preferred category.
- **Edit**: Adjust the account or category before saving.
- **Discard**: Dismisses notifications that aren't financial transactions.

### 3. Backup and Data Portability
- Navigate to **Settings $\rightarrow$ Import Data / Restore**.
- **Export**: Save a `.json` backup file or share a `.csv` spreadsheet.
- **Restore / Import**: Pick a `.json` backup file to restore your database on a new device.

---

## 🛠️ Developer & Architecture Documentation

For complete technical specifications, architecture designs, flowcharts, and schema definitions, check out the developer documentation:

- 🏛️ **[High-Level Design (HLD)](docs/HLD.md)** — System architecture, security model, and end-to-end Mermaid flowcharts.
- 🔬 **[Low-Level Design (LLD)](docs/LLD.md)** — Class hierarchy, sequence diagrams, and isolate threading.
- 🗄️ **[Database Schema Specification](docs/architecture/database_schema.md)** — SQLite schema definitions, indexes, and timestamp standards.
- ⚙️ **[Notification Pipeline](docs/architecture/notification_pipeline.md)** — Android OS listener service and background queue architecture.
- 🧠 **[ML Classifier Engine](docs/architecture/ml_classifier_engine.md)** — Perceptron ML model and feature extraction engine.
