FROM node:22-alpine as build-stage

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY=http://verdaccio:4873
RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

WORKDIR /app
COPY package.json package-lock.json* ./
RUN for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done
COPY . .
# Normalize the output dir: Vite/Vue CLI emit dist/, other scaffolds may emit build/
RUN npm run build && \
    if [ -d dist ]; then mv dist /site; \
    elif [ -d build ]; then mv build /site; \
    else echo "No dist/ or build/ output found" && exit 1; fi

FROM nginx:alpine

COPY --from=build-stage /site /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
