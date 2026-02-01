# Основа - Node 22 (Debian Bookworm)
FROM node:22-bookworm

# 1. Устанавливаем Chromium и системные зависимости
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 2. Настраиваем Puppeteer на системный Chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# 3. Устанавливаем Bun (нужен для скриптов)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Включаем pnpm
RUN corepack enable

WORKDIR /app

# 4. Копируем конфиги
COPY package.json pnpm-workspace.yaml .npmrc ./

COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# 5. Устанавливаем зависимости
RUN pnpm install

# 6. Копируем остальной код и билдим
COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build

# Сборка UI
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# 7. Безопасность
USER node

# 8. ЗАПУСК (ИСПРАВЛЕНО ТУТ)
# Добавили аргумент "gateway", чтобы запустить сам сервер, а не просто меню помощи
# Убрали --host, оставили только --port
CMD node dist/index.js gateway --allow-unconfigured --port $PORT
