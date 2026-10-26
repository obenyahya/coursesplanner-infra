project_id = "coursesplanner-infra"
region     = "europe-west9"

registry_readers = [
  # VM k3s de chaque environnement : doit pouvoir tirer les images pour les déployer
  "serviceAccount:k3s-dev@coursesplanner-dev-509419.iam.gserviceaccount.com",
  "serviceAccount:k3s-stg@coursesplanner-staging-509419.iam.gserviceaccount.com",
  "serviceAccount:k3s-prod@coursesplanner-prod.iam.gserviceaccount.com",
]
