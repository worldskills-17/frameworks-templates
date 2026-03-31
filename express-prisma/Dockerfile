FROM node:22-alpine

# Accept database configuration as build arguments
ARG NPM_REGISTRY
ARG DB_HOST
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD

# Configure npm registry for Verdaccio cache
RUN if [ -n "$NPM_REGISTRY" ]; then \
        npm config set registry "$NPM_REGISTRY" && \
        npm config set strict-ssl false; \
    fi

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install --loglevel error

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
