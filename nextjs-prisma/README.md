# Next.js + Prisma Template

Next.js (App Router) with Prisma ORM + MySQL for WorldSkills UK competitions. Runs as a Node server (`next start`) on port 80 so server components and API routes can reach the database.

## Local development

```bash
npm install
npx prisma generate
DATABASE_URL="mysql://user:pass@localhost:3306/dev" npm run dev
```

## Production build

```bash
npm run build
npx prisma db push
npm run start
```

## Container build (CI)

Triggered automatically on push to `main` via Gitea Actions. DB credentials come from repository secrets (`DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`) and are baked into `DATABASE_URL` at build time. On first start the container runs `prisma db push` to apply the schema.

## Endpoints

- `GET /` — landing page
- `GET /api/users` — list users (Prisma)
- `POST /api/users` — create a user (JSON body: `{ "email": "...", "name": "..." }`)

## Note on MySQL vs MariaDB

The competition database server is MySQL 8.4. Prisma uses `provider = "mysql"` for both MySQL and MariaDB, so the schema is unchanged. The default Prisma connector is used. If a driver adapter is preferred, use `@prisma/adapter-mysql2` (the `@prisma/adapter-mariadb` adapter also connects but mysql2 is the correct match for this server).
