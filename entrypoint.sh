#!/bin/bash
set -e

echo "Starting Blogger to Jekyll migration..."

# Run the migration script
/app/migration/migrate.sh

# Clean up the output directory before copying new files
echo "Cleaning up output directory..."
if [ -d "/app/output" ] && [ "$(ls -A /app/output)" ]; then
  rm -rf /app/output/*
fi

# Copy the generated Jekyll site to the mounted volume
echo "Copying Jekyll site to output directory..."
cp -r /app/jekyll_site/* /app/output/

echo "Migration completed successfully!" 