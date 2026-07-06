#!/usr/bin/env bash
# Démo end-to-end GRACE THD : import de l'échantillon public ANCT puis
# exécution complète du pipeline dbt (contrôles + transformations).
# À la fin, la base PostGIS reste en ligne (service `db`) pour un branchement QGIS.
set -euo pipefail

cd /app

echo "==> Attente de PostgreSQL (db:5432)…"
until pg_isready -h db -p 5432 -U grace >/dev/null 2>&1; do
  sleep 1
done
echo "==> PostgreSQL prêt."

echo "==> Import des données GRACE THD (input_data/) → schéma gracethd_source…"
python scripts/import_grace_pg.py input_data docker

# packages.yml est vide aujourd'hui ; sans effet, mais robuste si des deps sont ajoutées.
echo "==> dbt deps…"
dbt deps || true

# À partir d'ici, on ne bloque pas sur les erreurs de modèles : la philosophie GRACE THD
# est une intégration NON BLOQUANTE / analyse progressive. Avec un échantillon partiel
# (jeu ANCT v3.0 vs modèle v3.0.1), quelques modèles peuvent échouer sans arrêter la démo.
set +e

echo "==> dbt seed (paramètres de contrôle + listes de valeurs)…"
dbt seed

echo "==> dbt run — points de contrôle…"
dbt run --select tag:grace_control

# Le rapport consolide les contrôles via graph.nodes (pas de ref() → pas d'arête de
# dépendance dbt) : il doit donc être exécuté APRÈS, dans une invocation séparée.
echo "==> dbt run — rapports consolidés…"
dbt run --select tag:grace_rapport

echo "==> dbt run — transformations (base + élémentaires + thématiques)…"
dbt run --select tag:grace_base tag:grace_elem tag:grace_thematiques

echo ""
echo "==> Résumé du rapport de contrôles :"
PGPASSWORD=grace psql -h db -U grace -d grace -t -c \
  "SELECT type_controle, count(*) AS nb FROM grace_controles.rapport_controles GROUP BY 1 ORDER BY 2 DESC;" \
  || echo "(rapport_controles indisponible)"

echo ""
echo "=========================================================="
echo " Pipeline terminé. La base PostGIS reste disponible :"
echo "   host=localhost  port=5433  db=grace  user=grace  pass=grace"
echo " Schémas : gracethd_source, grace, grace_controles, grace_transformations"
echo "=========================================================="
