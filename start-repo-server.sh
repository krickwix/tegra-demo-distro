#!/bin/bash
# Simple HTTP server for testing the repository

PORT=8080
BASE_DIR="/media/fandrieu/build/all/tmp/deploy/rpm"

echo "Starting HTTP server on port $PORT..."
echo "Repository will be available at: http://localhost:$PORT/"
echo "Press Ctrl+C to stop"

cd "$BASE_DIR/.." && python3 -m http.server $PORT
