variable "domain" {
  type = string
}

variable "folder_id" {
  type = string
}

locals {
  dns_zone_id = yandex_dns_zone.zone.id
}


# --- бэкенд, опубликованный на приватном бакете YaCloud ---

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
}

# --- публичный бакет для шейринга статики ---

resource "yandex_storage_bucket" "open-bucket" {
  bucket    = "${terraform.workspace}.${var.domain}"
  folder_id = var.folder_id

  # публичный доступ на чтение статики
  anonymous_access_flags {
    read        = true
    list        = true
    config_read = false
  }

  # страничка, опубликованная в бакете, помещенная на http
  website {
    index_document = "index.html"
  }

  https {
    certificate_id = data.yandex_cm_certificate.cert_id.id
  }

  depends_on = [data.yandex_cm_certificate.cert_id]
}


# --- Загрузка главной страницы в публичный бакет ---
 
resource "yandex_storage_object" "index-page" {
  bucket  = yandex_storage_bucket.open-bucket.id
  key     = "index.html"
  source  = "index.html"
}


# --- Создание DNS зон и ресурсных записей ---

resource "yandex_dns_zone" "zone" {
  name   = "domain-zone"
  zone   = "${var.domain}."
  public = true
}


# --- DNS CNAME запись, поддомен с именем workspace ---

resource "yandex_dns_recordset" "cname" {
  zone_id = yandex_dns_zone.zone.id
  name    = "@"
  type    = "CNAME"
  ttl     = 600
  data    = ["${terraform.workspace}.${var.domain}.website.yandexcloud.net"]
}


# --- выпуск Let's Encrypt сертификата ---

resource "yandex_cm_certificate" "cert" {
  name    = "cert"
  domains = ["${var.domain}"]

  managed {
    challenge_type = "DNS_CNAME"
  }  
}


# --- DNS запись подтверждения владения доменом, сертификат Let's Encrypt ---

resource "yandex_dns_recordset" "cert" {
  count   = length(yandex_cm_certificate.cert.challenges)
  zone_id = local.dns_zone_id
  name    = yandex_cm_certificate.cert.challenges[count.index].dns_name
  type    = yandex_cm_certificate.cert.challenges[count.index].dns_type
  data    = [yandex_cm_certificate.cert.challenges[count.index].dns_value]
  ttl     = 600
}


# --- актуальная инфа об id сертификата напрямую с провайдера ---

data "yandex_cm_certificate" "cert_id" {
  depends_on     = [yandex_dns_recordset.cert]
  certificate_id = yandex_cm_certificate.cert.id
}


# --- Провайдер YaCloud ---

provider "yandex" {
  zone = "ru-central1-a"
}
