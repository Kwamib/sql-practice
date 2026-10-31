#!/usr/bin/env bash
# Run the Larkspur County checks against the larkspur container.
# Prints every problem found. Exits 1 if any error-level check finds a row.
set -euo pipefail

psql_() { docker exec larkspur psql -U postgres -d larkspur -v ON_ERROR_STOP=1 "$@"; }

psql_ -q -f /practice/checks.sql
psql_ -c "SELECT severity, check_name, ref, detail FROM problems ORDER BY severity, check_name, ref;"

errors=$(psql_ -tA -c "SELECT count(*) FROM problems WHERE severity = 'error';")
warnings=$(psql_ -tA -c "SELECT count(*) FROM problems WHERE severity = 'warn';")

if [ "$errors" -gt 0 ]; then
  echo "FAIL: $errors error(s), $warnings warning(s)"
  exit 1
fi
echo "PASS: 0 errors, $warnings warning(s)"
