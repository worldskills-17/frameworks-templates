FROM node:22-alpine

# NOTE: per-repo build args (DB_*) are declared right before first use, not
# here - early declaration would bust the npm/prisma layer cache for every
# new module repo (classic builder folds ARG values into RUN cache keys).
ARG NPM_REGISTRY=http://verdaccio:4873

# Configure npm registry for Verdaccio cache
RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

# Install OpenSSL for Prisma — retry on transient Alpine CDN errors
RUN for i in 1 2 3; do apk add --no-cache openssl && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies — retry on transient registry errors
RUN for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done

# Copy Prisma schema
COPY prisma ./prisma/

# Generate Prisma Client
RUN npx prisma generate

# Copy application code
COPY . .

# Per-repo database URL (declared here, not at the top - see the note under FROM).
# DATABASE_URL comes from the module's provisioned secret and is already
# engine-correct (mysql:// or postgresql://...:5432, URL-encoded password), so ONE
# prisma template serves any SQL engine. schema.prisma's datasource provider is
# pinned to match by the platform (db_prisma_set_provider).
ARG DATABASE_URL

# Create .env with the database URL (gitignored, so generated at build time). The
# same DATABASE_URL is also injected as a runtime container env var (which takes
# precedence), keeping build-time and runtime consistent.
RUN echo "DATABASE_URL=\"${DATABASE_URL}\"" > .env

# Keep a safe copy of the boot-seed script outside the app dir; fall back to a
# no-op if a competitor removed it from the repo (build must not break).
RUN cp ws-boot-seed.js /usr/local/lib/ws-boot-seed.js 2>/dev/null || \
    echo "console.log('boot-seed script missing - skipping')" > /usr/local/lib/ws-boot-seed.js

EXPOSE 80

# Sync schema on every start (was missing - siblings nestjs/nextjs-prisma
# already did this), seed if configured/changed, then run the app
CMD ["sh", "-c", "if [ \"$WS_MARKING\" = 1 ]; then echo 'Marking mode (WS_MARKING=1) - skipping prisma db push + seed; serving restored DB as-is'; else npx prisma db push --accept-data-loss --skip-generate && node /usr/local/lib/ws-boot-seed.js; fi && node src/server.js"]
