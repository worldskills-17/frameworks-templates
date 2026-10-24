This is a [Next.js](https://nextjs.org) 16 project (App Router, React 19, Tailwind CSS 4, ESLint 10) bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:4200](http://localhost:4200) with your browser to see the result.

You can start editing the page by modifying `src/app/page.js`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/getting-started/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Next.js 16 notes

- `next dev` and `next build` use Turbopack by default (no `--turbopack` flag needed).
- `next lint` was removed: `npm run lint` runs the ESLint CLI with the flat config in `eslint.config.mjs`. `next build` no longer lints.
- `cookies()`, `headers()`, `draftMode()`, `params` and `searchParams` are async only (`await` them).
- `middleware.js` is now `proxy.js` (exported function `proxy`).
- `next-pwa` is webpack-only. To use it, wrap the config in `next.config.mjs` and build with `next build --webpack`.

## Database (optional)

`DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` (and `DATABASE_URL`) are available at runtime via `process.env`, so `mysql2` / `knex` can be used from route handlers and server components. Nothing connects automatically.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Upgrading to Next.js 16](https://nextjs.org/docs/app/guides/upgrading/version-16) - breaking changes from Next.js 15.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.
