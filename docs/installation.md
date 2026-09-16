# Installer Friday sous Windows

Statut documentaire : actif.

Prérequis : Windows 11 x64 et un artefact Friday vérifié. L'installation par
défaut utilise `D:\Friday` pour le programme et `D:\FridayData` pour les
données. Elle ne compile rien et ne dépend pas du dépôt TypeScript privé.

Depuis PowerShell :

```powershell
D:\Friday\installer\Install-Friday.ps1 -PackagePath C:\chemin\friday.zip
```

Le script vérifie chaque SHA-256 du manifeste, installe dans un nouveau dossier,
conserve la version précédente et teste `/api/health`. En cas d'échec, il remet
automatiquement la release précédente. Utiliser `Register-FridayTask.ps1` pour
le démarrage à l'ouverture de session et `Install-FridayShortcuts.ps1` pour les
raccourcis.

Ollama, ses modèles, Chrome et l'environnement Python/OpenCV du Robot sont
facultatifs et restent externes à l'artefact.
