# Farm OS — Backend (Sprint 1)

Farm Operating System backend. NestJS + TypeScript + Prisma + PostgreSQL.

## Sprint 1 scope (this delivery)

Per the approved development strategy, Sprint 1 covers:

- Project setup (NestJS, TypeScript, Docker, Postgres, Prisma)
- Authentication: register, login, refresh (rotating), logout, password reset request/confirm
- Farm module: create farm (auto-creates the owner's `FarmMember` row), list my farms, get farm, update farm
- Cross-cutting: global response envelope (`{ success, data, error, meta }`), global exception filter, farm-isolation guard (`FarmAccessGuard`), role guard (`RolesGuard`), Swagger docs at `/docs`

The **complete approved database schema** (Livestock, Feed, Drugs, Equipment, Finance, Notifications, Audit) is already implemented in `prisma/schema.prisma` so no re-migration is needed as later sprints add business logic — but only Auth and Farms have services/controllers built yet, by design.

## Getting started

```bash
npm install
cp .env.example .env          # edit values as needed
npx prisma generate
npx prisma migrate dev --name init
npx prisma db seed            # roles + default species/categories
npm run start:dev             # http://localhost:3000, docs at /docs
```

Or with Docker (spins up Postgres + the API together):

```bash
docker compose up --build
```

> **Note:** `npx prisma generate` / `migrate` need to reach `binaries.prisma.sh` to download the query engine. This is normal on any standard network — it was the one step I could not verify inside this sandboxed dev environment, which blocks that domain. Everything else (dependency install, full TypeScript compile) was verified here; I temporarily stubbed the generated Prisma client types to run `tsc --noEmit` against the real Sprint 1 code and it compiled clean. Run the two commands above on your machine/CI and it will work normally.

## Verifying the vertical slice manually (once running)

```
POST /auth/register        { fullName, email or phone, password }
POST /auth/login           { identifier, password }  -> accessToken, refreshToken
POST /farms                (Bearer accessToken)       { name, location, ... }
GET  /farms                (Bearer accessToken)       -> your farms
GET  /farms/:farmId        (Bearer accessToken)
```

## Project structure

```
src/
  auth/          registration, login, tokens, password reset
  users/         user persistence (used by auth)
  farms/         farm CRUD + membership bootstrap
  common/        guards, decorators, filters, interceptors shared across modules
  database/      PrismaService/PrismaModule (global)
  config/        (reserved for Sprint 2+ typed config)
  main.ts        bootstrap, global pipes/filters/interceptors, Swagger
prisma/
  schema.prisma  full approved domain model
  seed.ts        roles + default species/animal categories
```

## Next sprints (not built yet, per the approved plan)

- Sprint 2: Livestock (species-generic movements + computed stock), Feed ledger, Dashboard
- Sprint 3: Drugs (FIFO + expiry alerts), Equipment, Alert engine
- Sprint 4: Finance (event-driven: purchase/sale auto-creates expense/revenue), Reports, Audit logging wiring
- Sprint 5: Testing, performance, security review

Each will be built and stopped for review before moving to the next, per the incremental approach already agreed for this project.
