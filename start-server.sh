#!/bin/bash

# Загрузка переменных из .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден. Создайте его и настройте переменные."
  exit 1
fi

# Проверка, установлен ли сервер
if [ ! -f "$ARK_SERVER_DIR/ShooterGame/Binaries/Linux/ShooterGameServer" ]; then
  echo "❌ Сервер ARK не установлен. Сначала запустите install_ark.sh."
  exit 1
fi

# Проверка, запущен ли сервер
if screen -list | grep -q "ark-server"; then
  echo "❌ Сервер ARK уже запущен."
  exit 1
fi

# Запуск сервера
echo "🔄 Запуск сервера ARK..."
screen -dmS ark-server "$ARK_SERVER_DIR/ShooterGame/Binaries/Linux/ShooterGameServer" "$ARK_MAP?listen?SessionName=$ARK_SERVER_NAME?ServerPassword=$ARK_SERVER_PASSWORD?ServerAdminPassword=$ARK_ADMIN_PASSWORD" -server -log
echo "✅ Сервер ARK запущен в screen-сессии."
echo "Используйте команду 'screen -r ark-server' для подключения к консоли сервера."