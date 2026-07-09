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

# Copy Prisma schema and generate the client
COPY prisma ./prisma/
RUN npx prisma generate

# Copy application code
COPY . .

# Bake DATABASE_URL into the image env so it's available to the Prisma CLI (db push
# at startup) and the runtime @prisma/client. next build does not connect to the DB
# because the API routes are forced dynamic.
ARG DB_HOST
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ENV DATABASE_URL=mysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:3306/${DB_NAME}

RUN npm run build

# Keep a safe copy of the boot-seed script outside the app dir; fall back to a
# no-op if a competitor removed it from the repo (build must not break).
RUN cp ws-boot-seed.js /usr/local/lib/ws-boot-seed.js 2>/dev/null || \
    echo "console.log('boot-seed script missing - skipping')" > /usr/local/lib/ws-boot-seed.js

EXPOSE 80

# Sync schema, seed if configured/changed, then serve
CMD ["sh", "-c", "if [ \"$WS_MARKING\" = 1 ]; then echo 'Marking mode (WS_MARKING=1) - skipping prisma db push + seed; serving restored DB as-is'; else npx prisma db push --accept-data-loss --skip-generate && node /usr/local/lib/ws-boot-seed.js; fi && npm run start"]
