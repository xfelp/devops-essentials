# Configuración de Terraform y proveedores
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor de Google Cloud
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Habilitar APIs necesarias (si el proyecto es nuevo)
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "artifactregistry.googleapis.com", 
    "run.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  
  project = var.project_id
  service = each.key
  
  # No deshabilitar el servicio al destruir (evita problemas)
  disable_on_destroy = false
}

# Crear Artifact Registry para almacenar imágenes Docker
resource "google_artifact_registry_repository" "docker_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "apps"  # Coincide con REPO_NAME en Jenkinsfile
  description   = "Docker repository para aplicaciones"
  format        = "DOCKER"
  
  depends_on = [google_project_service.required_apis]
}

# Service Account dedicada para la VM de Jenkins
resource "google_service_account" "jenkins_sa" {
  account_id   = "${var.name_prefix}-sa"
  display_name = "Service Account para Jenkins"
  description  = "SA con permisos para desplegar en Cloud Run y usar Artifact Registry"
}

# Permisos para la Service Account de Jenkins
resource "google_project_iam_member" "jenkins_permissions" {
  for_each = toset([
    "roles/run.admin",                      # Administrar Cloud Run
    "roles/artifactregistry.writer",       # Escribir en Artifact Registry
    "roles/artifactregistry.reader",       # Leer de Artifact Registry  
    "roles/iam.serviceAccountUser",        # Usar service accounts
    "roles/cloudbuild.builds.builder",    # Construir imágenes
    "roles/storage.admin",                 # Acceso a Cloud Storage (logs, artifacts)
    "roles/logging.logWriter",             # Escribir logs
    "roles/monitoring.metricWriter"        # Escribir métricas
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# Regla de firewall para acceder a Jenkins (puerto 8080)
resource "google_compute_firewall" "jenkins_access" {
  name    = "${var.name_prefix}-jenkins-access"
  network = "default"
  
  # Permitir conexiones entrantes al puerto 8080 y SSH
  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]  # Jenkins y SSH
  }
  
  # Aplicar solo a VMs con el tag "jenkins"
  target_tags = ["jenkins"]
  
  # Permitir desde cualquier IP (CUIDADO: solo para desarrollo)
  # En producción, restringir a IPs específicas
  source_ranges = ["0.0.0.0/0"]
}

# VM para Jenkins (creada directamente sin módulo)
resource "google_compute_instance" "jenkins_vm" {
  name         = "${var.name_prefix}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  
  # Tags para aplicar reglas de firewall
  tags = ["jenkins", "ssh"]
  
  # Configuración del disco de arranque
  boot_disk {
    initialize_params {
      image = var.boot_image           # Ubuntu 22.04 LTS
      size  = var.boot_disk_gb         # Tamaño en GB
      type  = "pd-balanced"            # Tipo de disco (balance precio/rendimiento)
    }
  }
  
  # Configuración de red
  network_interface {
    network = "default"
    
    # Asignar IP pública
    access_config {
      // IP pública efímera
    }
  }
  
  # Metadatos de la instancia
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = <<-EOT
      #!/bin/bash
      set -euxo pipefail
      
      # Actualizar sistema
      apt-get update -y
      apt-get upgrade -y
      
      # Instalar Docker
      echo "=== Instalando Docker ==="
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      
      # Crear usuario jenkins y añadirlo al grupo docker
      useradd -m -s /bin/bash jenkins || true
      usermod -aG docker jenkins
      
      # Instalar Java 17 (requerido por Jenkins)
      echo "=== Instalando Java 17 ==="
      apt-get install -y openjdk-17-jdk
      
      # Instalar Jenkins
      echo "=== Instalando Jenkins ==="
      curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
      echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
      apt-get update -y
      apt-get install -y jenkins
      
      # Instalar Google Cloud SDK
      echo "=== Instalando Google Cloud SDK ==="
      apt-get install -y apt-transport-https ca-certificates gnupg
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
      apt-get update -y
      apt-get install -y google-cloud-cli
      
      # Configurar Jenkins
      echo "=== Configurando Jenkins ==="
      # Añadir jenkins al grupo docker (por si no se hizo antes)
      usermod -aG docker jenkins
      
      # Iniciar y habilitar Jenkins
      systemctl enable jenkins
      systemctl start jenkins
      
      # Instalar herramientas adicionales
      apt-get install -y git curl wget unzip tree
      
      # Crear script para mostrar información útil
      cat > /home/jenkins/info.sh << 'EOF'
#!/bin/bash
echo "=== Información del servidor Jenkins ==="
echo "URL de Jenkins: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google"):8080"
echo "Contraseña inicial de Jenkins:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
EOF
      chmod +x /home/jenkins/info.sh
      chown jenkins:jenkins /home/jenkins/info.sh
      
      echo "=== Jenkins instalado correctamente ==="
      echo "La instalación puede tomar unos minutos en completarse..."
      echo "Una vez listo, Jenkins estará disponible en el puerto 8080"
    EOT
  }
  
  # Service Account con permisos específicos
  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]  # Acceso completo a GCP
  }
  
  # Etiquetas para organización
  labels = {
    env     = var.env
    owner   = var.owner
    purpose = "jenkins-ci-cd"
  }
  
  depends_on = [
    google_project_service.required_apis,
    google_service_account.jenkins_sa,
    google_project_iam_member.jenkins_permissions
  ]
}
