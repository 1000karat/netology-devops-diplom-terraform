variable "token" {
  type        = string
  description = "IAM-токен или OAuth-токен для доступа к Yandex Cloud"
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "service_account" {
  description = "Globally unique bucket name"
  type        = string
  default     = "netology-service_account"
}

variable "bucket_name" {
  description = "Globally unique bucket name"
  type        = string
  default     = "storage-bucket-netology-diplom-test"
}