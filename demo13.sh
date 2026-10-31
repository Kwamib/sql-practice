#!/usr/bin/env bash
# Lesson 13 demo: back up Larkspur County, restore it, lose a table, get it back.
cd "$(dirname "$0")"
run() { echo "\$ $*"; eval "$@" 2>&1; echo; }
ready() { until docker exec "$1" pg_isready -q -U postgres -h 127.0.0.1 2>/dev/null; do sleep 1; done; }
mkdir -p backups

echo "===== 0. what we're backing up"
run 'docker exec larkspur psql -U postgres -d larkspur -c "SELECT (SELECT count(*) FROM towns) AS towns, (SELECT count(*) FROM leaders) AS leaders, (SELECT count(*) FROM meetings) AS meetings;"'

echo "===== 1. a plain SQL dump"
run 'docker exec larkspur pg_dump -U postgres -d larkspur > backups/larkspur.sql'
run 'ls -lh backups/larkspur.sql | awk "{print \$5, \$9}"'
run 'grep -n -E "^(CREATE TABLE|COPY|ALTER TABLE ONLY|CREATE VIEW|CREATE INDEX)" backups/larkspur.sql'
run 'sed -n "/^COPY public.towns/,/^\\\\\\./p" backups/larkspur.sql | head -5'

echo "===== 2. a custom-format dump"
run 'docker exec larkspur pg_dump -U postgres -Fc -d larkspur > backups/larkspur.dump'
run 'ls -lh backups/ | awk "NR>1 {print \$5, \$9}"'
run 'docker exec larkspur pg_restore -l /practice/backups/larkspur.dump | grep -v "^;"'

echo "===== 3. restore it somewhere new, and prove it"
run 'docker exec larkspur createdb -U postgres larkspur_restored'
run 'time docker exec larkspur pg_restore -U postgres -d larkspur_restored /practice/backups/larkspur.dump'
run 'docker exec larkspur psql -U postgres -d larkspur_restored -c "SELECT (SELECT count(*) FROM towns) AS towns, (SELECT count(*) FROM leaders) AS leaders, (SELECT count(*) FROM meetings) AS meetings;"'
run 'docker exec larkspur psql -U postgres -d larkspur_restored -c "SELECT severity, count(*) FROM problems GROUP BY severity ORDER BY severity;"'

echo "===== 4. disaster: a table is dropped, and committed"
run 'docker exec larkspur psql -U postgres -d larkspur -c "DROP TABLE meetings;"'
run 'docker exec larkspur psql -U postgres -d larkspur -c "SELECT count(*) FROM meetings;"'

echo "===== 5a. restore one table with pg_restore -t"
run 'docker exec larkspur pg_restore -U postgres -d larkspur -t meetings /practice/backups/larkspur.dump'
run 'docker exec larkspur psql -U postgres -d larkspur -c "SELECT count(*) FROM meetings;"'
run 'docker exec larkspur psql -U postgres -d larkspur -c "\d meetings"'

echo "===== 5b. again, with its keys"
run 'docker exec larkspur psql -U postgres -d larkspur -c "DROP TABLE meetings;"'
run 'docker exec larkspur sh -c "pg_dump -U postgres -d larkspur_restored -t meetings | psql -q -U postgres -d larkspur"'
run 'docker exec larkspur psql -U postgres -d larkspur -c "\d meetings"'
run 'docker exec larkspur psql -U postgres -d larkspur -c "SELECT count(*) FROM meetings;"'

echo "===== 6. what pg_dump leaves out: roles"
run 'docker exec larkspur psql -U postgres -c "CREATE ROLE backup_test_role LOGIN;"'
run 'grep -c backup_test_role backups/larkspur.sql'
run 'docker exec larkspur pg_dump -U postgres -d larkspur | grep -c backup_test_role'
run 'docker exec larkspur pg_dumpall -U postgres --globals-only | grep -E "^CREATE ROLE"'
run 'docker exec larkspur psql -U postgres -c "DROP ROLE backup_test_role;"'

echo "===== 7. moving to a newer Postgres"
run 'docker run -d --name larkspur17 -e POSTGRES_PASSWORD=practice -v "$PWD":/practice postgres:17 > /dev/null'
ready larkspur17
run 'docker exec larkspur17 createdb -U postgres larkspur'
run 'docker exec larkspur17 pg_restore -U postgres -d larkspur /practice/backups/larkspur.dump'
run 'docker exec larkspur17 psql -U postgres -d larkspur -c "SHOW server_version;"'
run 'docker exec larkspur17 psql -U postgres -d larkspur -c "SELECT (SELECT count(*) FROM towns) AS towns, (SELECT count(*) FROM leaders) AS leaders, (SELECT count(*) FROM meetings) AS meetings;"'
run 'docker rm -f -v larkspur17'

echo "===== 8. a backup you can trust"
run 'shasum -a 256 backups/larkspur.dump'
run 'docker exec larkspur pg_restore -l /practice/backups/larkspur.dump | head -12'

echo "===== cleanup"
run 'docker exec larkspur dropdb -U postgres larkspur_restored'
