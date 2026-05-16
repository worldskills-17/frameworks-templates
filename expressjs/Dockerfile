FROM node:lts

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY=http://verdaccio:4873
RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

WORKDIR /app
COPY package.json package-lock.json* ./
RUN for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done
COPY . .

EXPOSE 80

CMD ["node", "src/server.js"]

