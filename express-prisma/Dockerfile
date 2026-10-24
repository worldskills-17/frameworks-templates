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

# Copy Prisma schema and config (package.json is listed so the wildcard
# always has a match - the classic builder fails on an empty COPY glob)
COPY prisma ./prisma/
COPY package.json prisma.config.* ./

# Generate Prisma Client (into the output path set in schema.prisma)
RUN npx prisma generate

# Copy application code
COPY . .

# Per-repo database configuration (declared here, not at the top -
# see the note under FROM)
ARG DB_HOST
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD

# Create .env with database URL (file is gitignored so must be generated at build time)
RUN echo "DATABASE_URL=\"mysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:3306/${DB_NAME}\"" > .env

# Keep a safe copy of the boot-seed script outside the app dir; fall back to a
# no-op if a competitor removed it from the repo (build must not break).
RUN cp ws-boot-seed.js /usr/local/lib/ws-boot-seed.js 2>/dev/null || \
    echo "console.log('boot-seed script missing - skipping')" > /usr/local/lib/ws-boot-seed.js

EXPOSE 80

# Sync schema on every start, seed if configured/changed, then run the app.
# The seed hash is read before db push, which drops tables not in the schema
# (ws_seed_hash included) - see ws-boot-seed.js.
CMD ["sh", "-c", "if [ \"$WS_MARKING\" = 1 ]; then echo 'Marking mode (WS_MARKING=1) - skipping prisma db push + seed; serving restored DB as-is'; else node /usr/local/lib/ws-boot-seed.js --before-push && npx prisma db push --accept-data-loss && node /usr/local/lib/ws-boot-seed.js; fi && node src/server.js"]
