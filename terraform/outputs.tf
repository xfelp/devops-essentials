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

output "step_by_step_guide" {
  description = "Guía paso a paso completa para configurar el pipeline"
  value = <<-EOT

🚀 GUÍA PASO A PASO - CONFIGURACIÓN COMPLETA DEL PIPELINE
═══════════════════════════════════════════════════════════════

⚠️  IMPORTANTE: Tu Jenkinsfile usa región 'us-east1' ⚠️

═══════════════════════════════════════════════════════════════
PASO 1: PREPARAR CREDENCIALES (mientras Jenkins se instala)
═══════════════════════════════════════════════════════════════

PASO 1.1: Crear Service Account Key para Jenkins
─────────────────────────────────────────────────
gcloud iam service-accounts keys create jenkins-sa-key.json --iam-account=${google_service_account.jenkins_sa.email}

PASO 1.2: Crear SSH Key para GitHub
─────────────────────────────────────
ssh-keygen -t rsa -b 4096 -C "jenkins@devops-learning-hub" -f jenkins-github-key -N ""

PASO 1.3: Mostrar clave pública para GitHub
─────────────────────────────────────────────
echo "🔑 COPIA esta clave pública y agrégala a GitHub → Settings → SSH and GPG Keys → New SSH Key:"
echo "Title: Jenkins DevOps Server"
echo "Key:"
cat jenkins-github-key.pub

═══════════════════════════════════════════════════════════════
PASO 2: VERIFICAR ARTIFACT REGISTRY
═══════════════════════════════════════════════════════════════

Verificar que el repositorio fue creado:
gcloud artifacts repositories describe apps --location=${var.region}

URL del repositorio: ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}

═══════════════════════════════════════════════════════════════
PASO 3: ACCEDER A JENKINS (esperar 5-10 minutos)
═══════════════════════════════════════════════════════════════

Jenkins URL: http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080

Obtener contraseña inicial:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --project ${var.project_id} --command='sudo cat /var/lib/jenkins/secrets/initialAdminPassword'

═══════════════════════════════════════════════════════════════
PASO 4: CONFIGURACIÓN INICIAL DE JENKINS
═══════════════════════════════════════════════════════════════

4.1: Ingresar contraseña inicial obtenida arriba
4.2: Seleccionar "Install suggested plugins"
4.3: Crear usuario administrador:
     - Username: admin
     - Password: admin123 (cambiar en producción)
     - Full name: Jenkins Admin
     - Email: tu-email@example.com
4.4: Confirmar Jenkins URL (debería estar correcto)

═══════════════════════════════════════════════════════════════
PASO 5: INSTALAR PLUGINS ADICIONALES
═══════════════════════════════════════════════════════════════

Ir a: Manage Jenkins → Manage Plugins → Available

Buscar e instalar estos plugins:
- ☑️ AnsiColor (para colores en consola - usado en tu Jenkinsfile)
- ☑️ Google Cloud Build
- ☑️ Docker Pipeline
- ☑️ Pipeline: Stage View
- ☑️ Blue Ocean (interfaz moderna)

Reiniciar Jenkins después: Manage Jenkins → Restart Safely

═══════════════════════════════════════════════════════════════
PASO 6: CONFIGURAR CREDENCIALES EN JENKINS
═══════════════════════════════════════════════════════════════

Ir a: Manage Jenkins → Manage Credentials → System → Global credentials

6.1: GCP Service Account (Secret file)
─────────────────────────────────────
- Add Credentials → Secret file
- ID: gcp-sa-key
- Description: GCP Service Account Key
- File: subir jenkins-sa-key.json
- ☑️ OK

6.2: GCP Project ID (Secret text)
─────────────────────────────────
- Add Credentials → Secret text  
- ID: gcp-project-id
- Description: GCP Project ID
- Secret: ${var.project_id}
- ☑️ OK

6.3: GitHub SSH Key (SSH Username with private key)
─────────────────────────────────────────────────
- Add Credentials → SSH Username with private key
- ID: github-ssh-key
- Description: GitHub SSH Key for Repository Access
- Username: git
- Private Key: Enter directly → pegar contenido de jenkins-github-key (sin extensión .pub)
- ☑️ OK

═══════════════════════════════════════════════════════════════
PASO 7: CREAR PIPELINE EN JENKINS
═══════════════════════════════════════════════════════════════

7.1: New Item
7.2: Nombre: fastapi-cloud-run-pipeline
7.3: Tipo: Pipeline → OK

