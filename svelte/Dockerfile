FROM node:24 AS build-stage

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY=http://verdaccio:4873
RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

WORKDIR /app
COPY package.json package-lock.json* ./
RUN for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done
COPY . .
# Normalize the output dir: SvelteKit emits build/, plain Vite+Svelte emits dist/
RUN npm run build && \
    if [ -d build ]; then mv build /site; \
    elif [ -d dist ]; then mv dist /site; \
    else echo "No build/ or dist/ output found" && exit 1; fi
# Asset paths are left as SvelteKit emits them: the app is served at the domain
# root, and the SPA fallback page needs absolute /_app/ paths so nested routes
# (e.g. /a/b) still load their scripts.

FROM nginx:alpine

COPY --from=build-stage /site /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
