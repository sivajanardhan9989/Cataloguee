FROM node:22-alpine3.23 AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY *.js ./

# Set read-only permissions on application files.
# Directories need execute permission for traversal.
RUN find /app -type d -exec chmod 0550 {} \; && \
    find /app -type f -exec chmod 0440 {} \;

# Stage 2: Runtime image
FROM node:22-alpine3.23

WORKDIR /app

ENV MONGO="true" \
    MONGO_URL="mongodb://mongodb:27017/catalogue"

EXPOSE 8080

# Create a non-root application user
RUN addgroup -S roboshop && \
    adduser -S -G roboshop roboshop

# Copy application files without write permissions
COPY --from=builder --chown=roboshop:roboshop /app /app

USER roboshop

CMD ["node", "server.js"]
