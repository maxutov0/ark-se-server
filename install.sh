#!/bin/bash

# Загрузка переменных из .env
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo "Файл .env не найден!"
    exit 1
fi

# Функция для логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -ne 0 ]; then
        log "Ошибка: $1"
        exit 1
    fi
}

# Обновление пакетов
log "Обновление списка пакетов..."
sudo apt-get update
check_success "Не удалось обновить список пакетов."

log "Обновление установленных пакетов..."
sudo apt-get upgrade -y
check_success "Не удалось обновить пакеты."

# Установка необходимых зависимостей
log "Установка lib32gcc-s1..."
sudo apt-get install -y lib32gcc-s1
check_success "Не удалось установить lib32gcc-s1."

# Добавление репозитория multiverse и архитектуры i386
log "Добавление репозитория multiverse и архитектуры i386..."
sudo add-apt-repository -y multiverse
sudo dpkg --add-architecture i386
sudo apt update
check_success "Не удалось добавить репозиторий multiverse или архитектуру i386."

# Установка steamcmd
log "Установка steamcmd..."
sudo apt install -y steamcmd
check_success "Не удалось установить steamcmd."

# Создание символической ссылки для steamcmd
if [ ! -f /usr/games/steamcmd ]; then
    log "Создание символической ссылки для steamcmd..."
    sudo ln -s /usr/games/steamcmd /usr/bin/steamcmd
    check_success "Не удалось создать символическую ссылку для steamcmd."
fi

# Установка ARK через steamcmd
log "Установка ARK через steamcmd..."
steamcmd +force_install_dir "$ARK_DIR" +login anonymous +app_update "$STEAM_APP_ID" +quit
check_success "Не удалось установить ARK через steamcmd."

# Настройка лимита открытых файлов
log "Настройка лимита открытых файлов..."

# Добавление в /etc/sysctl.conf
log "Добавление fs.file-max в /etc/sysctl.conf..."
echo "fs.file-max=100000" | sudo tee -a /etc/sysctl.conf > /dev/null
check_success "Не удалось добавить fs.file-max в /etc/sysctl.conf."

# Применение изменений из /etc/sysctl.conf
log "Применение изменений из /etc/sysctl.conf..."
sudo sysctl -p /etc/sysctl.conf
check_success "Не удалось применить изменения из /etc/sysctl.conf."

# Добавление в /etc/security/limits.conf
log "Добавление лимитов в /etc/security/limits.conf..."
echo -e "*\t\tsoft\tnofile\t1000000\n*\t\thard\tnofile\t1000000" | sudo tee -a /etc/security/limits.conf > /dev/null
check_success "Не удалось добавить лимиты в /etc/security/limits.conf."

# Добавление в /etc/pam.d/common-session
log "Добавление pam_limits.so в /etc/pam.d/common-session..."
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session > /dev/null
check_success "Не удалось добавить pam_limits.so в /etc/pam.d/common-session."

log "Настройка лимита открытых файлов завершена."

log "Установка ARK сервера завершена успешно!"