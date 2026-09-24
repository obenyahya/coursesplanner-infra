#!/bin/bash
# Exécuté en root par l'agent Google à CHAQUE démarrage de la VM.
set -euo pipefail

# On n'installe k3s qu'une seule fois
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -s - server \
    --write-kubeconfig-mode 600
fi

# À chaque exécution : copie des manifests de plateforme (clé de metadata gérée par
# Terraform) dans le dossier que k3s surveille et applique automatiquement.
MANIFEST_DIR=/var/lib/rancher/k3s/server/manifests
MANIFEST_URL=http://metadata.google.internal/computeMetadata/v1/instance/attributes/k3s-platform-manifests

umask 077 # fichiers créés lisibles par root seulement
mkdir -p "$MANIFEST_DIR"

# Fichier temporaire hors motif *.yaml, puis renommage atomique :
# k3s ne lit jamais un fichier à moitié écrit.
TMP="$MANIFEST_DIR/.platform.yaml.tmp"
if curl -sSf -H "Metadata-Flavor: Google" "$MANIFEST_URL" -o "$TMP"; then
  chmod 600 "$TMP"
  chown root:root "$TMP"
  mv -f "$TMP" "$MANIFEST_DIR/platform.yaml"
  echo "k3s-platform-manifests écrit dans $MANIFEST_DIR/platform.yaml"
else
  # Clé absente : on ne touche pas au fichier existant plutôt que de tout supprimer
  rm -f "$TMP"
  echo "k3s-platform-manifests introuvable dans les metadata, rien n'est modifié" >&2
fi
