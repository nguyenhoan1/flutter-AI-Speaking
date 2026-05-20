#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Run Flutter app trong dev mode với OpenAI API key.
#
# Cách dùng:
#   1. Copy .env.example thành .env và điền key vào
#   2. Chạy: bash scripts/run_dev.sh
#
# Hoặc gọi trực tiếp:
#   OPENAI_API_KEY=sk-proj-xxx bash scripts/run_dev.sh
# ─────────────────────────────────────────────────────────────────────
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Load .env nếu có
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ OPENAI_API_KEY chưa được set."
  echo "   Tạo file .env (copy từ .env.example) và điền key, hoặc:"
  echo "   OPENAI_API_KEY=sk-proj-xxx bash scripts/run_dev.sh"
  exit 1
fi

echo "🚀 Đang chạy Flutter với OpenAI API key (***${OPENAI_API_KEY: -6})..."
flutter run --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" "$@"
