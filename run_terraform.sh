#!/bin/bash

# Скрипт для загрузки переменных из .env и запуска terraform

# Проверка, что файл .env существует
if [ ! -f .env ]; then
  echo "Файл .env не найден!"
  exit 1
fi

# Загружаем переменные окружения из .env
set -o allexport
source .env
set +o allexport

# Инициализация terraform (инициализирует backend и плагины)
terraform init

# Применение конфигурации terraform
terraform apply -auto-approve
