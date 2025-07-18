# 🧾 NSDL ShareLedger

A PostgreSQL-based shareholding simulation system inspired by NSDL.  
This project handles companies, shareholders, certificates, applicants, and validated transactions using schema constraints, relational integrity, and PL/pgSQL triggers.

---

## 📁 Repository Structure

📂 ER - diagram
└── image.png # ER diagram of the entire schema
📂 excel*data
└── *.csv # Sample input data for companies, shareholders, etc.
📂 insert and update
└── \_.sql # Scripts for insertions and updates
📂 trigger
└── \*.sql # All PL/pgSQL trigger functions and definitions
📜 schema.sql # Base schema with table definitions

---

## 🧱 Database Tables

All tables are created under the `data` schema.

### `data.companies`

| Column        | Type     | Description                 |
| ------------- | -------- | --------------------------- |
| id            | SERIAL   | Primary key                 |
| name          | TEXT     | Company name                |
| isin_code     | CHAR(12) | Unique ISIN identifier      |
| sector        | TEXT     | Industry sector             |
| registered_on | DATE     | Date of registration        |
| total_shares  | INT      | Total shares (non-negative) |

---

### `data.shareholders`

| Column       | Type        | Description                                        |
| ------------ | ----------- | -------------------------------------------------- |
| id           | SERIAL      | Primary key                                        |
| name         | TEXT        | Shareholder's name                                 |
| pan_number   | VARCHAR(10) | Unique PAN identifier                              |
| email        | TEXT        | Email address                                      |
| kyc_status   | TEXT        | Must be `'pending'`, `'verified'`, or `'rejected'` |
| total_shares | INT         | Sum of holdings (default: 0)                       |
| active       | BOOLEAN     | Active flag (default: `true`)                      |

---

### `data.applicants`

| Column       | Type        | Description                        |
| ------------ | ----------- | ---------------------------------- |
| id           | SERIAL      | Primary key                        |
| name         | TEXT        | Applicant name                     |
| email        | TEXT        | Email address                      |
| pan_number   | VARCHAR(10) | Unique PAN (can be null initially) |
| request_date | DATE        | Defaults to current date           |

---

### `data.certificates`

| Column             | Type   | Description                               |
| ------------------ | ------ | ----------------------------------------- |
| id                 | SERIAL | Primary key                               |
| certificate_number | TEXT   | Unique identifier for the certificate     |
| company_id         | INT    | FK to `companies.id`                      |
| shareholder_id     | INT    | FK to `shareholders.id`                   |
| issued_on          | DATE   | Date of issue (default: current date)     |
| status             | TEXT   | `'active'`, `'lost'`, or `'cancelled'`    |
| origin_type        | TEXT   | `'initial'`, `'transfer'`, or `'reissue'` |
| reissue_of         | INT    | Optional FK to another certificate        |
| transaction_id     | INT    | FK to `transactions.id`                   |

---

### `data.transactions`

| Column              | Type          | Description                                    |
| ------------------- | ------------- | ---------------------------------------------- |
| id                  | SERIAL        | Primary key                                    |
| company_id          | INT           | FK to `companies.id`                           |
| certificate_id      | INT           | FK to `certificates.id`                        |
| from_shareholder_id | INT           | FK to `shareholders.id` (nullable for initial) |
| to_shareholder_id   | INT           | FK to `shareholders.id`                        |
| price_per_share     | DECIMAL(10,2) | Price per share in transaction                 |
| num_shares          | INT           | Shares moved (must be > 0)                     |
| txn_date            | TIMESTAMP     | Defaults to current timestamp                  |

---

### `data.shareholdings`

| Column         | Type      | Description                            |
| -------------- | --------- | -------------------------------------- |
| shareholder_id | INT       | FK to `shareholders.id`                |
| company_id     | INT       | FK to `companies.id`                   |
| total_shares   | INT       | Total shares held                      |
| assigned_at    | TIMESTAMP | Timestamp of the record (default: now) |

> 🔐 Composite Primary Key: `(shareholder_id, company_id)`

---

## ⚙️ Triggers & Functions

Defined inside the `trigger/` folder:

| Trigger Name                                 | Description                                                  |
| -------------------------------------------- | ------------------------------------------------------------ |
| `trg_promote_applicant_to_shareholder`       | On applicant KYC verification, promotes to shareholder       |
| `trg_update_shareholdings_after_transaction` | After insert on `transactions`, adjusts shareholdings        |
| `trg_validate_transaction_owner`             | Before insert on `transactions`, validates KYC and ownership |

Each trigger is written in PL/pgSQL for data safety and business rule enforcement.

---

## ✅ Sample Usage

- Insert companies, shareholders, and applicants using `insert and update/`
- Promote applicants via KYC trigger
- Transfer shares using the `transactions` table
- Verify updates in:
  - `certificates` (owner changed)
  - `shareholdings` (values updated)
  - `shareholders.total_shares` & `active` flag

---

## 🖼️ ER Diagram

![ER Diagram](./ER%20-%20diagram/image.png)

---

## 👨‍💻 Author

**Tanvir Kamble**  
📧 tanvirkamble.official@gmail.com  
💼 LinkedIn: [https://www.linkedin.com/in/tanvir-kamble-60129b228/](https://www.linkedin.com/in/tanvir-kamble-60129b228/)

---

## 📜 License

This project is licensed under the **MIT License**.
