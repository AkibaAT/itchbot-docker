#!/bin/sh
set -e

echo "Applying database migrations"
alembic upgrade head

exec "$@"
