# Use official Python runtime as base
FROM python:3.14-slim AS builder

WORKDIR /code

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final minimal runner stage
FROM python:3.14-slim AS runner

WORKDIR /code

# Copy packages from builder
COPY --from=builder /root/.local /root/.local
COPY app /code/app

ENV PATH=/root/.local/bin:$PATH
EXPOSE 8000

# Run uvicorn server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
