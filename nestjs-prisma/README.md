# NestJS + Prisma Template

NestJS skeleton with Prisma ORM + MySQL for WorldSkills UK competitions. TypeScript, Express adapter, listens on port 80.

## Versions

- NestJS 12 (`@nestjs/core`, `@nestjs/common`, `@nestjs/platform-express`) on Express 5
- Prisma ORM 7 (`prisma`, `@prisma/client`) with the `@prisma/adapter-mariadb` driver adapter (works with MySQL)
- TypeScript 6 (the Nest 12 CLI does not support TypeScript 7 yet)
- Node.js 22 (Docker image `node:22-alpine`)

## Prisma 7 layout

- `prisma/schema.prisma` - models. The `prisma-client` generator writes the client to `src/generated/prisma` (gitignored, compiled by `nest build`); import it with `import { PrismaClient } from '../generated/prisma/client'`.
- `prisma.config.ts` - datasource URL (`DATABASE_URL`), migrations path and seed command. Prisma 7 no longer reads `url` from `schema.prisma` or `"prisma"` from `package.json`, and no longer loads `.env` by itself (`prisma.config.ts` and `src/main.ts` import `dotenv/config`).
- `src/prisma/prisma.service.ts` - `PrismaClient` with the MariaDB driver adapter (required in Prisma 7).
- `prisma db push` and `prisma migrate dev` no longer run `prisma generate`; run `npx prisma generate` after editing the schema.

## Seeding

Set the seed command in `prisma.config.ts`:

```ts
migrations: {
  path: 'prisma/migrations',
  seed: 'tsx prisma/seed.ts',
},
```

`tsx` is included (it resolves the generated client's `.js` imports; `ts-node` does not). Run `npx prisma db seed` locally. On the server the container seeds on first start and resets + reseeds when anything under `prisma/` (other than `schema.prisma`) or the seed command changes.

## Local development

```bash
npm install
npx prisma generate
echo 'DATABASE_URL="mysql://user:pass@localhost:3306/dev"' > .env
npx prisma db push
npm run start:dev
```

## Production build

```bash
npx prisma generate
npm run build
npx prisma db push
node dist/main.js
```

## Container build (CI)

Triggered automatically on push to `main` via Gitea Actions. DB credentials come from repository secrets (`DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`) and are baked into the image as the `DATABASE_URL` environment variable at build time. On every start the container runs `prisma db push` to apply the schema, then the seed (if configured and changed).

## Endpoints

- `GET /` — landing HTML
- `GET /users` — list users (Prisma)
- `POST /users` — create a user (JSON body: `{ "email": "...", "name": "..." }`)
