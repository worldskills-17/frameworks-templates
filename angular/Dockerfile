FROM node:lts as build-stage

# Configure npm registry for Verdaccio cache
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --loglevel=error
COPY . .
RUN npm run build

FROM nginx:alpine

# Angular 17+ outputs to dist/<project-name>/browser/
# Copy dist folder, then find browser folder and copy contents to nginx root
COPY --from=build-stage /app/dist /tmp/dist
RUN BROWSER_DIR=$(find /tmp/dist -type d -name "browser" | head -1) && \
    if [ -n "$BROWSER_DIR" ]; then \
      cp -r "$BROWSER_DIR"/* /usr/share/nginx/html/; \
    else \
      cp -r /tmp/dist/*/* /usr/share/nginx/html/ 2>/dev/null || cp -r /tmp/dist/* /usr/share/nginx/html/; \
    fi && \
    rm -rf /tmp/dist

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
