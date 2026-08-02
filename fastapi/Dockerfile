# fastapi - Python app. PIP_INDEX_URL points at the offline PyPI mirror (devpi)
# during competition builds; defaults to PyPI for local/online builds.
FROM python:3.12-slim

ARG PIP_INDEX_URL=https://pypi.org/simple/
ARG PIP_TRUSTED_HOST=
ENV PIP_INDEX_URL=${PIP_INDEX_URL} \
    PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt ./
RUN for i in 1 2 3; do pip install --no-cache-dir -r requirements.txt && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done
COPY . .

EXPOSE 80
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
