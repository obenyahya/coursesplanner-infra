project_id      = "coursesplanner-staging-509419"
region          = "europe-west9"
environment     = "staging"
folder_id       = "204081832980"
billing_account = "011C2B-EE7E18-0633E4"

# k3s est déjà installé sur la VM : le nœud garde son nom actuel (hostname de la VM)
k3s_node_name = "k3s-stg"

# SSL « Full » côté Cloudflare : origine joignable en HTTPS seulement
expose_http_via_cloudflare  = false
expose_https_via_cloudflare = true
