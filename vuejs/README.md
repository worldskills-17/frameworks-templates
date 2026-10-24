# vuejs-base

This template should help get you started developing with Vue 3 in Vite.

## Versions

- Vue 3.5, Vue Router 5, Pinia 4
- Vite 8, Vitest 5 (jsdom 30), Tailwind CSS 4.3 (PostCSS plugin)
- ESLint 10 (flat config), Prettier 3.9
- Node.js 22.22 or 24.15 or newer for unit tests (jsdom 30); the Docker build uses `node:22-alpine`

Vue Router 5 and Pinia 4 keep the same application API as Vue Router 4 and Pinia 3
(`createRouter`, `createWebHistory`, `createPinia`, `defineStore`). Tailwind CSS 4 is
configured in CSS (`src/main.css`); there is no `tailwind.config.js`.

## Recommended IDE Setup

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Customize configuration

See [Vite Configuration Reference](https://vite.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Compile and Minify for Production

```sh
npm run build
```

### Run Unit Tests with [Vitest](https://vitest.dev/)

```sh
npm run test:unit
```

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```
