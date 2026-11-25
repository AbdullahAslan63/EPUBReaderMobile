FROM node:22-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ocrmypdf \
    tesseract-ocr-eng \
    tesseract-ocr-tur \
    calibre \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY src ./src

ENV PORT=8080 \
    CONVERTER_DATA_DIR=/data \
    OCR_LANGS=tur+eng \
    HOME=/tmp

RUN mkdir -p /data
VOLUME /data
EXPOSE 8080
CMD ["node", "src/index.js"]
