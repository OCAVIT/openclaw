# Основа - как в оригинале, используем Debian-based образ (bookworm)
FROM node:22-bookworm

# 1. Устанавливаем Chromium и зависимости (Взято из твоего первого файла и адаптировано)
# Это нужно, чтобы браузер мог запуститься в Linux среде Railway
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 2. Настраиваем переменные для Puppeteer (чтобы он использовал установленный Chromium)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# 3. Устанавливаем Bun (Нужен для скриптов сборки OpenClaw - из оригинального файла)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Включаем pnpm (критично для OpenClaw)
RUN corepack enable

WORKDIR /app

# 4. Копируем файлы конфигурации проекта
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# 5. Устанавливаем зависимости через pnpm
RUN pnpm install --frozen-lockfile

# 6. Копируем весь код и собираем
COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build

# Сборка UI (с фиксом для ARM/архитектур, как в оригинале)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# 7. Безопасность: запускаем от пользователя node (не root)
USER node

# 8. Запуск
CMD ["node", "dist/index.js"]
