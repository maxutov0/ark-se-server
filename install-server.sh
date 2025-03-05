#!/bin/bash

# Загрузка переменных из .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден. Создайте его и настройте переменные."
  exit 1
fi

# Проверка наличия файла конфигурации
if [ ! -f GameUserSettings.ini ]; then
  echo "❌ Файл GameUserSettings.ini не найден. Создайте его и настройте конфигурацию."
  exit 1
fi

# Проверка наличия файла сервиса
if [ ! -f ark-server.service ]; then
  echo "❌ Файл ark-server.service не найден. Создайте его и настройте сервис."
  exit 1
fi

# Функция для логирования
log_step() {
  if [ $? -eq 0 ]; then
    echo "✅ $1"
  else
    echo "❌ $1"
    exit 1
  fi
}

# Создание пользователя ark
echo "🔄 Создание пользователя ark..."
if id "ark" &>/dev/null; then
  echo "✅ Пользователь ark уже существует."
else
  sudo useradd -m -s /bin/bash ark
  log_step "Пользователь ark создан"
fi

# Переключение на пользователя ark
echo "🔄 Переключение на пользователя ark..."
sudo -u ark bash <<EOF

# Проверка установленных пакетов
echo "🔄 Проверка установленных пакетов..."

check_package() {
  if ! command -v "\$1" &> /dev/null; then
    echo "❌ Пакет \$1 не установлен."
    return 1
  else
    echo "✅ Пакет \$1 установлен."
    return 0
  fi
}

# Список необходимых пакетов
required_packages=("curl" "tar" "screen" "lib32gcc1" "lib32stdc++6" "libc6-i386" "libcurl4-gnutls-dev:i386")

# Проверка каждого пакета
for pkg in "\${required_packages[@]}"; do
  check_package "\$pkg"
  if [ \$? -ne 0 ]; then
    echo "🔄 Установка недостающих пакетов..."
    sudo apt-get install -y "\${required_packages[@]}"
    log_step "Недостающие пакеты установлены"
    break
  fi
done

# Обновление пакетов
echo "🔄 Обновление пакетов..."
sudo apt-get update -y
log_step "Пакеты обновлены"

# Создание директории для сервера
echo "🔄 Создание директории для сервера..."
mkdir -p "\$ARK_SERVER_DIR"
log_step "Директория создана"

# Переход в директорию сервера
cd "\$ARK_SERVER_DIR"
log_step "Переход в директорию сервера"

# Загрузка SteamCMD
echo "🔄 Загрузка SteamCMD..."
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o steamcmd.tar.gz
log_step "SteamCMD загружен"

# Распаковка SteamCMD
echo "🔄 Распаковка SteamCMD..."
tar -xvzf steamcmd.tar.gz
log_step "SteamCMD распакован"

# Установка ARK: Survival Evolved Dedicated Server
echo "🔄 Установка ARK: Survival Evolved Dedicated Server..."
./steamcmd.sh +force_install_dir "\$ARK_SERVER_DIR" +login anonymous +app_update 376030 validate +quit
log_step "ARK: Survival Evolved Dedicated Server установлен"

# Настройка конфигурации сервера
echo "🔄 Настройка конфигурации сервера..."
mkdir -p "\$ARK_SERVER_DIR/ShooterGame/Saved/Config/LinuxServer"
envsubst < /tmp/GameUserSettings.ini > "\$ARK_SERVER_DIR/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
log_step "Конфигурация сервера настроена"

EOF

# Копирование файла конфигурации во временную директорию
sudo cp GameUserSettings.ini /tmp/GameUserSettings.ini
sudo chown ark:ark /tmp/GameUserSettings.ini

# Копирование файла сервиса в systemd
echo "🔄 Копирование файла сервиса в systemd..."
ARK_SERVICE_PATH="/etc/systemd/system/ark-server.service"
sudo cp ark-server.service "$ARK_SERVICE_PATH"
sudo chmod 644 "$ARK_SERVICE_PATH"
sudo systemctl daemon-reload
log_step