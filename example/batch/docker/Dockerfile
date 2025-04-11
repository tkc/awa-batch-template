# Stage 1: Build stage - Install dependencies
FROM --platform=linux/amd64 python:3.11-slim as builder

# Install build tools and Poetry
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

# Set working directory
WORKDIR /app

# Configure Poetry to not create virtualenvs
RUN poetry config virtualenvs.create false

# Copy only dependency definition files first to leverage Docker cache
# These files are located in the build context directory (example/batch)
COPY pyproject.toml poetry.lock ./

# Install dependencies defined in example/batch/pyproject.toml
# Use --no-root to prevent installation of the current project (batch), only its dependencies
RUN poetry install --no-interaction --no-ansi --no-root

# Stage 2: Runtime stage - Create the final image
FROM --platform=linux/amd64 python:3.11-slim as runtime

# Create a non-root user and group
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Copy installed Python packages from the builder stage's global site-packages directory
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy the batch run script from the current context
COPY src/run_batch_test.py /app/run_batch_test.py

# Debug: Print the architecture to the logs at startup
RUN echo "Container architecture: $(uname -m)"

# Ensure the app directory and its contents are owned by the appuser
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Define the entrypoint to run the batch script using python
ENTRYPOINT ["python", "/app/run_batch_test.py"]
