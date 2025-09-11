# 🚀 DevOps Challenge - FastAPI + Jenkins + Cloud Run

## 📋 Resumen del Proyecto
Pipeline completo de CI/CD que despliega automáticamente una aplicación FastAPI en Google Cloud Run usando Jenkins.

### 🏗️ Arquitectura
```
Developer → GitHub → Jenkins (VM) → Artifact Registry → Cloud Run
    ↓           ↓         ↓              ↓              ↓
  git push   webhook   build image   store image   deploy app
```

---

## 🛠️ Preparación Inicial

### 1. Instalar Herramientas Locales (Ubuntu)
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas esenciales
sudo apt install -y git curl wget unzip build-essential

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Instalar Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Instalar Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Configurar GCP
```bash
# Autenticarse con GCP
gcloud auth login

# Establecer proyecto
gcloud config set project nombre-de-tu-proyecto

# Habilitar APIs necesarias
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable iam.googleapis.com
```

---

## 🔒 Configuración Segura (SIN terraform.tfvars)

### ⚠️ IMPORTANTE: Protección de Información Sensible

Este proyecto está configurado para **NO usar terraform.tfvars** y evitar cualquier leak de información sensible.

### 1. Configurar .gitignore (Protección de Archivos)
```bash
# Clonar repositorio
git clone https://github.com/zagalx90/devops-fundamentals.git
cd devops-fundamentals

# Crear/actualizar .gitignore para proteger archivos sensibles
cat >> .gitignore << 'EOF'

# Archivos de Python
__pycache__/
*.py[cod]

# Credenciales y configuración sensible
*.json
*.key
*.pem
terraform.tfvars
terraform.tfvars.backup

# Estado de Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Jenkins
jenkins-sa-key.json
jenkins-github-key*
EOF
```

### 2. Crear Template de Configuración (Para Desarrollo Local)
```bash
# Crear archivo de ejemplo (sin información sensible)
cat > terraform/terraform.tfvars.example << 'EOF'
# terraform.tfvars.example
# 
# 📋 INSTRUCCIONES PARA DESARROLLO LOCAL:
# 1. Copia: cp terraform.tfvars.example terraform.tfvars  
# 2. Completa con valores reales
# 3. NUNCA subas terraform.tfvars al repositorio
#
# 🔒 En Jenkins se usan variables de entorno TF_VAR_*

project_id   = "tu-proyecto-gcp-aqui"
region       = "us-east1"
zone         = "us-east1-b"
name_prefix  = "jenkins"
machine_type = "e2-medium"
boot_disk_gb = 30
env          = "dev"
owner        = "tu-nombre"
EOF
```

---

## 🔧 Despliegue de Infraestructura

### Método 1: Usando Variables de Entorno (Recomendado)
```bash
cd terraform

# Configurar variables de entorno (Terraform las lee automáticamente)
export TF_VAR_project_id="nombre-de-tu-proyecto"
export TF_VAR_env="dev" 
export TF_VAR_owner="tu-nombre"

# Inicializar Terraform
terraform init

# Verificar configuración
terraform validate

# Ver plan de ejecución (mostrará las variables)
terraform plan

# Aplicar cambios (crear infraestructura)
terraform apply
# Escribir 'yes' cuando se solicite confirmación
```

### Método 2: Para Desarrollo Local (Opcional)
```bash
# Solo si quieres usar archivo local (no subir al repo)
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Editar con valores reales
nano terraform.tfvars

# Ejecutar terraform
terraform init
terraform plan
terraform apply
```

### 3. Guardar Información de la Infraestructura
```bash
# Ver la guía paso a paso que aparecerá automáticamente
terraform output step_by_step_guide

# Guardar outputs importantes
terraform output jenkins_url
terraform output service_account_email
```

---

## 🔑 Configuración de Credenciales

