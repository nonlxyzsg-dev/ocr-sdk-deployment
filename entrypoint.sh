#!/bin/bash
set -e

# Запускаем сервер в фоне
python -m glmocr.server --config /app/config.yaml &
SERVER_PID=$!

# Ждём пока /health начнёт отвечать (макс 90 сек)
echo "[entrypoint] Waiting for server to become ready..."
for i in {1..45}; do
    if python -c "import urllib.request; urllib.request.urlopen('http://localhost:5002/health', timeout=2).read()" 2>/dev/null; then
        echo "[entrypoint] Server ready after ${i}x2s"
        break
    fi
    sleep 2
done

# Прогрев: один реальный запрос через весь pipeline
echo "[entrypoint] Warming up pipeline with schet-10.pdf..."
WARMUP_START=$(date +%s)
python -c "
import urllib.request, json
req = urllib.request.Request(
    'http://localhost:5002/glmocr/parse',
    data=json.dumps({'images': ['/test-data/schet-10.pdf']}).encode(),
    headers={'Content-Type': 'application/json'}
)
try:
    resp = urllib.request.urlopen(req, timeout=120).read()
    print(f'[entrypoint] Warmup OK ({len(resp)} bytes)')
except Exception as e:
    print(f'[entrypoint] Warmup FAILED: {e}')
" || true
WARMUP_END=$(date +%s)
echo "[entrypoint] Warmup took $((WARMUP_END - WARMUP_START))s. Server ready for production requests."

# Передаём управление серверу (ждём завершения)
wait $SERVER_PID
