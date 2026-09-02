# Digital Farm Management System — Stage 1 MVP
## Planning Deliverables (v2 — multi-species livestock, pending approval)

**Confirmed stack:** Flutter (Dart) mobile app · Node.js/TypeScript (NestJS) API · PostgreSQL · JWT auth.

**Scope update (v2):** the farm keeps pigs, dogs, dairy cattle, and chickens — not pigs only. The livestock and feed model below has been generalized to a multi-species design so all four (and any future species) share the same ledger-based inventory pattern instead of one-off pig-specific tables. Everything else from v1 (finance, equipment, notifications, audit, parties) is unchanged.

---

## 1. PRD Summary

**Problem:** Pig farmers track livestock, feed, drugs, equipment, purchases, and sales on paper, making it hard to answer basic questions about stock levels and profitability.

**Solution:** A mobile-first app where a farmer registers, creates a farm, and records day-to-day events (births, sales, feed purchases, drug usage, expenses). The system derives current stock and financial position from a transaction ledger — the farmer never edits a "current stock" number directly.

**Non-goals for Stage 1:** marketplace, vet/agrovet portals, buyer network, advanced analytics, financing. These are deferred but the data model must not block them.

**Success criteria for the vertical slice:**
Register → create farm → log in → view dashboard → record pig movement → record feed purchase → view updated inventory → record expense → view financial summary — all working end-to-end.

---

## 2. System Architecture

```
┌─────────────────────────┐
│  Mobile App (Flutter)   │  Offline-tolerant local cache (Stage 2: full sync)
└───────────┬─────────────┘
            │ HTTPS/REST (JWT)
┌───────────▼─────────────┐
│   API Gateway / Nest.js  │
│  ┌─────────────────────┐│
│  │ Auth Module          ││
│  │ Farm Module          ││
│  │ Livestock Module     ││  (species-generic: pigs, dogs, cattle, chickens)
│  │ Feed Module          ││
│  │ Drugs Module         ││
│  │ Equipment Module     ││
│  │ Finance Module       ││
│  │ Reports Module       ││
│  │ Notifications Module ││
│  │ Audit Module         ││
│  └─────────────────────┘│
└───────────┬──────────────┘
            │
┌───────────▼─────────────┐
│  PostgreSQL (per-farm    │
│  row-level isolation)    │
└──────────────────────────┘
```

**Key architectural decisions:**

1. **Every domain table carries `farm_id`.** All queries are scoped by farm at the ORM/repository layer, not left to individual endpoints — this is the backbone of the "a farmer never sees another farmer's data" requirement.
2. **Inventory and financial state is never stored as an editable field.** Stock levels and balances are *materialized views / computed columns* derived from an append-only transaction ledger (`pig_movements`, `feed_transactions`, `drug_transactions`). This satisfies the "no manual closing stock" rule and gives you the audit trail for free.
3. **Modular monolith, not microservices.** One deployable API with clearly separated modules (as in the diagram). This is enough for Stage 1/2 scale and avoids premature distributed-systems complexity; modules map cleanly to future services (e.g., a Treatments module can later be split out to serve a Vet portal) if you ever need to.
4. **Soft deletion + reversal transactions**, never hard deletes, for anything financial or inventory-related.
5. **Extensibility hooks built in now, unused until Stage 2/3:** a generic `party` concept (see schema) so that "Supplier," "Buyer," "Vet," and "Agrovet" can all later become specialized roles on the same underlying entity instead of new parallel tables.
6. **Livestock is species-generic, not pig-specific.** Since the farm keeps pigs, dogs, dairy cattle, and chickens, there is one `species` table and one `animal_movements` ledger shared across all of them, with per-species `animal_categories` (e.g. pig categories: Boar/Sow/Gilt/Piglet/Weaner/Grower/Finisher; cattle categories: Calf/Heifer/Milking Cow/Dry Cow; chicken categories: Chick/Layer/Broiler; dog categories: Puppy/Adult). Adding a fifth species later is a data insert, not a schema change.

