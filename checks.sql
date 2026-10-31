-- Larkspur County data checks.
-- Each part of the view returns the rows that break one rule,
-- so the right answer to every check is no rows.
-- severity 'error': a rule that must always hold. 'warn': for a person to look at.
-- Load it with:  psql -U postgres -d larkspur -f /practice/checks.sql

CREATE OR REPLACE VIEW problems AS

-- one current mayor per town
SELECT 'error' AS severity, 'two_current_mayors' AS check_name,
       'town ' || town_id AS ref, count(*) || ' current mayors' AS detail
FROM leaders
WHERE role = 'mayor' AND ended IS NULL
GROUP BY town_id HAVING count(*) > 1

UNION ALL
-- a term can't end before it starts
SELECT 'error', 'term_order', 'leader ' || id, name || ': ' || started || ' to ' || ended
FROM leaders
WHERE ended < started

UNION ALL
-- two mayors of the same town at the same time, past or present
SELECT 'error', 'overlapping_mayors', 'leaders ' || a.id || ' and ' || b.id,
       btrim(a.name) || ' and ' || btrim(b.name) || ', town ' || a.town_id
FROM leaders a
JOIN leaders b ON b.town_id = a.town_id AND b.id > a.id
WHERE a.role = 'mayor' AND b.role = 'mayor'
  AND a.started < coalesce(b.ended, 'infinity')
  AND b.started < coalesce(a.ended, 'infinity')

UNION ALL
-- no spaces at either end of a name
SELECT 'error', 'name_spaces', 'leader ' || id, '"' || name || '"'
FROM leaders
WHERE name <> btrim(name)

UNION ALL
-- every phone in the same format
SELECT 'error', 'phone_format', 'town ' || id, name || ': ' || phone
FROM towns
WHERE phone !~ '^\(\d{3}\) \d{3}-\d{4}$'

UNION ALL
-- no two town halls share a phone (missing phones aren't shared)
SELECT 'error', 'shared_phone', 'towns ' || string_agg(id::text, ', ' ORDER BY id), phone
FROM towns
WHERE phone IS NOT NULL
GROUP BY phone HAVING count(*) > 1

UNION ALL
-- a town with no current mayor: maybe true, worth a look
SELECT 'warn', 'no_current_mayor', 'town ' || t.id, t.name
FROM towns t
WHERE NOT EXISTS (SELECT 1 FROM leaders l
                  WHERE l.town_id = t.id AND l.role = 'mayor' AND l.ended IS NULL)

UNION ALL
-- websites should be https; missing ones are listed too
SELECT 'warn', 'website_not_https', 'town ' || id, name || ': ' || coalesce(website, '(none)')
FROM towns
WHERE website IS NULL OR website NOT LIKE 'https://%'

UNION ALL
-- population unknown
SELECT 'warn', 'population_missing', 'town ' || id, name
FROM towns
WHERE population IS NULL;
