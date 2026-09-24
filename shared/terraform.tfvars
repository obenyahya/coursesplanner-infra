project_id = "coursesplanner-infra"
region     = "europe-west9"

registry_readers = [
  # VM k3s de dev : doit pouvoir tirer les images pour les déployer
  "serviceAccount:k3s-dev@coursesplanner-dev-509419.iam.gserviceaccount.com",
]
