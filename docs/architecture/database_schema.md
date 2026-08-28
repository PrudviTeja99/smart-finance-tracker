# Database Schema Specification

## 1. Overview
The database uses SQLite managed via the `sqflite` Flutter package. All database tables store dates as 64-bit integer Unix epoch milliseconds (`timestamp INTEGER NOT NULL`).

---

## 2. Table Definitions

### 2.1. `accounts`
Stores payment accounts (Bank, Card, Wallet, Cash).

```sql
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,         -- 'bank', 'credit_card', 'wallet', 'cash'
  keywords TEXT NOT NULL,     -- Comma-separated matching keywords
  balance REAL NOT NULL       -- Current calculated balance
);
```

### 2.2. `categories`
Stores expense and income classification categories.

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  color INTEGER NOT NULL,     -- ARGB 32-bit color integer
  icon TEXT NOT NULL          -- Material icon string key
);
```

### 2.3. `transactions`
Primary table for financial debit, credit, and transfer records.

```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  app_name TEXT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,         -- 'debit', 'credit', 'transfer'
  account_id INTEGER NOT NULL,
  to_account_id INTEGER,
  category_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  timestamp INTEGER NOT NULL, -- Unix Epoch Milliseconds
  status TEXT NOT NULL,       -- 'confirmed', 'pending', 'archived'
  notification_log_id INTEGER,
  FOREIGN KEY (account_id) REFERENCES accounts (id),
  FOREIGN KEY (to_account_id) REFERENCES accounts (id),
  FOREIGN KEY (category_id) REFERENCES categories (id)
);

CREATE INDEX idx_transactions_timestamp ON transactions (timestamp);
CREATE INDEX idx_transactions_status ON transactions (status);
```

### 2.4. `notification_logs`
Stores audit records for intercepted notification messages.

```sql
CREATE TABLE notification_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  app_name TEXT,
  package_name TEXT,
  title TEXT,
  body TEXT,
  timestamp INTEGER NOT NULL, -- Unix Epoch Milliseconds
  status TEXT NOT NULL DEFAULT 'unclassified'
);

CREATE INDEX idx_notification_logs_status ON notification_logs (status);
CREATE INDEX idx_notification_logs_timestamp ON notification_logs (timestamp);
```

### 2.5. `raw_notification_queue`
Zero-battery staging queue for incoming background notifications.

```sql
CREATE TABLE raw_notification_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  package_name TEXT NOT NULL,
  title TEXT,
  body TEXT NOT NULL,
  timestamp INTEGER NOT NULL, -- Unix Epoch Milliseconds
  status TEXT DEFAULT 'pending'
);

CREATE UNIQUE INDEX idx_raw_notif_dedup ON raw_notification_queue(package_name, body, timestamp);
```

### 2.6. `classifier_state`
Key-value store for machine learning model weight table dumps.

```sql
CREATE TABLE classifier_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

### 2.7. `model_audit_log`
Logs automated decisions made by the Perceptron classification engine.

```sql
CREATE TABLE model_audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action_type TEXT NOT NULL,  -- 'auto_confirmed', 'draft_created'
  app_name TEXT,
  package_name TEXT NOT NULL,
  title TEXT,
  body TEXT NOT NULL,
  confidence REAL NOT NULL,
  timestamp INTEGER NOT NULL, -- Unix Epoch Milliseconds
  log_id INTEGER
);
```

