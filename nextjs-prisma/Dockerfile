FROM node:22-alpine

# Accept database configuration as build arguments
# NOTE: per-repo build args (DB_*) are declared right before first use, not
# here - early declaration would bust the npm/prisma layer cache for every
# new module repo (classic builder folds ARG values into RUN cache keys).
ARG NPM_REGISTRY=http://verdaccio:4873

# Configure npm registry for Verdaccio cache
RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

# OpenSSL for Prisma, libc6-compat for Next.js native deps — retry on transient Alpine CDN errors
RUN for i in 1 2 3; do apk add --no-cache openssl libc6-compat && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies — retry on transient registry errors
RUN for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done

# Copy Prisma schema + config and generate the client (into src/generated/prisma).
# package.json is listed so the prisma.config.* wildcard never matches nothing.
COPY prisma ./prisma/
COPY package.json prisma.config.* ./
RUN npx prisma generate

# Copy application code
COPY . .

# Bake DATABASE_URL into the image env so it's available to the Prisma CLI (db push
# at startup, read through prisma.config.ts) and the runtime client (driver adapter
# in src/lib/prisma.js). next build does not connect to the DB because the API
# routes are forced dynamic.
# DATABASE_URL comes from the module's provisioned secret and is already
# engine-correct (mysql:// or postgresql://...:5432, URL-encoded), so ONE prisma
# template serves any SQL engine; schema.prisma's provider is pinned to match.
ARG DATABASE_URL
ENV DATABASE_URL=${DATABASE_URL}

RUN npm run build

# Keep a safe copy of the boot-seed script outside the app dir; fall back to a
# no-op if a competitor removed it from the repo (build must not break).
RUN cp ws-boot-seed.js /usr/local/lib/ws-boot-seed.js 2>/dev/null || \
    echo "console.log('boot-seed script missing - skipping')" > /usr/local/lib/ws-boot-seed.js

EXPOSE 80

# Sync schema, seed if configured/changed, then serve.
# The seed hash is read before db push, which drops tables not in the schema
# (ws_seed_hash included) - see ws-boot-seed.js.
CMD ["sh", "-c", "if [ \"$WS_MARKING\" = 1 ]; then echo 'Marking mode (WS_MARKING=1) - skipping prisma db push + seed; serving restored DB as-is'; else node /usr/local/lib/ws-boot-seed.js --before-push && npx prisma db push --accept-data-loss && node /usr/local/lib/ws-boot-seed.js; fi && npm run start"]
