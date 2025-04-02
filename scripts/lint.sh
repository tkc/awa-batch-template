#!/bin/bash
set -e

echo "Running Ruff format..."
poetry run ruff format .

echo "Running Ruff check..."
poetry run ruff check . --fix

echo "Running Pyright type check..."
poetry run pyright

echo "Linting and type checking completed successfully."
