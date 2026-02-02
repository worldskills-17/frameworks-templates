FROM node:22-alpine

# Accept database configuration as build arguments
ARG NPM_REGISTRY
ARG MONGO_HOST
ARG MONGO_DB
ARG MONGO_USER
ARG MONGO_PASS

# Configure npm registry for Verdaccio cache
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --loglevel=error; else npm install --loglevel=error; fi
COPY . .

# Replace placeholders in .env
RUN sed -i "s|{{MONGO_HOST}}|${MONGO_HOST}|g" .env && \
    sed -i "s|{{MONGO_DB}}|${MONGO_DB}|g" .env && \
    sed -i "s|{{MONGO_USER}}|${MONGO_USER}|g" .env && \
    sed -i "s|{{MONGO_PASS}}|${MONGO_PASS}|g" .env

EXPOSE 80

CMD ["node", "src/server.js"]
