FROM node:lts

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then \
        npm config set registry "$NPM_REGISTRY" && \
        npm config set strict-ssl false; \
    fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --loglevel error
COPY . .

EXPOSE 80

CMD ["node", "src/server.js"]