7.4: Configurar Pipeline:
    📁 Pipeline section:
    - Definition: Pipeline script from SCM
    - SCM: Git
    - Repository URL: git@github.com:zagalx90/devops-fundamentals.git
    - Credentials: github-ssh-key
    - Branches to build: */main (o */feature/cloud-run-deployment si trabajas en esa rama)
    - Script Path: Jenkinsfile (está en la raíz según tu estructura)

    🔔 Build Triggers:
    - ☑️ GitHub hook trigger for GITScm polling

7.5: Save

═══════════════════════════════════════════════════════════════
PASO 8: CONFIGURAR WEBHOOK EN GITHUB
═══════════════════════════════════════════════════════════════

8.1: Ir al repositorio zagalx90/devops-fundamentals en GitHub
8.2: Settings → Webhooks → Add webhook
8.3: Configurar webhook:
     - Payload URL: http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080/github-webhook/
     - Content type: application/json
     - Which events would you like to trigger this webhook?: Just the push event
     - Active: ☑️
8.4: Add webhook

═══════════════════════════════════════════════════════════════
PASO 9: PROBAR EL PIPELINE
═══════════════════════════════════════════════════════════════

9.1: Prueba Manual:
     - En Jenkins, ir al job fastapi-cloud-run-pipeline
     - Click "Build Now"
     - Observar logs en tiempo real (deberían aparecer con colores)

9.2: Verificar el despliegue:
     gcloud run services describe fastapi-demo --region=us-east1 --format='value(status.url)'

9.3: Probar la aplicación:
     SERVICE_URL=$(gcloud run services describe fastapi-demo --region=us-east1 --format='value(status.url)')
     curl $SERVICE_URL/
     curl $SERVICE_URL/ping
     curl $SERVICE_URL/healthz

9.4: Prueba Automática (Push Trigger):
     - Hacer un cambio en el código
     - git add . && git commit -m "test: trigger pipeline" && git push
     - El pipeline debería ejecutarse automáticamente

═══════════════════════════════════════════════════════════════
INFORMACIÓN CLAVE DE TU CONFIGURACIÓN
═══════════════════════════════════════════════════════════════

✅ Service Account: ${google_service_account.jenkins_sa.email}
✅ Artifact Registry: ${var.region}-docker.pkg.dev/${var.project_id}/apps
✅ Región Cloud Run: us-east1 (según tu Jenkinsfile)
✅ Servicio Cloud Run: fastapi-demo
✅ Repository Docker: apps

═══════════════════════════════════════════════════════════════
TROUBLESHOOTING - COMANDOS ÚTILES
═══════════════════════════════════════════════════════════════

🔍 Ver logs de Jenkins:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --command='sudo journalctl -u jenkins -f'

🔍 Verificar Docker funciona:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --command='sudo systemctl status docker'

🔍 Verificar que jenkins user puede usar Docker:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --command='sudo -u jenkins docker ps'

🔍 Reiniciar servicios si es necesario:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --command='sudo systemctl restart jenkins'

🔍 Ver imágenes Docker construidas:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone} --command='sudo docker images'

🔍 Ver servicios Cloud Run:
gcloud run services list --region=us-east1

🔍 Ver logs de Cloud Run:
gcloud run services logs tail fastapi-demo --region=us-east1

🔍 Verificar Artifact Registry:
gcloud artifacts docker images list ${var.region}-docker.pkg.dev/${var.project_id}/apps

🔍 Probar autenticación manual en VM:
gcloud compute ssh ${google_compute_instance.jenkins_vm.name} --zone ${var.zone}
sudo -u jenkins gcloud auth list

═══════════════════════════════════════════════════════════════
¡IMPORTANTE! COINCIDENCIA DE REGIONES
═══════════════════════════════════════════════════════════════

⚠️  Tu Jenkinsfile usa REGION='us-east1'
⚠️  Este Terraform crea recursos en: ${var.region}
⚠️  Verifica que coincidan para evitar errores

Si necesitas cambiar la región en Jenkinsfile, modifica:
REGION = '${var.region}'
REGISTRY_HOST = "${var.region}-docker.pkg.dev"

═══════════════════════════════════════════════════════════════

🎉 ¡Sigue estos pasos en orden y tendrás tu pipeline funcionando perfectamente!

Los endpoints de tu FastAPI estarán disponibles en:
- /           → {"hello": "cloud run + jenkins"}
- /ping       → {"message": "pong"}  
- /healthz    → {"status": "ok"}
- /health     → {"status": "ok"}

EOT
}
