# Mise à jour et retour arrière

Statut documentaire : actif.

Le canal alpha ne vérifie pas automatiquement Internet. Une mise à jour est
déclenchée manuellement avec un artefact reçu séparément. L'installateur
contrôle le manifeste et les empreintes, teste le candidat, puis bascule la
release active. Si le démarrage échoue, la release précédente redevient active.

Un `git pull` ne met jamais à jour le runtime installé. Il ne protège pas les
téléchargements incomplets, les modules natifs ni le retour arrière.
