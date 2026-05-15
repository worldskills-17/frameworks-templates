FROM node:lts as build-stage

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY=http://verdaccio:4873
RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --loglevel error
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
