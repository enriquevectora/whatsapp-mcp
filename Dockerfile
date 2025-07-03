# Etapa 1: Construir el puente de Go
FROM golang:1.21-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
COPY whatsapp-bridge/go.mod whatsapp-bridge/go.sum ./
RUN go mod download
COPY whatsapp-bridge/ ./
# Necesitamos un compilador de C para la dependencia de SQLite
RUN apk add --no-cache build-base
RUN CGO_ENABLED=1 GOOS=linux go build -o /whatsapp-bridge-server main.go

# Etapa 2: Preparar el servidor de Python
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
COPY --from=builder /whatsapp-bridge-server /usr/local/bin/
COPY whatsapp-mcp-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY whatsapp-mcp-server/ .

# Directorio para la base de datos y la sesión de WhatsApp
RUN mkdir -p /data/store
VOLUME /data

EXPOSE 8000

# Comando para iniciar ambos servicios
# Nota: Esto es una simplificación. Un script de inicio sería más robusto.
# Por ahora, iniciamos el servidor MCP. El puente se debe manejar por separado o integrar en el script.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
