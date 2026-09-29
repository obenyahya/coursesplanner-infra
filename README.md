# Infrastructure CoursesPlanner

## GitOps avec Flux

Terraform crée les VM k3s. Au démarrage, le script `modules/k3s/startup.sh.tftpl` installe
k3s, puis dépose dans `/var/lib/rancher/k3s/server/manifests/` les fichiers que k3s
applique tout seul (auto-déploiement) :

| Fichier sur la VM | Contenu | Source |
|---|---|---|
| `flux-install.yaml` | Composants de Flux | release officielle `fluxcd/flux2`, version `flux_version` |
| `platform.yaml` | Namespace `coursesplanner`, External Secrets (HelmChart k3s) et `ClusterSecretStore` `gcp-secret-manager`, PersistentVolumes hostPath `manual` (postgres, redis, keycloak), GitRepository + Kustomization Flux | métadonnée `k3s-manifests`, rendue par Terraform depuis `modules/k3s/manifests/*.yaml.tftpl` |
| `flux-app-deploy-key.yaml` (600) | Secret `flux-system/coursesplanner-app-deploy-key` (`identity`, `known_hosts`) | secret `flux-deploy-key` de Secret Manager |

Flux surveille **uniquement `k8s/`** du dépôt `coursesplanner-docker` et applique
`k8s/overlays/<env>` :

| Environnement | VM | Branche suivie | Overlay |
|---|---|---|---|
| dev | `k3s-dev` | `develop` | `k8s/overlays/dev` |
| staging | `k3s-stg` | `staging` | `k8s/overlays/staging` |
| prod | `k3s-prod` | `main` | `k8s/overlays/prod` |

Aucun commit n'est fait dans un dépôt Git et aucun jeton GitHub n'est nécessaire.
Aucun secret ne passe par Terraform ni par les métadonnées de la VM : la clé SSH
(deploy key **en lecture seule**) est ajoutée à la main dans Secret Manager, et seul
le compte de service de la VM peut la lire.

Les versions sont épinglées : `flux_version` dans `environments/<env>/k3s.tf`,
`external_secrets_version` dans `modules/k3s/variables.tf`.

### Installer Flux sur un environnement (exemple : dev)

```bash
# 1. Clé SSH propre à l'environnement (sans passphrase : Flux l'utilise sans intervention)
ssh-keygen -t ed25519 -N "" -C flux-dev -f flux-dev

# 2. GitHub → coursesplanner-docker → Settings → Deploy keys → Add deploy key :
#    titre "flux-dev", contenu de flux-dev.pub, "Allow write access" DÉCOCHÉ.

# 3. Infra : secret vide, droit de lecture de la VM, métadonnées de la VM
cd environments/development
terraform init
terraform plan     # attendu : VM modifiée sur place, secret + IAM créés, 0 destruction
terraform apply

# 4. Clé privée dans Secret Manager, puis suppression des fichiers locaux
gcloud secrets versions add flux-deploy-key --data-file=flux-dev \
  --project=coursesplanner-dev-509419
shred -u flux-dev && rm -f flux-dev.pub

# 5. Relancer le script sans redémarrer la VM
gcloud compute ssh k3s-dev --zone=europe-west9-a --project=coursesplanner-dev-509419 \
  --tunnel-through-iap -- sudo google_metadata_script_runner startup
```

Vérifications, sur la VM (`gcloud compute ssh … --tunnel-through-iap`) :

```bash
sudo k3s kubectl get pods -n flux-system
sudo k3s kubectl get gitrepositories,kustomizations -n flux-system
sudo k3s kubectl get pods -n coursesplanner
# En cas de problème
sudo journalctl -u google-startup-scripts --no-pager | tail -50
sudo k3s kubectl describe gitrepository coursesplanner-docker -n flux-system
```

Dans les premières minutes, k3s peut signaler des erreurs sur le `ClusterSecretStore`
ou sur les objets Flux : leurs CRD ne sont pas encore installées. Il réessaie tout seul.

Staging et prod : mêmes étapes avec `flux-staging` / `flux-prod`, le dossier
`environments/staging` / `environments/production`, les projets
`coursesplanner-staging-509419` / `coursesplanner-prod` et les VM `k3s-stg` / `k3s-prod`.

### Rotation de la clé

Générer une nouvelle clé (étapes 1, 2, 4), relancer le script (étape 5), puis retirer
l'ancienne deploy key sur GitHub et désactiver l'ancienne version :
`gcloud secrets versions disable <n> --secret=flux-deploy-key --project=…`.

### Déployer

Un commit dans `k8s/` de `coursesplanner-docker` (la CI y met à jour les tags d'images)
suffit : Flux relit le dépôt toutes les minutes et applique l'overlay toutes les 5 minutes.
Un objet supprimé du dépôt est supprimé du cluster (`prune`).

Synchronisation immédiate, sur la VM :

```bash
sudo k3s kubectl annotate --overwrite -n flux-system gitrepository/coursesplanner-docker \
  reconcile.fluxcd.io/requestedAt="$(date +%s)"
```

Ne pas modifier les objets gérés avec `kubectl edit` : Flux ou k3s rétabliraient la
version de référence.
