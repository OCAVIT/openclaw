FROM node:22-bookworm

# 1. Устанавливаем Chromium и зависимости
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 2. Переменные для браузера
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# 3. Устанавливаем Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable

WORKDIR /app

# 4. Копируем файлы проекта
COPY package.json pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# 5. Устанавливаем и собираем
RUN pnpm install
COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build
ENV NODE_ENV=production

# 6. Безопасность
USER node

# === ИСПРАВЛЕНИЕ ===
# Вместо создания JSON-файла, задаем настройки через переменные окружения.
# Это заставляет сервер слушать внешний мир (0.0.0.0)
ENV HOST=0.0.0.0
ENV OPENCLAW_GATEWAY_HOST=0.0.0.0

# 7. Запуск
# Мы используем --allow-unconfigured, чтобы он не требовал файл openclaw.json
# Порт передаем через $PORT от Railway
CMD node dist/index.js gateway --allow-unconfigured --port $PORT
