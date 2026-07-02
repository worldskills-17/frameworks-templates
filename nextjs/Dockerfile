FROM node:22-alpine

# npm registry + optional database configuration as build arguments.
# DB_* are OPTIONAL: they are baked into the runtime env so a competitor CAN use
# MySQL (mysql2/knex) if they want. Nothing connects automatically — a plain
# Next.js app simply ignores them, so an empty DB config never breaks the build.
# DB_* args are declared right before first use (bottom of file), not here -
# early declaration would bust the npm/build layer cache for every new module
# repo (classic builder folds ARG values into RUN cache keys).
ARG NPM_REGISTRY=http://verdaccio:4873

RUN npm config set registry "$NPM_REGISTRY" && \
    npm config set strict-ssl false

# libc6-compat for Next.js native deps — retry on transient Alpine CDN errors
RUN for i in 1 2 3; do apk add --no-cache libc6-compat && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done

WORKDIR /app

COPY package.json package-lock.json* ./
RUN for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done

COPY . .

RUN npm run build

# DB connection available at runtime for competitors who opt in to MySQL.
# Individual vars for mysql2/knex; DATABASE_URL for tools that expect a URL.
ARG DB_HOST
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ENV DB_HOST=${DB_HOST} \
    DB_NAME=${DB_NAME} \
    DB_USERNAME=${DB_USERNAME} \
    DB_PASSWORD=${DB_PASSWORD} \
    DATABASE_URL=mysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:3306/${DB_NAME}

EXPOSE 80

CMD ["npm", "run", "start"]
