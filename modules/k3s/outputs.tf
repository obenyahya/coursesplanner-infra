output "instance_name" {
  value = google_compute_instance.this.name
}

output "zone" {
  value = google_compute_instance.this.zone
}

output "external_ip" {
  value = google_compute_address.this.address
}
