# 1. Создание сервисного аккаунта
resource "yandex_iam_service_account" "sa" {
  name        = var.service_account
  description = "Сервисный аккаунт для управления S3 и ресурсами"
}

# 2. Назначение роли editor
resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# 3. Назначение роли storage.editor
resource "yandex_resourcemanager_folder_iam_member" "sa_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# 4. Создание Authorization Key (JSON)
resource "yandex_iam_service_account_key" "sa_auth_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Ключ авторизации в формате JSON"
}

resource "local_file" "save_auth_key" {
  content = jsonencode({
    id                 = yandex_iam_service_account_key.sa_auth_key.id
    service_account_id = yandex_iam_service_account_key.sa_auth_key.service_account_id
    created_at         = yandex_iam_service_account_key.sa_auth_key.created_at
    key_algorithm      = yandex_iam_service_account_key.sa_auth_key.key_algorithm
    public_key         = yandex_iam_service_account_key.sa_auth_key.public_key
    private_key        = yandex_iam_service_account_key.sa_auth_key.private_key
  })
  filename = "../authorized_key.json"
}

# 5. Создание Static Access Key (для S3)
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Статический ключ доступа для S3"
}

resource "local_file" "save_static_key" {
  content  = <<EOT
export BUCKET_NAME=${var.bucket_name}
export AWS_ACCESS_KEY_ID=${yandex_iam_service_account_static_access_key.sa_static_key.access_key}
export AWS_SECRET_ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa_static_key.secret_key}
EOT
  filename = "../s3.env"
}

# 6. Создание S3 Bucket
resource "yandex_storage_bucket" "test_bucket" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  depends_on = [yandex_resourcemanager_folder_iam_member.sa_storage_editor]
}