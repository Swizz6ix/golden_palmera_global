# syntax=docker/dockerfile:1

FROM node:26.7.0-alpine3.24 AS base


# ----------------------------------------
# Dependencies
# ----------------------------------------

FROM base AS deps

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci


# ----------------------------------------
# Build
# ----------------------------------------

FROM base AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build


# ----------------------------------------
# Production
# ----------------------------------------

FROM node:26.7.0-alpine3.24 AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Create non-root user
RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache libstdc++ \
    && addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs \

    # Remove global npm/corepack/yarn modules to wipe out any inherited vulnerabilities
    && rm -rf /usr/local/lib/node_modules /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack /opt/yarn*

# Copy only the Node runtime
COPY --from=builder /usr/local/bin/node /usr/local/bin/node

# Nextjs standalone application
COPY --from=builder /app/public ./public

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]