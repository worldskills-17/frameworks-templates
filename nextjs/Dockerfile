FROM node:lts as build-stage

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
RUN npm run build

FROM nginx:alpine

COPY --from=build-stage /app/out /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