### 1. Crear Service Account Key para Jenkins
```bash
# Obtener email de la service account (desde output de terraform)
SA_EMAIL=$(terraform output -raw service_account_email)

# Crear clave JSON para Jenkins
gcloud iam service-accounts keys create jenkins-sa-key.json \
  --iam-account="$SA_EMAIL"

echo "✅ jenkins-sa-key.json creado - GUARDALO EN LUGAR SEGURO"
echo "⚠️  Este archivo NO se sube al repositorio (protegido por .gitignore)"
```

### 2. Crear SSH Key para GitHub
```bash
# Generar par de claves SSH para Jenkins
ssh-keygen -t rsa -b 4096 -C "jenkins@nombre-de-tu-proyecto" -f jenkins-github-key -N ""

echo "✅ Claves SSH creadas:"
echo "  - jenkins-github-key (clave privada - para Jenkins)"
echo "  - jenkins-github-key.pub (clave pública - para GitHub)"

# Mostrar clave pública para agregar a GitHub
echo ""
echo "🔑 CLAVE PÚBLICA para GitHub (copia todo el contenido):"
cat jenkins-github-key.pub
```

### 3. Agregar SSH Key a GitHub
1. Ve a GitHub → Settings → SSH and GPG keys
2. Click "New SSH key"
3. Title: `Jenkins DevOps Server`
4. Key: pega el contenido de `jenkins-github-key.pub`
5. Click "Add SSH key"

---

## ⚙️ Configuración de Jenkins

### 1. Acceder a Jenkins
```bash
# Obtener URL y contraseña inicial
terraform output jenkins_url
terraform output initial_jenkins_password_command

# Ejecutar comando para obtener contraseña
terraform output -raw initial_jenkins_password_command | bash
```

### 2. Configuración Inicial de Jenkins
1. **Abrir Jenkins** en el navegador
2. **Ingresar contraseña inicial**
3. **Instalar plugins sugeridos**
4. **Crear usuario administrador**:
   - Username: `admin`
   - Password: `admin123` (cambiar en producción)
   - Full name: `Jenkins Admin`
   - Email: tu-email@example.com

### 3. Configurar Variables de Entorno en Jenkins (CRÍTICO)

#### 🔒 Configuración de Variables Seguras:
1. **Ir a**: Manage Jenkins → Configure System
2. **Buscar "Global properties"**
3. **Environment variables** ☑️ (marcar checkbox)
4. **Agregar variables**:
   - `TF_VAR_project_id` = `nombre-de-tu-proyecto`
   - `TF_VAR_env` = `dev`
   - `TF_VAR_owner` = `jenkins-pipeline`
5. **Save**

### 4. Configurar Credenciales en Jenkins

#### A. Credencial para GCP Service Account
1. **Ir a**: Manage Jenkins → Manage Credentials → System → Global credentials
2. **Add Credentials** → **Secret file**
   - **ID**: `gcp-sa-key`
   - **Description**: `GCP Service Account Key`
   - **File**: subir `jenkins-sa-key.json`
   - Click **OK**

#### B. Credencial para Project ID
1. **Add Credentials** → **Secret text**
   - **ID**: `gcp-project-id`
   - **Description**: `GCP Project ID`
   - **Secret**: `nombre-de-tu-proyecto`
   - Click **OK**

#### C. Credencial SSH para GitHub
1. **Add Credentials** → **SSH Username with private key**
   - **ID**: `github-ssh-key`
   - **Description**: `GitHub SSH Key`
   - **Username**: `git`
   - **Private Key**: seleccionar "Enter directly"
   - Pegar contenido del archivo `jenkins-github-key` (sin extensión)
   - Click **OK**

### 5. Instalar Plugins Necesarios
1. **Ir a**: Manage Jenkins → Manage Plugins → Available
2. **Buscar e instalar**:
   - `AnsiColor` (para colores en consola - usado en Jenkinsfile)
   - `Google Cloud Build`
   - `Docker Pipeline`
   - `Pipeline: Stage View`
   - `Blue Ocean` (interfaz moderna)
3. **Restart Jenkins**: Manage Jenkins → Restart Safely

---

## 🔄 Configuración del Pipeline

