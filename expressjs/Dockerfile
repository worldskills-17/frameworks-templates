FROM node:lts

WORKDIR /app
COPY package.json package.json* ./
RUN npm ci --verbose
COPY . .

EXPOSE 80

CMD ["node", "src/server.js"]

