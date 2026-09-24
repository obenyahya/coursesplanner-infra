terraform {
  backend "gcs" {
    bucket = "coursesplanner-infra-tfstate"
    prefix = "shared"
  }
}
