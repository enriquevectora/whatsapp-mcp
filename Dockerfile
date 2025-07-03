# Etapa 1: Construir el puente de Go
FROM golang:1.21-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git build-base
COPY whatsapp-bridge/go.mod whatsapp-bridge/go.sum ./
RUN go mod download
COPY whatsapp-bridge/ ./
RUN CGO_ENABLED=1 GOOS=linux go build -o /whatsapp-bridge-server main.go

# Etapa 2: Preparar el servidor de Python
FROM python:3.10-slim
WORKDIR /app

# Copiar el puente de Go compilado de la etapa anterior
COPY --from=builder /whatsapp-bridge-server /usr/local/bin/

# Copiar todo el código del servidor MCP
COPY whatsapp-mcp-server/ .

# Instalar las dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Directorio para la base de datos y la sesión de WhatsApp
RUN mkdir -p /data/store
VOLUME /data

EXPOSE 8000

# Comando para iniciar el servidor
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
