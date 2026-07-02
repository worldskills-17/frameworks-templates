FROM node:22-alpine

# Accept database configuration as build arguments
ARG NPM_REGISTRY=http://verdaccio:4873
ARG DB_HOST
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD

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
ENV DATABASE_URL=mysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:3306/${DB_NAME}

RUN npm run build

# Keep a safe copy of the boot-seed script outside the app dir; fall back to a
# no-op if a competitor removed it from the repo (build must not break).
RUN cp ws-boot-seed.js /usr/local/lib/ws-boot-seed.js 2>/dev/null || \
    echo "console.log('boot-seed script missing - skipping')" > /usr/local/lib/ws-boot-seed.js

EXPOSE 80

# Sync schema, seed if configured/changed, then serve
CMD ["sh", "-c", "npx prisma db push --accept-data-loss --skip-generate && node /usr/local/lib/ws-boot-seed.js && npm run start"]
