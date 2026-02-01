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

# 3. Bun и Corepack
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

# 6. Подготовка конфига и прав доступа
# Создаем папку настроек
RUN mkdir -p /home/node/.openclaw

# === МАГИЯ ЗДЕСЬ ===
# Мы принудительно создаем конфиг, который говорит серверу: "Слушай весь интернет (0.0.0.0)"
# Также мы прописываем сюда настройки для смены модели на OpenAI
RUN echo '{\
  "gateway": { "host": "0.0.0.0" },\
  "llm": { "provider": "openai", "model": "gpt-4o" }\
}' > /home/node/.openclaw/openclaw.json

# Передаем права на папку пользователю node
RUN chown -R node:node /home/node/.openclaw

# 7. Запуск
USER node

# Запускаем gateway. Порт передаем через флаг (он перекроет конфиг, если что),
# а --allow-unconfigured больше не нужен, так как конфиг мы создали выше.
CMD node dist/index.js gateway --port $PORT
