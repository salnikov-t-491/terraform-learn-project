variable "domain" {
  type = string
}

variable "folder_id" {
  type = string
}

locals {
  dns_zones = [yandex_dns_zone.zone1.id, yandex_dns_zone.zone2.id]
}


terraform {

  # коннектор к YaCloud API

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"


  # state файл проекта в отдельном приватном бакете

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "terraform-project"
    region = "ru-central1"
    key    = "week1.tfstate"

    # костыль для работающего подключения
    skip_region_validation = true
    skip_credentials_validation = true
    skip_requesting_account_id = true
    skip_s3_checksum = true
  }
  

  # публичный бакет для шейринга статики

  resource "yandex_storage_bucket" "open-bucket" {
    bucket    = var.domain
    folder_id = var.folder_id

    # публичный доступ на чтение статики
    anonymous_access_flags {
        read        = true
        list        = true
        config_read = false
    }

    # страничка, опубликованная в бакете
    website {
        index_document = "index.html"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-a"
}
