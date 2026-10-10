FROM node:22-alpine3.23 AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY *.js ./

FROM node:22-alpine3.23

WORKDIR /app
EXPOSE 8080

ENV MONGO="true" \
    MONGO_URL="mongodb://mongodb:27017/catalogue"

RUN addgroup -S roboshop && adduser -S -G roboshop roboshop

COPY --from=builder --chown=roboshop:roboshop /app /app

USER roboshop
CMD ["node", "server.js"]