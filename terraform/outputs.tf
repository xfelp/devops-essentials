# Información útil después de crear la infraestructura

output "instance_name" {
  description = "Nombre de la instancia de Jenkins"
  value       = google_compute_instance.jenkins_vm.name
}

output "instance_self_link" {
  description = "Self link de la instancia"
  value       = google_compute_instance.jenkins_vm.self_link
}

output "jenkins_external_ip" {
  description = "IP pública para acceder a Jenkins"
  value       = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}

output "jenkins_url" {
  description = "URL para acceder a Jenkins"
  value       = "http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080"
}

output "ssh_command" {
  description = "Comando para conectarse por SSH"
  value       = "gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --project ${var.project_id}"
}

output "artifact_registry_url" {
  description = "URL del registry de Docker"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "initial_jenkins_password_command" {
  description = "Comando para obtener la contraseña inicial de Jenkins"
  value       = "gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --project ${var.project_id} --command='sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

output "service_account_email" {
  description = "Email de la service account creada para Jenkins"
  value       = google_service_account.jenkins_sa.email
}

output "next_steps" {
  description = "Siguientes pasos después de la creación"
  value = <<-EOT
  
🚀 PRÓXIMOS PASOS:

1. Esperar que Jenkins termine de instalarse (5-10 minutos)
   
2. Acceder a Jenkins:
   ${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080
   
3. Obtener contraseña inicial:
   gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --project ${var.project_id} --command='sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
   
4. Crear credenciales en Jenkins:
   - Crear service account key: 
     gcloud iam service-accounts keys create jenkins-sa-key.json --iam-account=${google_service_account.jenkins_sa.email}
   - Subir jenkins-sa-key.json como 'gcp-sa-key' en Jenkins
   - Añadir project_id '${var.project_id}' como 'gcp-project-id' en Jenkins

5. Crear pipeline con el repositorio Git

EOT
}
