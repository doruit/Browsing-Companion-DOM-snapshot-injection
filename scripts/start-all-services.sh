#!/bin/bash

# Start All Services for Browsing Companion
# This script starts the AI service, API Gateway, and Frontend

echo "🚀 Starting Browsing Companion Services..."
echo ""

# Get the project root directory (parent of scripts folder)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f "uvicorn main:app" 2>/dev/null
pkill -f "nodemon" 2>/dev/null
pkill -f "vite" 2>/dev/null
sleep 2

# Start AI Service
echo "🤖 Starting AI Service (port 8000)..."
cd "$SCRIPT_DIR/services/ai-service"
source "$SCRIPT_DIR/services/ai-service/venv/bin/activate"
uvicorn main:app --reload --host 0.0.0.0 --port 8000 > "$SCRIPT_DIR/logs/ai-service.log" 2>&1 &
AI_PID=$!
echo "   ✓ AI Service started (PID: $AI_PID)"

# Start API Gateway
echo "🌐 Starting API Gateway (port 3001)..."
cd "$SCRIPT_DIR/services/api-gateway"
npm run dev > "$SCRIPT_DIR/logs/api-gateway.log" 2>&1 &
GATEWAY_PID=$!
echo "   ✓ API Gateway started (PID: $GATEWAY_PID)"

# Start Frontend
echo "💻 Starting Frontend (port 3000)..."
cd "$SCRIPT_DIR/frontend"
npm run dev > "$SCRIPT_DIR/logs/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo "   ✓ Frontend started (PID: $FRONTEND_PID)"

echo ""
echo "✅ All services started!"
echo ""
echo "📍 Service URLs:"
echo "   • AI Service:   http://localhost:8000"
echo "   • API Gateway:  http://localhost:3001"
echo "   • Frontend:     http://localhost:3000"
echo ""
echo "📝 Logs are being written to the logs/ directory"
echo ""
echo "To stop all services, run: ./stop-all-services.sh"
echo "Or press Ctrl+C and run: pkill -f 'uvicorn|nodemon|vite'"
