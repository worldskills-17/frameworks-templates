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

# Create .env with database URL (file is gitignored so must be generated at build time)
RUN echo "DATABASE_URL=\"mysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:3306/${DB_NAME}\"" > .env

EXPOSE 80

CMD ["node", "src/server.js"]
