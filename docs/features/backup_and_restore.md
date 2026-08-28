# Backup & Restore Specification

## 1. Overview
The Backup & Restore engine (`BackupService`) allows users to export and import complete database snapshots in JSON or CSV formats.

---

## 2. Import Modes

### 2.1. Override Mode (Restore)
- Prompts for user confirmation before proceeding.
- Wipes all tables (`transactions`, `notification_logs`, `classifier_state`, `accounts`, `categories`).
- Inserts payload records directly from JSON backup file.

### 2.2. Append Mode (Import)
- Merges missing accounts and categories into the current database.
- Inserts new transaction items while running duplicate checks on `(body, amount, type, account_id)`.

---

## 3. JSON Payload Structure
```json
{
  "version": 2,
  "exported_at": 1787884400000,
  "accounts": [...],
  "categories": [...],
  "transactions": [...],
  "classifier_state": [...],
  "notification_logs": [...]
}
```

