# Réseau HTTPS et PWA

L’accès depuis Android ou iPhone exige une adresse stable sur le réseau privé,
un certificat HTTPS valide pour cette adresse ou ce nom, et la confiance dans
l’autorité qui l’a émis.

Après avoir créé le certificat et sa clé hors du dépôt :

```powershell
D:\Friday\installer\Configure-FridayLan.ps1 `
  -PublicOrigin 'https://friday.maison:8443' `
  -CertificatePath 'D:\FridayData\certificates\friday-lan.pem' `
  -KeyPath 'D:\FridayData\secrets\friday-lan-key.pem'
```

Relancez Friday, vérifiez `/api/health`, puis ouvrez exactement la même origine
sur le téléphone. Chrome Android propose l’installation de la PWA ; Safari iOS
utilise « Sur l’écran d’accueil ». Une autre origine crée un stockage navigateur
distinct : synchronisez avant tout changement d’adresse.

N’ouvrez pas le port sur Internet et ne partagez jamais la clé privée du certificat.
