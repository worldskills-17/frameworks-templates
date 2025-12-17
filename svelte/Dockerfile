FROM node:lts as build-stage

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --loglevel=error
COPY . .
RUN npm run build

# Fix absolute paths for subdirectory deployment
RUN find build -name '*.html' -exec sed -i 's|"/_app/|"./_app/|g' {} \; && \
    find build -name '*.html' -exec sed -i 's|href="/_app/|href="./_app/|g' {} \; && \
    find build -name '*.js' -exec sed -i 's|"/_app/|"./_app/|g' {} \;

FROM nginx:alpine

COPY --from=build-stage /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
