#!/bin/bash

cd ~/Desktop/navoiy_v3.1_full/navoiy_backend

echo "=========================================="
echo "  NAVOIY API - AVTOMATIK ISHGA TUSHIRISH"
echo "=========================================="

# Ngrok ni tekshirish va ishga tushirish
start_ngrok() {
    if command -v ngrok &> /dev/null; then
        echo "✅ Ngrok topildi, ishga tushirilmoqda..."
        ngrok http 8000 --log=stdout > ngrok.log 2>&1 &
        NGROK_PID=$!
        echo "   Ngrok PID: $NGROK_PID"
        sleep 3
    else
        echo "⚠️  Ngrok o'rnatilmagan."
        echo "   O'rnatish: snap install ngrok"
        echo "   yoki: https://ngrok.com/download"
    fi
}

# PostgreSQL tekshirish
if ! systemctl is-active --quiet postgresql; then
    echo "🔄 PostgreSQL ishga tushirilmoqda..."
    sudo systemctl start postgresql
fi

# Ngrok ni fonda ishga tushirish
start_ngrok

# Virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
fi

echo ""
echo "🚀 FastAPI server ishga tushirilmoqda..."
echo ""

# Serverni ishga tushirish
PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Server to'xtaganda ngrok ni ham to'xtatish
if [ ! -z "$NGROK_PID" ]; then
    kill $NGROK_PID 2>/dev/null
fi