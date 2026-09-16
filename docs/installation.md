# Installation et premier démarrage

Le dépôt public contient les installateurs, pas le logiciel compilé. Obtenez un
artefact Friday auprès du canal autorisé, accompagné de son SHA-256.

```powershell
D:\Friday\installer\Install-Friday.ps1 `
  -PackagePath C:\chemin\friday.zip `
  -ExpectedArchiveSha256 <empreinte-attendue>
```

L’installateur vérifie le manifeste et chaque fichier, installe la release dans
`runtime\releases`, bascule `runtime\active.json`, puis contrôle `/api/health`.
En cas d’échec, il restaure automatiquement la release précédente.

Une installation neuve écoute seulement sur `http://127.0.0.1:8443`. Ouvrez
cette adresse sur le PC, créez le propriétaire, puis suivez le
[guide réseau](reseau-et-pwa.md) avant d’utiliser un téléphone.

Pour terminer l’installation Windows :

```powershell
D:\Friday\installer\Register-FridayTask.ps1
D:\Friday\installer\Install-FridayShortcuts.ps1
```

L’installation ne compile rien et ne requiert aucun dépôt de sources.
