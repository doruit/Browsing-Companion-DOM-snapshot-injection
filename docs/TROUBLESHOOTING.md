# Troubleshooting Guide

This guide covers common setup and runtime issues for the Browsing Companion demo.

## 📑 Table of Contents

- [Python Environment Issues](#python-environment-issues)
- [Node.js Environment Issues](#nodejs-environment-issues)
- [Environment File Issues](#environment-file-issues)
- [Service Startup Issues](#service-startup-issues)
- [Runtime Issues](#runtime-issues)
- [Quick Reset](#quick-reset)

---

## Python Environment Issues

### Problem: `python: command not found` or `python3: command not found`

```bash
# Solution: Check if Python is installed
python --version  # or python3 --version

# macOS: Install via Homebrew
brew install python@3.11

# Windows: Download from https://www.python.org/downloads/
# Linux (Ubuntu/Debian): 
sudo apt update && sudo apt install python3.11 python3.11-venv
```

### Problem: Virtual environment not activating

```bash
# If "source venv/bin/activate" fails, try:
. venv/bin/activate

# Windows PowerShell (if restricted):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
venv\Scripts\Activate.ps1
```

### Problem: `pip install` fails with permission errors

```bash
# Solution: Ensure virtual environment is activated
# Your prompt should show (venv) at the beginning
# If not, run: source venv/bin/activate

# Never use sudo with pip inside a virtual environment
```

---

## Node.js Environment Issues

### Problem: `npm: command not found`

```bash
# Solution: Install Node.js
# macOS: 
brew install node

# Windows: Download from https://nodejs.org/
# Linux (Ubuntu/Debian):
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Problem: `npm install` fails with EACCES errors

```bash
# Solution: Fix npm permissions (don't use sudo!)
# macOS/Linux:
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

### Problem: Port already in use (EADDRINUSE)

```bash
# Find process using the port (e.g., 3000, 3001, or 8000):
# macOS/Linux:
lsof -i :3000
kill -9 <PID>

# Windows:
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

---

## Environment File Issues

### Problem: Services start but can't connect to Azure

```bash
# Solution 1: Verify .env.local files exist
ls -la services/ai-service/.env.local
ls -la services/api-gateway/.env.local
ls -la frontend/.env.local

# Solution 2: Re-run environment setup
./scripts/setup-env.sh

# Solution 3: Check Azure CLI login
az account show
```

### Problem: Missing deployment-outputs.json

```bash
# This file is created during deployment
# If missing, you need to redeploy:
./scripts/deploy.sh
```

---

## Service Startup Issues

### Problem: Python service fails with import errors

```bash
# Ensure you're in the virtual environment
cd services/ai-service
source venv/bin/activate  # Should show (venv) in prompt
pip list  # Verify packages are installed
pip install -r requirements.txt --force-reinstall
```

### Problem: Frontend shows blank page

```bash
# Check browser console (F12) for errors
# Common issues:
# 1. API Gateway not running (check http://localhost:3001/health)
# 2. CORS errors (ensure all services started in correct order)
# 3. .env.local missing in frontend/
```

### Problem: Chat doesn't respond

```bash
# Verify all three services are running:
curl http://localhost:8000/health     # Python AI Service
curl http://localhost:3001/health     # Node.js Gateway
curl http://localhost:3000            # React Frontend

# Check logs in each terminal for error messages
```

---

## Runtime Issues

### "Deployment failed" error
- Ensure you have Contributor role on the subscription
- Check if you have available quota for Azure OpenAI in the selected region
- Try a different region (e.g., `westus`, `swedencentral`)

### "Cannot connect to AI service" error
- Verify all three services are running
- Check `.env.local` files have correct URLs
- Ensure ports 3000, 3001, 8000 are not in use

### "Key Vault access denied" error
- Run: `az ad signed-in-user show --query id -o tsv` and verify the Object ID
- Ensure you ran `deploy.sh` which grants you Key Vault access

---

## Quick Reset

If everything seems broken, try a fresh start:

```bash
# Stop all services (Ctrl+C in all terminals)

# Clean and reinstall dependencies
cd services/ai-service
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ../..

cd services/api-gateway
rm -rf node_modules package-lock.json
npm install
cd ../..

cd frontend
rm -rf node_modules package-lock.json
npm install
cd ..

# Restart all services in separate terminals
```

---

## Still Having Issues?

1. Check the [Enterprise Grade Score](ENTERPRISE_GRADE_SCORE.md) for known limitations
2. Open an issue on GitHub with:
   - Your OS and versions (Node, Python, npm)
   - The exact error message
   - Steps to reproduce
3. [Reach out on LinkedIn](https://www.linkedin.com/in/dvanderuit/)
