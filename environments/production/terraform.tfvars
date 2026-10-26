project_id      = "coursesplanner-prod"
region          = "europe-west9"
environment     = "production"
folder_id       = "675616086897"
billing_account = "011C2B-EE7E18-0633E4"

# SSL « Full » côté Cloudflare : origine joignable en HTTPS seulement
expose_http_via_cloudflare  = false
expose_https_via_cloudflare = true
