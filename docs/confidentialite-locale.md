# Données et confidentialité locale

Friday conserve la base, les comptes, les secrets, les certificats, les modèles,
les journaux et les sauvegardes dans le répertoire de données configuré. Ils ne
sont présents ni dans ce dépôt ni dans les artefacts distribués.

Le fonctionnement local n’exige aucun service cloud. Ollama reste sur le PC.
Les recherches Web et la future vérification manuelle des mises à jour sont les
seules connexions Internet prévues par le produit actuel.

Protégez le volume, les ACL, les sauvegardes et la clé privée HTTPS. Une simple
copie d’une base SQLite active ne constitue pas une sauvegarde cohérente.
