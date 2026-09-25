#!/bin/bash
# Exécuté en root par l'agent Google à CHAQUE démarrage de la VM.
set -euo pipefail

# On n'installe k3s qu'une seule fois
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -s - server \
    --write-kubeconfig-mode 600
fi
