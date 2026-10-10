FROM node:20.20.2-alpine3.23 AS builder

# Set the working directory
WORKDIR /app

COPY package.json .
COPY *.js .

# Install dependencies
RUN npm install

#  at Runtime stage 
FROM node:20.20.2-alpine3.23

WORKDIR /app

EXPOSE 8080

ENV MONGO="true" \
    MONGO_URL="mongodb://mongodb:27017/catalogue"

RUN apk update && apk upgrade --no-cache && \
    addgroup -S roboshop && \
    adduser -S -G roboshop roboshop && \
    chown -R roboshop:roboshop /app

COPY --from=builder /app /app

USER roboshop

CMD ["node", "server.js"]