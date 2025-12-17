FROM node:lts

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --loglevel=error
COPY . .

EXPOSE 80

CMD ["node", "src/server.js"]

