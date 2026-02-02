FROM node:22-alpine

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --loglevel=error; else npm install --loglevel=error; fi
COPY . .

EXPOSE 80

CMD ["node", "src/server.js"]