---

## 3. Database ERD (entities & relationships)

```
users ──< farm_members >── farms
  │                            │
  │                            ├──< species (Pig, Dog, Dairy Cattle, Chicken, ...)
  │                            │      └──< animal_categories (per species, system + custom)
  │                            │             └──< animal_movements (opening/birth/purchase/sale/death/etc.)
  │                            ├──< feed_items (tagged to one or more species) ──< feed_transactions
  │                            ├──< drug_items ──< drug_transactions
  │                            ├──< treatments (fk: drug_item, animal_category)
  │                            ├──< equipment ──< equipment_maintenance
  │                            ├──< purchases (fk: category, party)
  │                            ├──< expenses
  │                            ├──< sales (fk: party as buyer)
  │                            ├──< notifications
  │                            └──< audit_logs
  │
  └── roles (many-to-many via user_roles: farmer, farm_manager, admin)

parties (generic: supplier / buyer / future vet / agrovet)
  └── referenced by purchases.supplier_party_id, sales.buyer_party_id
```

`parties` is the one deliberately future-proofed table: instead of a plain text "Supplier" string, purchases and sales reference a lightweight `parties` row (name, phone, type). In Stage 1 `type` is just `supplier` or `buyer`; in Stage 2 it extends to `vet`, `agrovet`, `hotel`, `restaurant`, `transporter` without any schema migration to the purchases/sales tables themselves.

**Feed-to-species mapping:** rather than hard-coding "pig feed" vs "dog feed" as separate tables, each `feed_item` has a `species_id` (nullable — some feeds, like a generic supplement, may apply to more than one species via a join table `feed_item_species` if needed). This lets the dashboard show "Feed" broken down per species without duplicating the purchase/usage/waste ledger logic four times.

---

## 4. Core Database Schema (PostgreSQL DDL — key tables)

