# sv

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Versions

- SvelteKit 3 (`@sveltejs/kit` 3.1) with Svelte 5.57, static adapter 4
- Vite 8, Vitest 5 (browser mode via Playwright), Tailwind CSS 4.3
- ESLint 10 (flat config), Prettier 3.9
- Node.js 22.17 or newer (the Docker build uses `node:24`)

SvelteKit 3 notes:

- Project configuration lives in `vite.config.js` (options passed to `sveltekit()`); `svelte.config.js` is no longer read.
- Import from `src/lib` with `#lib` (declared under `imports` in `package.json`), e.g. `import x from '#lib/x.js'`. `$lib` still works through an alias in `vite.config.js`.
- `$app/stores` is removed; use `$app/state`.

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project in the current directory
npx sv create

# create a new project in my-app
npx sv create my-app
```

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```sh
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
