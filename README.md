
Acme Industries - Procure-to-Pay (P2P) Module

A multi-company Procure-to-Pay (P2P) back-office module built with Laravel and MySQL, covering Purchase Requisitions (PR), dynamic database-driven Approval Workflows, Budget Controls with concurrency locking, Purchase Orders (PO) with GST calculation, Goods Receipt Notes (GRN) with UoM conversion & tolerance checks, and Vendor Invoices with 3-Way Matching.

---

1. Tech Stack & Architecture Choices
* Framework: Laravel 11+ (PHP 8.2+) — Chosen for built-in database transaction support, pessimistic row locking (`lockForUpdate`), clean service-layer separation, and PHPUnit feature testing.
* Database: MySQL 8 / MariaDB 10.6+ — Uses `DECIMAL(15,2)` columns alongside PHP `BCMath` functions (`bcadd`, `bcsub`, `bcmul`, `bcdiv`, `bccomp`) to prevent floating-point rounding errors in financial and GST calculations.
* Service Layer Pattern: Core domain logic (GST calculation, Approval chain generation, Budget locking, GRN tolerance validation, and 3-Way matching) is isolated inside `app/Services/P2PService.php`, keeping controllers thin and maintainable.
* Immutable Audit Trail: Every status transition writes an append-only record to `audit_logs`; updates and deletes are blocked at the Eloquent model level (`AuditLog`).

---

2. Setup Instructions

Prerequisites
* PHP 8.2+ (with `bcmath`, `pdo_mysql`, `mbstring`, `zip` extensions enabled)
* Composer
* MySQL 8.0+ or MariaDB 10.6+

 Local Installation Steps
1. Extract the project into your web directory (e.g., `p2p-app`) and install dependencies:
   bash
   composer install



2. Configure environment variables:
Copy `.env.example` to `.env` and update your MySQL database credentials:

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=p2p_db
DB_USERNAME=root
DB_PASSWORD=




3.Generate application key:
bash
php artisan key:generate




4. Run migrations and load Appendix A seed data (or import the included `p2p_db.sql` dump):
bash
php artisan migrate:fresh --seed




5. Start the application server:
bash
php artisan serve



Open `http://127.0.0.1:8000` in your browser.
6. Run automated feature tests:
bash
php artisan test




 3. Demo Credentials (Appendix A Seed Data)

The login screen provides a quick role-switcher dropdown pre-loaded with all seeded users. If logging in via standard credentials, the password for all accounts is `password`.

| Company | Email | Role(s) |
| --- | --- | --- |
|ACME-MUM (Mumbai) | `admin.mum@acme.test` | Admin |
| ACME-MUM (Mumbai) | `req.mum@acme.test` | Requester |
| ACME-MUM (Mumbai) | `depthead.mum@acme.test` | Dept Head, Requester |
| ACME-MUM (Mumbai) | `ithead.mum@acme.test` | IT Head |
|ACME-MUM (Mumbai) | `finhead.mum@acme.test` | Finance Head |
| ACME-MUM (Mumbai) | `cfo.mum@acme.test` | CFO |
| ACME-MUM (Mumbai) | `proc.mum@acme.test` | Procurement Officer |
|ACME-MUM(Mumbai) | `store.mum@acme.test` | Store Keeper |
| ACME-MUM (Mumbai) | `accounts.mum@acme.test` | Accounts |
| ACME-BLR(Bengaluru) | `admin.blr@acme.test` | Admin |
| ACME-BLR (Bengaluru) | `req.blr@acme.test` | Requester |
| ACME-BLR (Bengaluru) | `depthead.blr@acme.test` | Dept Head |
| ACME-BLR(Bengaluru) | `proc.blr@acme.test` | Procurement Officer |

---

 4. Design Decisions & Assumptions

* Approval Rules & Extra Step Combination (Rule 4): Base approval chains are resolved dynamically from the `approval_rules` table using document type and amount slabs. When a document contains items in the `IT` category, `P2PService::buildApprovalChain()` splices the extra `IT Head` step immediately after `Dept Head` and snapshots the steps into `document_approvals` so subsequent rule edits do not affect in-flight documents.
* Self-Approval Prevention (Scenario S8): A user cannot approve a document they created. When a user holding an approver role (such as `depthead.mum@acme.test`) submits a PR, their matching role step is automatically marked `SKIPPED` in the approval chain so the workflow proceeds cleanly to the next level.
* Concurrency Control on Budgets (Scenario S3): Budget verification and commitment during PO approval run inside a `DB::transaction()` using pessimistic locking (`lockForUpdate()`) on the `budgets` row, ensuring concurrent approvals cannot push available funds below zero.
* Unit Conversion & Over-Receipt Tolerance (Scenario S4): GRN quantities are converted to the item's base UoM via the `uoms` conversion factor (e.g., `1 BOX = 12 PCS`) and validated against a strict `5%` cumulative over-receipt ceiling (`1.05 * ordered_base_qty`).
* 3-Way Match Rules (Scenario S5): Invoices are automatically validated against PO and GRN records for unbilled accepted quantity, unit price variance within `±2%`, and matching GST rates. Any mismatch places the invoice `ON_HOLD` with detailed line-level reasons.
* Company Isolation (Scenario S7): All queries and state-mutating actions enforce `company_id` ownership against the authenticated user, returning `403 Forbidden` on cross-company access attempts.

---

5. Entity-Relationship (ER) Diagram

mermaid
erDiagram
    COMPANIES ||--o{ USERS : employs
    COMPANIES ||--o{ COST_CENTRES : owns
    COMPANIES ||--o{ VENDORS : catalogues
    COMPANIES ||--o{ PURCHASE_REQUISITIONS : raises
    COMPANIES ||--o{ PURCHASE_ORDERS : issues
    USERS }o--o{ ROLES : assigned
    COST_CENTRES ||--o{ BUDGETS : tracks
    PURCHASE_REQUISITIONS ||--o{ PR_ITEMS : contains
    PURCHASE_ORDERS ||--o{ PO_ITEMS : contains
    PURCHASE_ORDERS ||--o{ GRNS : receives
    GRNS ||--o{ GRN_ITEMS : logs
    PURCHASE_ORDERS ||--o{ INVOICES : billed_by
    INVOICES ||--o{ INVOICE_ITEMS : details





6. What Was Not Finished & Next Steps

Due to prioritizing rock-solid domain integrity across all Tier 1 (Must Have) modules, the following Tier 2 and Tier 3 features are planned for the next iteration:

1. Payments, TDS & Vendor Ledger (M7): Implement payment recording against posted invoices with automatic `2%` TDS deduction on taxable value for `SERVICES` items, running vendor ledger balances, and ageing bucket reports (`0–30`, `31–60`, `61–90`, `90+` days).
2. Operational Reports (M8): Dedicated dashboard views for Budget vs Committed vs Spent summaries, Open PO pending quantities, and On-Hold invoice queues.
3. Queue Notifications & Escalations (M9a/M9b): Dispatch queued email/in-app alerts on document transitions and a scheduled command to escalate approvals pending beyond 48 hours.
4. Docker Compose & CI Pipeline (M9d): Add `Dockerfile`, `docker-compose.yml` (PHP-FPM, Nginx, MySQL, Redis), and GitHub Actions workflow to run `php artisan test` automatically on every push.

