FROM node:22-alpine

# Accept database configuration as build arguments
ARG NPM_REGISTRY
ARG DB_HOST
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD

# Configure npm registry for Verdaccio cache
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --loglevel=error

# Copy Prisma schema
COPY prisma ./prisma/

# Generate Prisma Client
RUN npx prisma generate

# Copy application code
COPY . .

# Replace placeholders in .env
RUN sed -i "s|{{DB_HOST}}|${DB_HOST}|g" .env && \
    sed -i "s|{{DB_NAME}}|${DB_NAME}|g" .env && \
    sed -i "s|{{DB_USERNAME}}|${DB_USERNAME}|g" .env && \
    sed -i "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" .env

EXPOSE 80

CMD ["node", "src/server.js"]
