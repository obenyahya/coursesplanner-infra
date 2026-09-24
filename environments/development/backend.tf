terraform {
  backend "gcs" {
    bucket = "coursesplanner-infra-tfstate"
    prefix = "environments/development"
  }
}