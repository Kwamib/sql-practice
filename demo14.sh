#!/usr/bin/env bash
# Lesson 14 demo: Redis as a key-value store, and JSON documents in Postgres.
cd "$(dirname "$0")"
run() { echo "\$ $*"; eval "$@" 2>&1; echo; }
r() { docker exec -i larkspur-redis redis-cli "$@"; }
pg() { docker exec -i larkspur psql -U postgres -d larkspur "$@"; }

echo "===== 0. start Redis"
run 'docker run -d --name larkspur-redis redis:7-alpine > /dev/null'
until docker exec larkspur-redis redis-cli ping >/dev/null 2>&1; do sleep 1; done
run 'r PING'
run 'r INFO server | grep -E "^redis_version"'

echo "===== 1. keys and values"
run 'r SET town:1:name Ashford'
run 'r GET town:1:name'
run 'r GET town:99:name'
run 'r SET town:1:name "Ashford City"'
run 'r GET town:1:name'
run 'r EXISTS town:1:name town:99:name'
run 'r DEL town:1:name'
run 'r GET town:1:name'

echo "===== 2. a cache, with an expiry"
run 'pg -tA -c "SELECT json_agg(t ORDER BY id) FROM (SELECT id, name, kind, population FROM towns) t" | r -x SET cache:towns:all'
run 'r EXPIRE cache:towns:all 5'
run 'r STRLEN cache:towns:all'
run 'r GET cache:towns:all | cut -c1-120'
run 'r TTL cache:towns:all'
run 'sleep 6'
run 'r TTL cache:towns:all'
run 'r GET cache:towns:all'

echo "===== 3. counters, and a simple rate limit"
run 'r INCR visits:ashford'
run 'r INCR visits:ashford'
run 'r INCRBY visits:ashford 10'
run 'r GET visits:ashford'
run 'for i in $(seq 1 12); do n=$(r INCR rl:demo-key:minute); [ "$n" -eq 1 ] && r EXPIRE rl:demo-key:minute 60 >/dev/null; if [ "$n" -le 10 ]; then echo "request $i: allowed ($n of 10)"; else echo "request $i: refused, 429 ($n of 10)"; fi; done'
run 'r TTL rl:demo-key:minute'

echo "===== 4. a sliding window, with a sorted set"
run 'now=$(date +%s); for s in 130 70 45 20 5; do r ZADD rl:sliding $((now - s)) "req-$((now - s))" > /dev/null; done; r ZCARD rl:sliding; r ZCOUNT rl:sliding $((now - 60)) +inf; r ZREMRANGEBYSCORE rl:sliding 0 $((now - 120)); r ZCARD rl:sliding'

echo "===== 5. a hash: several fields under one key"
run 'r HSET town:1 name Ashford kind city population 48210'
run 'r HGETALL town:1'
run 'r HINCRBY town:1 population 150'
run 'r HGET town:1 population'
run 'r TYPE town:1'
run 'r TYPE visits:ashford'
run 'r TYPE rl:sliding'

echo "===== 6. what a key-value store can't do"
run 'r HSET town:3 name "Brennan Falls" kind city population 21544'
run 'r HSET town:12 name Linden kind town population 9734'
run 'r KEYS "town:*"'
run 'for k in $(r KEYS "town:*"); do p=$(r HGET "$k" population); [ "${p:-0}" -gt 20000 ] && echo "$k $(r HGET "$k" name) $p"; done'
run 'pg -c "SELECT id, name, population FROM towns WHERE population > 20000 ORDER BY id;"'

echo "===== 7. after a restart"
run 'r SET survives:restart yes'
run 'docker restart larkspur-redis'
until docker exec larkspur-redis redis-cli ping >/dev/null 2>&1; do sleep 1; done
run 'r GET survives:restart'
run 'r DBSIZE'

echo "===== 8. documents, inside Postgres: jsonb"
pg -q <<'SQL'
CREATE TABLE town_profiles (town_id integer PRIMARY KEY REFERENCES towns (id), profile jsonb NOT NULL);
INSERT INTO town_profiles VALUES
 (1, '{"motto": "Built on the river", "twin_towns": ["Ashby", "Fordwich"], "services": {"library": true, "pool": true}}'),
 (3, '{"motto": "Where the falls begin", "services": {"library": true, "pool": false}, "festival": {"name": "Falls Fest", "month": "June"}}'),
 (6, '{"services": {"library": false}, "elevation_ft": 2210}'),
 (12, '{"twin_towns": ["Lindau"], "services": {"libary": true}}');
SQL
run 'pg -c "SELECT town_id, profile->>'"'"'motto'"'"' AS motto, profile->'"'"'services'"'"'->>'"'"'library'"'"' AS library FROM town_profiles ORDER BY town_id;"'
run 'pg -c "SELECT t.name FROM town_profiles p JOIN towns t ON t.id = p.town_id WHERE p.profile @> '"'"'{\"services\": {\"library\": true}}'"'"' ORDER BY t.name;"'
run 'pg -c "SELECT t.name, p.profile->'"'"'festival'"'"'->>'"'"'name'"'"' AS festival FROM town_profiles p JOIN towns t ON t.id = p.town_id WHERE p.profile ? '"'"'festival'"'"';"'
run 'pg -c "SELECT town_id, jsonb_object_keys(profile->'"'"'services'"'"') AS service_key FROM town_profiles ORDER BY town_id;"'
run 'pg -c "CREATE INDEX town_profiles_gin ON town_profiles USING gin (profile);"'
run 'pg -c "\d town_profiles"'

echo "===== cleanup"
run 'pg -c "DROP TABLE town_profiles;"'
run 'docker rm -f -v larkspur-redis'
