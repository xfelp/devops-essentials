# Tu archivo está bien, solo voy a ajustar la región para que coincida con el Jenkinsfile

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región por defecto"
  type        = string
  default     = "us-east1"  # Cambiado para coincidir con tu Jenkinsfile
}

variable "zone" {
  description = "Zona por defecto"  
  type        = string
  default     = "us-east1-b"  # Cambiado para coincidir con la región
}

variable "name_prefix" {
  description = "Prefijo para nombrar recursos"
  type        = string
  default     = "jenkins"  # Cambiado para ser más descriptivo
}

variable "machine_type" {
  description = "Tipo de máquina (e2-micro es gratuito dentro de límites)"
  type        = string
  default     = "e2-medium"  # e2-medium para Jenkins (e2-micro puede ser lento)
}

variable "boot_image" {
  description = "Imagen del sistema operativo"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_gb" {
  description = "Tamaño del disco en GB"
  type        = number
  default     = 30  # Aumentado para Jenkins y Docker
}

variable "env" {
  description = "Entorno (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Propietario del recurso"
  type        = string
  default     = "devops-team"
}
