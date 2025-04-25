# Use a Python image with uv pre-installed
FROM --platform=linux/amd64 ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install git if needed by dependencies (apt-get update is needed first)
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Enable bytecode compilation (optional, can improve startup time slightly)
ENV UV_COMPILE_BYTECODE=1

# Use copy link mode for uv (recommended in some environments)
ENV UV_LINK_MODE=copy

# Install only the project's dependencies using the lockfile.
# Mount the lockfile and pyproject.toml, and a cache directory.
# Use --frozen to ensure lockfile is up-to-date.
# Use --no-install-project to avoid installing the project itself here.
# Use --no-dev to exclude development dependencies.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Copy the application code
COPY run_batch.py /app/run_batch.py

# Create a non-root user and group
# Do this after installing dependencies to potentially improve caching
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser

# Debug: Print the architecture to the logs at startup
RUN echo "Container architecture: $(uname -m)"

# Ensure the app directory and its contents are owned by the appuser
RUN chown appuser:appuser /app/run_batch.py

# Switch to the non-root user
USER appuser

# Place the virtual environment's bin directory at the front of the PATH
# This ensures that the installed packages are found
ENV PATH="/app/.venv/bin:$PATH"

# Define the entrypoint to run the batch script using python
# The python interpreter within the virtual environment will be used due to PATH setting
ENTRYPOINT ["python", "/app/run_batch.py"]
