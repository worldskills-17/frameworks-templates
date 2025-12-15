FROM node:lts

WORKDIR /app
COPY package.json package.json* ./
RUN npm ci --loglevel=error
COPY . .

EXPOSE 80

CMD ["node", "src/server.js"]