### 1. Crear Job en Jenkins
1. **New Item**
2. **Nombre**: `fastapi-cloud-run-pipeline`
3. **Tipo**: Pipeline
4. Click **OK**

### 2. Configurar Pipeline
1. **En "Pipeline" section**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `git@github.com:xfelp/devops-essentials.git`
   - **Credentials**: seleccionar `github-ssh-key`
   - **Branch**: `*/main`
   - **Script Path**: `api/Jenkinsfile`

2. **En "Build Triggers"**:
   - ☑️ GitHub hook trigger for GITScm polling

3. **Click "Save"**

### 3. Configurar Webhook en GitHub
1. **Ir al repositorio** en GitHub
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://TU_JENKINS_IP:8080/github-webhook/`
   ```bash
   # Para obtener la IP de Jenkins:
   terraform output jenkins_external_ip
   ```
4. **Content type**: `application/json`
5. **Which events**: "Just the push event"
6. **Active**: ☑️
7. Click **Add webhook**

---

## 🧪 Probar el Pipeline

### 1. Ejecutar Pipeline Manualmente
1. En Jenkins, ir al job `fastapi-cloud-run-pipeline`
2. Click **"Build Now"**
3. Observar logs en tiempo real (con colores gracias a AnsiColor)

### 2. Verificar Despliegue
```bash
# Obtener URL del servicio desplegado
gcloud run services describe fastapi-demo \
  --region=us-east1 \
  --format='value(status.url)'

# Probar endpoints
SERVICE_URL=$(gcloud run services describe fastapi-demo --region=us-east1 --format='value(status.url)')
curl $SERVICE_URL/
curl $SERVICE_URL/ping
curl $SERVICE_URL/healthz
```

### 3. Probar Trigger Automático
```bash
# Hacer un cambio en el código y push
cd api/app
echo "# Updated $(date)" >> main.py
git add .
git commit -m "test: trigger pipeline automatically"
git push origin main

# El pipeline debería ejecutarse automáticamente en Jenkins
```

---

## 🔍 Troubleshooting

### Variables de Entorno
```bash
# Verificar variables en Jenkins VM
gcloud compute ssh jenkins-vm --zone=us-east1-b --command='env | grep TF_VAR'

# Si las variables no están, configurarlas en Jenkins UI
```

### Problemas Comunes

#### 1. Terraform no encuentra project_id
```bash
# Verificar variables de entorno
echo $TF_VAR_project_id

# Si está vacía, configurar:
export TF_VAR_project_id="nombre-de-tu-proyecto"

# O configurar en Jenkins UI (recomendado)
```

#### 2. Jenkins no puede acceder a GitHub
```bash
# Verificar SSH key
gcloud compute ssh jenkins-vm --zone=us-east1-b
sudo -u jenkins ssh -T git@github.com
```

#### 3. Error de permisos en GCP
```bash
# Verificar service account
gcloud projects get-iam-policy nombre-de-tu-proyecto \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:*jenkins-sa*"
```

#### 4. Artifact Registry no funciona
```bash
# Verificar repositorio
gcloud artifacts repositories describe apps --location=us-east1

# Verificar permisos
gcloud artifacts repositories get-iam-policy apps --location=us-east1
```

### Comandos Útiles de Debugging
```bash
# Ver logs de Jenkins
gcloud compute ssh jenkins-vm --zone=us-east1-b \
  --command='sudo journalctl -u jenkins -f'

# Estado de servicios
gcloud compute ssh jenkins-vm --zone=us-east1-b \
  --command='sudo systemctl status jenkins docker'

# Verificar Terraform en Jenkins
gcloud compute ssh jenkins-vm --zone=us-east1-b \
  --command='sudo -u jenkins terraform version'

# Ver imágenes Docker construidas
gcloud compute ssh jenkins-vm --zone=us-east1-b \
  --command='sudo docker images'

# Ver servicios Cloud Run
gcloud run services list --region=us-east1

# Ver logs de Cloud Run
gcloud run services logs tail fastapi-demo --region=us-east1
```

---

## 🔒 Características de Seguridad Implementadas

