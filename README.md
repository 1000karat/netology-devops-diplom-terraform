###Итоговый проект курса «DevOps-инженер с нуля»

####Тема итоговой работы - Базовая DevOps‑инфраструктура в Yandex.Cloud
---
####Цели:
- развернуть базовую облачную инфраструктуру и подготовить виртуальную машину к работе приложения;
- развернуть контейнерное веб‑приложение в Yandex.Cloud, опубликовать Docker‑образ в реестре и настроить автоматическое обновление приложения при изменении кода;
- продемонстрировать понимание ключевых практик DevOps: инфраструктура как код, контейнеризация и базовый CI/CD‑pipeline;
- оформить проект в виде понятной документации, чтобы другой специалист смог воспроизвести ваше решение по инструкции.
---
####Используемое окружение:
OS: Ubuntu 26.04 LTS (Resolute Raccoon)

Перед началом выполнения установлено:
- [git](https://git-scm.com/install/linux);
- [docker](https://docs.docker.com/engine/install/ubuntu/);
- [terraform](https://developer.hashicorp.com/terraform/install);
- [ansible](https://docs.ansible.com/projects/ansible/latest/installation_guide/installation_distros.html);
- сгенерирован ~/.ssh/id_ed25519.pub;
- [yc cli](https://yandex.cloud/ru/docs/cli/operations/install-cli);
- в Yandex Cloud Console созданы `cloud_id` и `folder_id`.
---
####Этапы выполнения:
##### 1. Подготовка облачной инфраструктуры
Создание облачной инфраструктуры разделено на 2 проекта:  
1.1. Проект в каталоге `01.ya-cloud-sa-s3` создаёт сервисный аккаунт, `authorized_key.json`, файл `s3.env` с ключами доступа к бакету и сам бакет. Для запуска проекта `01.ya-cloud-sa-s3` необходимо создать файл `terraform.tfvars` и заполнить своими значениями, пример содержимого:
```
cloud_id        = "b1g***"
folder_id       = "b1g***"
zone            = "ru-central1-a"
service_account = "netology-sa-var"
bucket_name     = "storage-bucket-netology-diplom-var"
```  
**Выполняемые команды:**  
Получаем IAM-токен с помощью YC:
```bash
yc iam create-token
```
Инициплизируем проект и запускаем строительство инфраструктуры:
```bash
terraform init
terraform plan
terraform apply
```
**Итогом выполнения команд** является создание сервисного аккаунта и бакета в Yandex Cloud.  

1.2. Проект в каталоге `02.ya-cloud-infrastructure` через созданный файл `authorized_key.json` создаёт инфраструктуру из VPC, подсети и виртуальной машины. Для запуска проекта `02.ya-cloud-infrastructure` необходимо создать файл `terraform.tfvars` и заполнить своими значениями, пример содержимого:
```
cloud_id                 = "b1g"
folder_id                = "b1g***"
zone                     = "ru-central1-a"
service_account_key_file = "../authorized_key.json"
ssh_public_key_path      = "~/.ssh/id_ed25519.pub"
ssh_user                 = "ubuntu"
```
**Выполняемые команды:**  
Загружаем переменные из файла s3.env в текущую Bash-сессию
```bash
source ../s3.env
```
Инициплизируем проект и запускаем строительство инфраструктуры:
```bash
terraform init -backend-config="bucket=$BUCKET_NAME"
terraform plan
terraform apply
```
**Итогом выполнения команд** являептся создание VPC, подсети и VM в Yandex Cloud. Файла `inventory.ini` для дальнейшего запуска Ansible.

---

##### 2. Установка Docker на виртуальной машине
Для установки Docker используется Ansible‑playbook из репозитория [netology-devops-diplom-ansible](link).
**Выполняемые команды:**
```bash
ansible-playbook -i ../../netology-devops-diplom-ansible/inventory.ini ../../netology-devops-diplom-ansible/install-docker.yml
```
**Итогом выполнения команды** является установленный Docker.

---

##### 3. Подготовка тестового приложения
Тестовое приложение находится в репозитори [netology-devops-diplom-app](link)
[Dockerfile](link)
[compose.yaml](link)
Для локальной сборки образа и его запуска **выполняются команды:**
```bash
docker build -t 14b93194de1d/netology-nginx-app:1.0.0 .
docker run -d --rm -p 80:80 --name netology-nginx-app 14b93194de1d/netology-nginx-app:1.0.0
```
**Итогом выполнения команд** является локального nginx.

---

##### 4. Публикация образа в реестре
Для публикации приложения был выбран https://hub.docker.com
**Выполняемые команды:**
```bash
docker login
docker push 14b93194de1d/netology-nginx-app:1.0.0
```
**Итогом выполнения команд** является загрузка приложения в репозиторий по ссылке [hub.docker.com](https://hub.docker.com/r/14b93194de1d/netology-nginx-app)

---

##### 5. Настройка CI/CD
5.1. Подготовка SSH ключей для GitHub Actions и VM Сгенерировать ключ для GitHub Actions:
```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions
```
Добавить публичный ключ на VM:
```bash
ssh-copy-id -i ~/.ssh/github_actions.pub ubuntu@ip_address
```

5.2. Настройка `Secrets` в github.com  
В репозитории переходим по пути Settings -> Secrets and variables -> Actions -> New repository secret
Создаём секреты:
| Secret             | Value                                                                                                                                                                                                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| DOCKERHUB_USERNAME | username hub.docker.com                                                                                                                                                                                                                                                              |
| DOCKERHUB_TOKEN    | в настройка docker [профиля](https://app.docker.com/) во вкладке "Personal access tokens" нажимаем "Generate new token" и выполняем генерацию нового token с правами "Read & Write". Полученный personal access token вставляем в значение для Repository secrets "DOCKERHUB_TOKEN". |
| VM_USER            | ранее прописанное значение в файле `02.ya-cloud-infrastructure/terraform.tfvars`. По умолчанию - `ubuntu`.                                                                                                                                                                           |
| VM_HOST            | заполнить ip адрес из файла `netology-devops-diplom-ansible/inventory.ini`.|
| VM_SSH_KEY         | cat ~/.ssh/github_actions |


5.3. Настройка `Actions` в github.com  
В репозитории переходим в Actions и выюираем "Docker image Build a Docker image to deploy, run, or push to a registry" жмём "Configure".
Заполняем имя файла docker-image.yml с [содержимым](https://github.com/1000karat/netology-devops-diplom-app/blob/main/.github/workflows/docker-image.yml).

Итоговая проверка 

---

6. Удаление инфраструктуры.
Команда `terraform destroy` выполняется из каталога `02.ya-cloud-infrastructure`. 