```sql
-- USERS & ACCESS CONTROL
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  password_hash TEXT NOT NULL,
  email_verified_at TIMESTAMPTZ,
  phone_verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL -- 'farmer','farm_manager','admin'
);

CREATE TABLE farms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id UUID NOT NULL REFERENCES users(id),
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(30),
  email VARCHAR(150),
  location VARCHAR(255),
  region VARCHAR(100),
  country VARCHAR(100),
  farm_type VARCHAR(50),
  registration_no VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE farm_members (   -- supports multi-farm, multi-user from day 1
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  user_id UUID NOT NULL REFERENCES users(id),
  role_id INT NOT NULL REFERENCES roles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(farm_id, user_id)
);

-- LIVESTOCK (species-generic: pigs, dogs, dairy cattle, chickens, and any future species)
CREATE TABLE species (
  id SERIAL PRIMARY KEY,
  farm_id UUID REFERENCES farms(id),   -- NULL = system default species
  name VARCHAR(50) NOT NULL            -- Pig, Dog, Dairy Cattle, Chicken
);

CREATE TABLE animal_categories (
  id SERIAL PRIMARY KEY,
  species_id INT NOT NULL REFERENCES species(id),
  farm_id UUID REFERENCES farms(id),   -- NULL = system default category for that species
  name VARCHAR(50) NOT NULL
  -- Pig: Boar, Sow, Gilt, Piglet, Weaner, Grower, Finisher
  -- Dairy Cattle: Calf, Heifer, Milking Cow, Dry Cow, Bull
  -- Chicken: Chick, Grower, Layer, Broiler, Cockerel
  -- Dog: Puppy, Adult, Breeding
);

CREATE TABLE animal_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  species_id INT NOT NULL REFERENCES species(id),
  category_id INT NOT NULL REFERENCES animal_categories(id),
  movement_type VARCHAR(30) NOT NULL,  -- opening, birth, purchase, sale, death, cull, transfer, adjustment
  quantity INT NOT NULL CHECK (quantity > 0),
  movement_date DATE NOT NULL,
  reference_id UUID,                   -- links to purchases.id or sales.id when relevant
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- Current stock per (species, category) = SUM of signed quantities, computed via a view
-- (e.g. current_livestock_stock), never stored directly. Same view powers per-species
-- dashboard cards (Pigs / Cattle / Chickens / Dogs) with zero duplicated logic.

-- FEED (tagged to species so the same ledger pattern covers pig feed, dog feed, dairy meal, chicken mash)
CREATE TABLE feed_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  species_id INT REFERENCES species(id),   -- NULL = generic/shared feed
  name VARCHAR(100) NOT NULL,
  feed_type VARCHAR(50) NOT NULL,      -- configurable, farm-defined, e.g.:
  -- Pig: Maize Bran, Soya, Sunflower, Wheat Bran, Concentrate
  -- Dog: Ochong'a, Omena, Frozen Blood, Maize Flour, Meat
  -- Dairy Cattle: Dairy Meal
  -- Chicken: Chicken Mash
  unit VARCHAR(10) NOT NULL DEFAULT 'kg',
  bag_size_kg NUMERIC(8,2),            -- for bag<->kg conversion
  min_stock_kg NUMERIC(10,2),
  storage_location VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
-- Perishable/fresh feeds (frozen blood, meat, omena) reuse the same expiry_date field
-- already present on feed_transactions below — no special-casing needed.

CREATE TABLE feed_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feed_item_id UUID NOT NULL REFERENCES feed_items(id),
  farm_id UUID NOT NULL REFERENCES farms(id),
  txn_type VARCHAR(20) NOT NULL,       -- opening, purchase, usage, waste, adjustment
  quantity_kg NUMERIC(10,2) NOT NULL,
  cost_per_unit NUMERIC(10,2),
  total_cost NUMERIC(12,2),
  batch_number VARCHAR(50),
  expiry_date DATE,
  supplier_party_id UUID REFERENCES parties(id),
  txn_date DATE NOT NULL,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- DRUGS & VACCINES
CREATE TABLE drug_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  unit VARCHAR(20),
  min_stock NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE drug_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  drug_item_id UUID NOT NULL REFERENCES drug_items(id),
  farm_id UUID NOT NULL REFERENCES farms(id),
  txn_type VARCHAR(20) NOT NULL,      -- opening, purchase, usage, waste, adjustment
  quantity NUMERIC(10,2) NOT NULL,
  batch_number VARCHAR(50),
  expiry_date DATE,
  unit_cost NUMERIC(10,2),
  txn_date DATE NOT NULL,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- FIFO consumption resolved at query/service layer using batch + expiry_date ordering.

CREATE TABLE treatments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  pig_category_id INT REFERENCES pig_categories(id),
  drug_item_id UUID NOT NULL REFERENCES drug_items(id),
  batch_number VARCHAR(50),
  dose VARCHAR(50),
  quantity_used NUMERIC(10,2),
  reason TEXT,
  administered_by UUID REFERENCES users(id),
  treatment_date DATE NOT NULL,
  notes TEXT
);

-- EQUIPMENT
CREATE TABLE equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  quantity INT DEFAULT 1,
  condition VARCHAR(20) DEFAULT 'good', -- new, good, fair, damaged, under_repair, retired
  purchase_date DATE,
  unit_cost NUMERIC(10,2),
  location VARCHAR(100),
  assigned_to VARCHAR(100),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE equipment_maintenance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL REFERENCES equipment(id),
  maintenance_date DATE NOT NULL,
  description TEXT,
  cost NUMERIC(10,2),
  next_maintenance_date DATE,
  notes TEXT
);

-- PARTIES (future-proofing for vet/agrovet/buyer network)
CREATE TABLE parties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID REFERENCES farms(id),   -- NULL = platform-level party (Stage 2+)
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(30),
  type VARCHAR(30) NOT NULL DEFAULT 'supplier', -- supplier, buyer, vet(future), agrovet(future)...
  created_at TIMESTAMPTZ DEFAULT now()
);

-- FINANCE
CREATE TABLE purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  category VARCHAR(30) NOT NULL, -- feed, drugs, equipment, vet_services, labour, transport, utilities, repairs, other
  description TEXT,
  supplier_party_id UUID REFERENCES parties(id),
  quantity NUMERIC(10,2),
  unit_price NUMERIC(10,2),
  total_amount NUMERIC(12,2) NOT NULL,
  payment_method VARCHAR(30),
  receipt_no VARCHAR(50),
  purchase_date DATE NOT NULL,
  linked_feed_txn_id UUID REFERENCES feed_transactions(id),
  linked_drug_txn_id UUID REFERENCES drug_transactions(id),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  category VARCHAR(30) NOT NULL,
  description TEXT,
  amount NUMERIC(12,2) NOT NULL,
  payment_method VARCHAR(30),
  expense_date DATE NOT NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  buyer_party_id UUID REFERENCES parties(id),
  product_category VARCHAR(30) NOT NULL, -- live pig category, piglets, manure, other
  pig_category_id INT REFERENCES pig_categories(id),
  quantity NUMERIC(10,2) NOT NULL,
  weight_kg NUMERIC(10,2),
  price_per_unit NUMERIC(10,2),
  total_amount NUMERIC(12,2) NOT NULL,
  payment_status VARCHAR(20) DEFAULT 'paid',
  payment_method VARCHAR(30),
  sale_date DATE NOT NULL,
  linked_pig_movement_id UUID REFERENCES pig_movements(id),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- NOTIFICATIONS & AUDIT
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  type VARCHAR(50) NOT NULL, -- low_feed, low_drug, drug_expiring, drug_expired, maintenance_due, variance
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID NOT NULL REFERENCES farms(id),
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  entity VARCHAR(50) NOT NULL,
  entity_id UUID,
  previous_value JSONB,
  new_value JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**Note on computed stock:** `pig_movements`, `feed_transactions`, and `drug_transactions` are append-only ledgers. Current stock is exposed via SQL views (e.g., `current_pig_stock_by_category`, `current_feed_stock`) rather than a stored column, guaranteeing the "no manual override of closing stock" rule and giving accurate historical reporting for free.

---

## 5. API Specification (Stage 1 surface)

| Area | Endpoint | Method | Notes |
|---|---|---|---|
| Auth | `/auth/register` | POST | email or phone + password |
| Auth | `/auth/login` | POST | returns access + refresh JWT |
| Auth | `/auth/logout` | POST | invalidates refresh token |
| Auth | `/auth/password-reset/request` | POST | |
| Auth | `/auth/password-reset/confirm` | POST | |
| Farm | `/farms` | GET/POST | list user's farms / create farm |
| Farm | `/farms/:id` | GET/PUT | |
| Dashboard | `/farms/:id/dashboard` | GET | aggregated summary |
| Livestock | `/farms/:id/species` | GET | Pig, Dog, Dairy Cattle, Chicken, ... |
| Livestock | `/farms/:id/species/:speciesId/categories` | GET/POST | e.g. Sow, Milking Cow, Layer |
| Livestock | `/farms/:id/livestock/movements?species=` | GET/POST | filterable by species |
| Livestock | `/farms/:id/livestock/stock?species=` | GET | computed current stock, per species |
| Feed | `/farms/:id/feed/items` | GET/POST | |
| Feed | `/farms/:id/feed/purchases` | POST | |
| Feed | `/farms/:id/feed/usage` | POST | |
| Feed | `/farms/:id/feed/adjustments` | POST | reconciliation |
| Drugs | `/farms/:id/drugs/items` | GET/POST | |
| Drugs | `/farms/:id/drugs/purchases` | POST | |
| Drugs | `/farms/:id/drugs/usage` | POST | |
| Drugs | `/farms/:id/treatments` | GET/POST | |
| Equipment | `/farms/:id/equipment` | GET/POST | |
| Equipment | `/farms/:id/equipment/:eqId/maintenance` | GET/POST | |
| Finance | `/farms/:id/expenses` | GET/POST | |
| Finance | `/farms/:id/purchases` | GET/POST | |
| Finance | `/farms/:id/sales` | GET/POST | |
| Finance | `/farms/:id/profit-loss` | GET | date range param |
| Reports | `/farms/:id/reports/:type` | GET | livestock, feed, drugs, equipment, financial |
| Notifications | `/farms/:id/notifications` | GET/PATCH | mark read |

All responses use a consistent envelope: `{ success, data, error, meta }`. All list endpoints support `?from=&to=&category=&page=`.

---

## 6. Authentication Strategy

- Registration via email or phone; password hashed with bcrypt (cost 12).
- Login issues short-lived access JWT (15 min) + longer-lived refresh token (30 days, stored hashed in DB, revocable on logout).
- Role-based authorization middleware checks `farm_members.role_id` for every farm-scoped request — enforced centrally, not per-controller, to prevent accidental data leaks.
- Email/SMS verification deferred to Phase 1 but designed in from day one (`email_verified_at`/`phone_verified_at` columns already present).

---

## 7. MVP Development Backlog (by phase, matching Section 23 of the brief)

- **Phase 1** — Project scaffolding, Postgres schema + migrations, auth (register/login/logout), farm creation.
- **Phase 2** — Dashboard shell (per-species livestock summary cards), species + animal categories seed data, movements CRUD, computed stock view.
- **Phase 3** — Feed items, feed purchase/usage/adjustment endpoints, low-stock threshold logic.
- **Phase 4** — Drug items, drug transactions, expiry alert logic, basic treatment records.
- **Phase 5** — Equipment + maintenance tracking.
- **Phase 6** — Purchases + expenses, auto-linking purchases to feed/drug inventory.
- **Phase 7** — Sales, auto-linking sales to pig movements.
- **Phase 8** — Profit/loss aggregation endpoint + dashboard tie-in.
- **Phase 9** — Reports (filter + PDF/CSV export).
- **Phase 10** — Notifications engine (low stock, expiry, maintenance due).
- **Phase 11** — Testing, security review, deployment.

**First milestone (as specified):** the vertical slice — register → create farm → login → dashboard → record a livestock movement (e.g. a pig sale or a birth in the dairy herd) → feed purchase → updated inventory view → expense → financial summary. This spans thin slices of Phases 1, 2, 3, 6, and 8, and is the right thing to build and demo first rather than fully finishing any one phase in isolation.

---

## 8. Testing Strategy (high-level)

- Unit tests on all ledger calculations (stock derivation, FIFO drug consumption, P/L aggregation) — these are the parts where a bug silently corrupts a farmer's numbers.
- Integration tests per module against a test Postgres instance (auth flow, farm isolation, movement→stock consistency).
- Contract tests on API responses to catch breaking changes as modules are added.
- Manual mobile UI pass per phase against the "large touch targets, minimal typing" UX principle.

## 9. Deployment Strategy (high-level)

- Containerized API (Docker) behind managed Postgres (Stage 1 doesn't need read replicas or sharding).
- Environment-based config (dev/staging/prod), migrations run via CI before deploy.
- Mobile app built with Flutter, distributed via Play Store (and App Store if iOS is needed) — CI builds via Codemagic or GitHub Actions + Fastlane.
- Deferred to later: full offline sync engine — Stage 1 mobile app can cache read data and queue simple writes locally, with a clearly isolated sync module so it doesn't block Stage 1 delivery but doesn't require a rewrite either.

---

## Next Step

Stack (Flutter + Node/NestJS + Postgres) and livestock scope (pigs, dogs, dairy cattle, chickens) are now confirmed. Before I start writing actual code (project scaffolding, migrations, auth, farm registration), one last check:

- Any must-have detail I've missed in the schema/API — e.g. specific units for dairy (litres of milk?), egg tracking for chickens, or anything farm-specific — before we lock the schema in?

If nothing else needs adjusting, say so and I'll build **Phase 1** (scaffolding + DB migrations + auth + farm registration) as a working slice and stop there for your review, per the incremental approach the brief calls for.
