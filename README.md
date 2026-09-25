# Infrastructure CoursesPlanner

## GitOps avec Flux

Terraform crée les VM k3s ; ce qui tourne **dans** les clusters est décrit dans `k8s/`
et synchronisé en continu par [Flux](https://fluxcd.io), installé dans chaque cluster.

| Dossier | Rôle |
|---|---|
| `k8s/platform/` | Socle commun à tous les clusters : namespace `coursesplanner`, CronJob qui rafraîchit le Secret de pull Artifact Registry (sans clé JSON). |
| `k8s/apps/` | Applications (Deployments, Services…). Déployées après `platform`. |
| `k8s/clusters/<env>/` | Point d'entrée d'un cluster : les Kustomizations Flux qui disent quels dossiers synchroniser, dans quel ordre. |
| `k8s/clusters/<env>/flux-system/` | Généré par `flux bootstrap` (composants de Flux et lien vers ce dépôt). Ne pas modifier à la main. |

### Déployer

Un `git push` sur la branche principale suffit : Flux relit le dépôt toutes les minutes
et applique les différences. Un fichier supprimé du dépôt est supprimé du cluster (`prune`).

Pour forcer une synchronisation immédiate :

```bash
flux reconcile kustomization apps --with-source
```

Ne pas modifier les objets gérés avec `kubectl edit` : Flux rétablirait la version du dépôt.