### ✅ Información Protegida
- **terraform.tfvars** nunca se crea ni se sube al repo
- **Credenciales JSON** protegidas por .gitignore
- **SSH keys** protegidas por .gitignore
- **Variables sensibles** solo en Jenkins UI

### ✅ Variables de Entorno
- Terraform lee automáticamente `TF_VAR_*`
- Jenkins gestiona variables de forma segura
- Separación entre desarrollo local y CI/CD

### ✅ Mejores Prácticas
- Service account con permisos mínimos necesarios
- Firewall configurado solo para puertos necesarios
- Backend de Terraform local (para desarrollo)
- Rotación de credenciales recomendada

---

## 🧹 Limpieza de Recursos

```bash
# Eliminar servicio de Cloud Run
gcloud run services delete fastapi-demo --region=us-east1 --quiet

# Eliminar imágenes de Artifact Registry
gcloud artifacts docker images delete \
  us-east1-docker.pkg.dev/nombre-de-tu-proyecto/apps/fastapi-demo --quiet

# Eliminar infraestructura con Terraform
cd terraform
# Configurar variables si es necesario
export TF_VAR_project_id="nombre-de-tu-proyecto"
terraform destroy
# Escribir 'yes' cuando se solicite

# Limpiar archivos locales (solo si existen)
rm -f jenkins-sa-key.json
rm -f jenkins-github-key*
rm -f terraform/terraform.tfvars
```

---

## 📚 Diferencias Clave con Configuración Tradicional

### ❌ Método Tradicional (NO Recomendado)
```bash
# Crea archivo con información sensible
cat > terraform.tfvars << EOF
project_id = "nombre-de-tu-proyecto"  # ⚠️ Información sensible
EOF

# ❌ Riesgo: terraform.tfvars puede subirse accidentalmente al repo
```

### ✅ Método Seguro (Implementado)
```bash
# Variables de entorno (no van al repo)
export TF_VAR_project_id="nombre-de-tu-proyecto"

# ✅ Terraform funciona igual, pero sin archivos sensibles
terraform plan
```

---

## 📈 Próximas Mejoras

### Seguridad Avanzada
- [ ] Backend remoto en GCS para estado de Terraform
- [ ] Terraform Workspaces para múltiples entornos
- [ ] Vault para gestión de secretos
- [ ] Renovación automática de credenciales

### Pipeline Avanzado
- [ ] Tests automatizados (pytest)
- [ ] Múltiples entornos (dev/staging/prod)
- [ ] Rollback automático si fallan tests
- [ ] Notificaciones Slack/Email

### Monitoreo
- [ ] Prometheus + Grafana
- [ ] Alertas proactivas
- [ ] Métricas de aplicación
- [ ] Logs centralizados

---

## 🆘 Soporte

Si encuentras problemas:

1. **Revisa variables de entorno** en Jenkins
2. **Verifica .gitignore** protege archivos sensibles
3. **Confirma APIs habilitadas** en GCP
4. **Usa comandos de debugging** proporcionados
5. **Consulta logs específicos** de cada servicio

**¡Felicitaciones por implementar un pipeline DevOps seguro y profesional!** 🎉

---

## 🎯 Resumen de Comandos Esenciales

```bash
# 1. Configuración inicial
export TF_VAR_project_id="nombre-de-tu-proyecto"
cd terraform && terraform init && terraform apply

# 2. Crear credenciales
gcloud iam service-accounts keys create jenkins-sa-key.json --iam-account=$(terraform output -raw service_account_email)
ssh-keygen -t rsa -b 4096 -C "jenkins" -f jenkins-github-key -N ""

# 3. Obtener info de Jenkins
terraform output jenkins_url
terraform output -raw initial_jenkins_password_command | bash

# 4. Verificar despliegue
gcloud run services describe fastapi-demo --region=us-east1 --format='value(status.url)'

# 5. Limpiar (cuando termines)
terraform destroy
```

**¡Tu pipeline está listo y es completamente seguro!** 🚀🔒
