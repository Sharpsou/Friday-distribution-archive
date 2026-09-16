# Dépannage et FAQ

| Symptôme                    | Contrôle                                                            |
| --------------------------- | ------------------------------------------------------------------- |
| Friday ne démarre pas       | Lancer `Invoke-FridayDiagnostic.ps1` et contrôler la release active |
| Le téléphone ne répond pas  | Vérifier réseau privé, origine exacte, certificat et pare-feu       |
| Une connexion reboucle      | Ne pas effacer le navigateur ; contrôler session et horloge du PC   |
| Une donnée reste en attente | Garder la PWA ouverte au retour du LAN et contrôler le Hub          |
| Chat indisponible           | Vérifier que le Hub fonctionne puis, si activé, Ollama et le modèle |
| Version ancienne affichée   | Fermer les fenêtres Friday puis accepter la mise à jour PWA         |

Une réinstallation du programme ne doit jamais remplacer directement la base
SQLite ou son secret. Conservez le message exact avant toute réparation.
