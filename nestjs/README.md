# NestJS Template

Bare NestJS skeleton for WorldSkills UK competitions. TypeScript, Express adapter, listens on port 80.

## Local development

```bash
npm install
npm run start:dev
```

## Production build

```bash
npm run build
node dist/main.js
```

## Container build (CI)

Triggered automatically on push to `main` via Gitea Actions. Image is published to the local Gitea registry and Watchtower deploys it within 30 seconds.

## Endpoints

- `GET /` — landing HTML
- `GET /test` — JSON health check
