FROM node:22-alpine

# Accept database configuration as build arguments
ARG NPM_REGISTRY
ARG MONGO_HOST
ARG MONGO_DB
ARG MONGO_USER
ARG MONGO_PASS

# Configure npm registry for Verdaccio cache
RUN if [ -n "$NPM_REGISTRY" ]; then \
        npm config set registry "$NPM_REGISTRY" && \
        npm config set strict-ssl false; \
    fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --loglevel=error; else npm install --loglevel=error; fi
COPY . .

# Force correct values in .env (overrides any competitor changes)
RUN sed -i "s|^MONGO_URI=.*|MONGO_URI=\"mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_HOST}:27017/${MONGO_DB}?authSource=admin\"|" .env && \
    sed -i "s|^MONGO_DB=.*|MONGO_DB=\"${MONGO_DB}\"|" .env

EXPOSE 80

CMD ["node", "src/server.js"]
