#!/bin/bash

# Stop All Services for Browsing Companion

echo "🛑 Stopping all services..."

pkill -f "uvicorn main:app"
pkill -f "nodemon"
pkill -f "vite"

sleep 1

echo "✅ All services stopped!"
