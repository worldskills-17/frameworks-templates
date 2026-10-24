# React + Vite

Competition template: React 19.3 with Vite 8, Tailwind CSS 4 and ESLint 10 (flat config).
The Docker build uses `node:24` and nginx serves the built app at the domain root (deep links
fall back to `index.html`). Local development needs Node 20.19+ or 22.12+.

- `npm run dev` - development server with hot reload
- `npm run build` - production build into `dist/`
- `npm run lint` - ESLint

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.
