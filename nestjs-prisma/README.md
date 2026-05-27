# NestJS + Prisma Template

NestJS skeleton with Prisma ORM + MySQL for WorldSkills UK competitions. TypeScript, Express adapter, listens on port 80.

## Local development

```bash
npm install
npx prisma generate
DATABASE_URL="mysql://user:pass@localhost:3306/dev" npm run start:dev
```

## Production build

```bash
npm run build
npx prisma db push
node dist/main.js
```

## Container build (CI)

Triggered automatically on push to `main` via Gitea Actions. DB credentials come from repository secrets (`DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`) and are baked into `.env` at build time. On first start the container runs `prisma db push` to apply the schema.

## Endpoints

- `GET /` — landing HTML
- `GET /users` — list users (Prisma)
- `POST /users` — create a user (JSON body: `{ "email": "...", "name": "..." }`)
