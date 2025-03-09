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

# Создание и настройка swap-файла
SWAP_SIZE="4G"
SWAP_FILE="/swapfile"

log "Проверка, существует ли swap-файл..."
if swapon --show | grep -q "$SWAP_FILE"; then
    log "Swap-файл уже существует и активирован."
else
    log "Создание swap-файла размером $SWAP_SIZE..."
    sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || sudo dd if=/dev/zero of="$SWAP_FILE" bs=1G count=4
    check_success "Не удалось создать swap-файл."

    log "Настройка прав доступа для swap-файла..."
    sudo chmod 600 "$SWAP_FILE"
    check_success "Не удалось настроить права доступа для swap-файла."

    log "Настройка swap-файла..."
    sudo mkswap "$SWAP_FILE"
    check_success "Не удалось настроить swap-файл."

    log "Активация swap..."
    sudo swapon "$SWAP_FILE"
    check_success "Не удалось активировать swap."

    log "Добавление swap в /etc/fstab для автоматической загрузки при перезагрузке..."
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
        check_success "Не удалось добавить swap в /etc/fstab."
    else
        log "Swap уже добавлен в /etc/fstab."
    fi

    log "Настройка swappiness на 10..."
    sudo sysctl vm.swappiness=10
    check_success "Не удалось настроить swappiness."

    log "Добавление swappiness в /etc/sysctl.conf для постоянного изменения..."
    if ! grep -q "vm.swappiness=10" /etc/sysctl.conf; then
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        check_success "Не удалось добавить swappiness в /etc/sysctl.conf."
    else
        log "Swappiness уже добавлен в /etc/sysctl.conf."
    fi

    log "Swap успешно настроен."
fi

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

# Установка ARK через steamcmd
log "Установка ARK через steamcmd..."
steamcmd +force_install_dir "$HOME/ark-se-server" +login anonymous +app_update "$STEAM_APP_ID" +quit
check_success "Не удалось установить ARK через steamcmd."

log "Установка ARK сервера завершена успешно!"