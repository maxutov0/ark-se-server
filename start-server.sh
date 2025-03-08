#!/bin/bash

# Загрузка переменных из .env
if [ -f .env ]; then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "Файл .env не найден!"
    exit 1
fi

# Путь к исполняемому файлу сервера
SERVER_BIN="./ShooterGame/Binaries/Linux/ShooterGameServer"

# Проверка существования исполняемого файла сервера
if [ ! -f "$SERVER_BIN" ]; then
    echo "Ошибка: Исполняемый файл сервера не найден по пути $SERVER_BIN."
    exit 1
fi

# Запуск сервера с параметрами из .env
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Запуск сервера ARK..."
"$SERVER_BIN" "$MAP_NAME?listen?SessionName=$SESSION_NAME?ServerPassword=$SERVER_PASSWORD?ServerAdminPassword=$SERVER_ADMIN_PASSWORD" -server -log

# Проверка успешности запуска
if [ $? -ne 0 ]; then
    log "Ошибка: Не удалось запустить сервер ARK."
    exit 1
fi
