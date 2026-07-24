This is a [Nuxt 3](https://nuxt.com) starter template.

## Getting Started

Install dependencies and run the development server:

```bash
npm install
npm run dev
```

The dev server runs on [http://localhost:4200](http://localhost:4200). Edit
`pages/index.vue` (or add more files under `pages/`) — the page auto-updates as
you edit.

## Build & run (production)

```bash
npm run build      # outputs .output/
npm run start      # node .output/server/index.mjs
```

In the competition container the app is built and served on port **80**
(`NITRO_PORT=80`, `NITRO_HOST=0.0.0.0`).

## Database (optional)

MySQL is optional. `DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` (and
`DATABASE_URL`) are available at runtime via `process.env`, so you can use
`mysql2` / `knex` from server routes (`server/api/*`) if you want. Nothing
connects automatically — a plain Nuxt app ignores them.

## Learn More

- [Nuxt Documentation](https://nuxt.com/docs)
