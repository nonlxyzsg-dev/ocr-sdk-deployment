FROM python:3.12-slim

# Системные зависимости: libgomp1 для torch OpenMP runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Увеличиваем pip timeout — дефолт 15 сек слишком мал для больших wheels (torch)
ENV PIP_DEFAULT_TIMEOUT=120 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Установка glmocr со всеми нужными extras одной командой
# [selfhosted] → torch, torchvision, transformers, sentencepiece, accelerate, pypdfium2
# [server]     → flask
RUN pip install "glmocr[selfhosted,server]==0.1.4" opencv-python-headless opencv-python-headless opencv-python-headless

# Рабочий каталог внутри контейнера (сюда монтируется config.yaml через compose)
WORKDIR /app

# Flask слушает на 5002 по дефолту (GLM-OCR SDK встроенный дефолт)
EXPOSE 5002

# Запуск сервера. --config указывает на монтированный config.yaml.
# Всё остальное конфигурируется через GLMOCR_* env vars из compose.
CMD ["python", "-m", "glmocr.server", "--config", "/app/config.yaml"]
