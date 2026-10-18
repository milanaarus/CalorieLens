# The source archive contains the current reviewed application.
FROM python:3.11-slim-bookworm AS source
COPY CalorieVision-source.zip /tmp/source.zip
RUN python -c "import zipfile; zipfile.ZipFile('/tmp/source.zip').extractall('/source')"

FROM node:22-bookworm-slim AS frontend
WORKDIR /build
COPY --from=source /source/CalorieVision/frontend/package.json /source/CalorieVision/frontend/package-lock.json ./
RUN npm ci --ignore-scripts
COPY --from=source /source/CalorieVision/frontend/ ./
RUN npm run build

FROM python:3.11-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    FRONTEND_DIST=/app/frontend-dist \
    NUTRITION_CACHE_PATH=/tmp/calorievision/nutrition-cache.sqlite3 \
    OMP_NUM_THREADS=1 MPLCONFIGDIR=/tmp/matplotlib
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
# CPU-only packages avoid downloading CUDA libraries on a small server.
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu
COPY --from=source /source/CalorieVision/backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=source /source/CalorieVision/backend/app/ ./app/
COPY --from=source /source/CalorieVision/backend/yolov8n.pt ./yolov8n.pt
COPY --from=frontend /build/dist ./frontend-dist/
RUN useradd --create-home --uid 10001 calorievision
USER calorievision
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
    CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:'+os.getenv('PORT','8000')+'/health', timeout=3)" || exit 1
CMD ["sh", "-c", "exec uvicorn app.production:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"]
