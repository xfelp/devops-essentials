variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región por defecto (debe coincidir con REGION en Jenkinsfile)"
  type        = string
  default     = "us-east1"  # Coincide con REGION en tu Jenkinsfile
}

variable "zone" {
  description = "Zona por defecto dentro de la región"  
  type        = string
  default     = "us-east1-b"  # Zona disponible en us-east1
}

variable "name_prefix" {
  description = "Prefijo para nombrar recursos"
  type        = string
  default     = "jenkins"  # Más descriptivo para Jenkins
}

variable "machine_type" {
  description = "Tipo de máquina VM (e2-medium recomendado para Jenkins con Docker)"
  type        = string
  default     = "e2-medium"  # Suficiente para Jenkins + Docker + builds
}

variable "boot_image" {
  description = "Imagen del sistema operativo para la VM"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"  # Ubuntu 22.04 LTS estable
}

variable "boot_disk_gb" {
  description = "Tamaño del disco de arranque en GB (mínimo 30GB para Jenkins + Docker)"
  type        = number
  default     = 30  # Suficiente para Jenkins, Docker images, y builds
}

variable "env" {
  description = "Etiqueta de entorno (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Etiqueta de propietario del recurso"
  type        = string
  default     = "devops-team"
}
