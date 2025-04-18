# Stage 1: Build stage - Install dependencies
FROM --platform=linux/amd64 python:3.12-slim as builder

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Stage 2: Runtime stage - Create the final image
FROM --platform=linux/amd64 python:3.12-slim as runtime

# Create a non-root user and group
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Copy installed Python packages from the builder stage's global site-packages directory
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copy the batch run script from the current context
COPY run_batch.py /app/run_batch.py

# Debug: Print all content of run_batch.py during build to verify content
RUN cat /app/run_batch.py

# Debug: Print the architecture to the logs at startup
RUN echo "Container architecture: $(uname -m)"

# Ensure the app directory and its contents are owned by the appuser
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Define the entrypoint to run the batch script using python
ENTRYPOINT ["python", "/app/run_batch.py"]
