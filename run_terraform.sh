#!/bin/bash

# Проверка наличия файла .env
if [ ! -f .env ]; then
  echo [translate:"Файл .env не найден!"]
  exit 1
fi

# Загрузка переменных окружения из .env
set -o allexport
source .env
set +o allexport

# Инициализация terraform, инициализация backend и плагинов
terraform init

# Функция создания workspace, если его нет
create_workspace_if_not_exists() {
  local workspace_name=$1
  if terraform workspace list | grep -qw "$workspace_name"; then
    echo [translate:"Workspace"] "'$workspace_name'" [translate:"уже существует"]
  else
    echo [translate:"Создаём workspace"] "'$workspace_name'"
    terraform workspace new "$workspace_name"
  fi
}

# Создание трёх workspace при их отсутствии
create_workspace_if_not_exists qa
create_workspace_if_not_exists staging
create_workspace_if_not_exists production

# Переключение на workspace по умолчанию (qa)
terraform workspace select qa

# Применение конфигурации terraform
terraform apply -var-file="domain.tfvars" -auto-approve 
