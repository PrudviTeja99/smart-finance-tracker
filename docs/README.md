# Smart Finance Tracker — Technical Documentation

Welcome to the technical documentation for **Smart Finance Tracker**, an offline-first, machine-learning-powered personal finance management application built with Flutter, SQLite, and Android Native Notification Services.

---

## 📚 Documentation Directory

### Core Architecture & Design
- 🏛️ **[HLD.md](HLD.md)** — **High-Level Design**: System architecture, end-to-end flowcharts, component boundaries, and security model.
- 🔬 **[LLD.md](LLD.md)** — **Low-Level Design**: Class hierarchies, sequence diagrams, state management, and isolate threading.

### Architecture Subsystems (`docs/architecture/`)
- 🗄️ **[Database Schema](architecture/database_schema.md)** — SQLite schema definitions, indexes, timestamp integer standards, and table relationships.
- ⚙️ **[Notification Pipeline](architecture/notification_pipeline.md)** — Android OS listener service, zero-battery background queueing, and isolate port IPC.
- 🧠 **[ML Classifier Engine](architecture/ml_classifier_engine.md)** — Structured Perceptron tagger, BIO feature extraction, online weight updates, and `compute()` thread offloading.

### Feature Specifications (`docs/features/`)
- 📊 **[Dashboard Analytics](features/dashboard_analytics.md)** — Donut & Bar chart components, dynamic date range filter engine (`FilterLogic`), and timeframe state architecture.
- 📁 **[Backup & Restore](features/backup_and_restore.md)** — JSON & CSV serialization, transactional override and append modes, and migration specs.
- 🌐 **[Localization](features/localization.md)** — Multi-language l10n framework (English & Telugu), localized UI controls, and canonical key decoupling.

