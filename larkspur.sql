-- Larkspur County: a made-up county for practising SQL.
-- Every town, person, phone number and website here is invented.
-- Load it with:  psql -U postgres -f /practice/larkspur.sql
-- Running it again starts the database fresh.

DROP DATABASE IF EXISTS larkspur;
CREATE DATABASE larkspur;
\connect larkspur

CREATE TABLE towns (
    id          integer PRIMARY KEY,
    name        text,
    kind        text,
    population  integer,
    founded     integer,
    website     text,
    phone       text
);

CREATE TABLE leaders (
    id       integer PRIMARY KEY,
    town_id  integer REFERENCES towns (id),
    name     text,
    role     text,
    started  date,
    ended    date
);

CREATE TABLE meetings (
    id           integer PRIMARY KEY,
    town_id      integer REFERENCES towns (id),
    held_on      date,
    body         text,
    attendance   integer,
    minutes_url  text
);

INSERT INTO towns (id, name, kind, population, founded, website, phone) VALUES
    (1,  'Ashford',       'city',    48210, 1851, 'https://www.ashfordcity.gov',      '(555) 010-1100'),
    (2,  'Ashford',       'village',  1904, 1888, NULL,                               '(555) 010-2200'),
    (3,  'Brennan Falls', 'city',    21544, 1867, 'https://www.brennanfalls.gov',     '(555) 010-3300'),
    (4,  'Cedar Hollow',  'town',     8390, 1902, 'http://cedarhollow.larkspur.us',   '(555) 010-4400'),
    (5,  'Dunmore',       'town',     NULL, 1879, 'https://www.dunmoretown.gov',      '(555) 010-4400'),
    (6,  'Elk Ridge',     'village',  2710, 1911, 'https://www.elkridge.gov',         '(555) 010-6600'),
    (7,  'Fairview',      'city',    33102, 1859, 'https://www.fairview.gov',         '555-010-7700'),
    (8,  'Glen Oak',      'town',    11876, 1884, 'https://www.glenoak.gov',          '(555) 010-8800'),
    (9,  'Harlow',        'town',     6045, 1896, 'https://www.harlowtown.gov',       '(555) 010-9900'),
    (10, 'Juniper',       'village',  1288, 1920, NULL,                               NULL),
    (11, 'Kestrel Bay',   'city',    27450, 1871, 'https://www.kestrelbay.gov',       '(555) 011-1100'),
    (12, 'Linden',        'town',     9734, 1890, 'https://lindentown.com',           '(555) 011-2200');

INSERT INTO leaders (id, town_id, name, role, started, ended) VALUES
    (1,  1,  'Maria Okafor',   'mayor',         '2018-01-01', '2022-01-01'),
    (2,  1,  'Thomas Reyes',   'mayor',         '2022-01-01', NULL),
    (3,  1,  'Priya Shah',     'administrator', '2019-06-01', NULL),
    (4,  2,  'Thomas Reyes',   'mayor',         '2020-05-01', NULL),
    (5,  3,  'Dana Ruiz',      'mayor',         '2021-01-01', NULL),
    (6,  3,  'Leo Park',       'administrator', '2017-03-15', NULL),
    (7,  4,  'Ellen Marsh',    'mayor',         '2015-01-01', '2023-01-01'),
    (8,  4,  'Sam Whitfield ', 'mayor',         '2023-01-01', NULL),
    (9,  5,  'Grace Lin',      'mayor',         '2019-01-01', NULL),
    (10, 5,  'Owen Price',     'mayor',         '2023-01-01', NULL),
    (11, 6,  'Ivy Chen',       'mayor',         '2022-01-01', NULL),
    (12, 7,  'Marcus Bell',    'mayor',         '2020-01-01', NULL),
    (13, 7,  'Nora Quinn',     'administrator', '2021-08-01', NULL),
    (14, 8,  'Hal Brooks',     'mayor',         '2017-01-01', '2024-12-31'),
    (15, 9,  'Rosa Diaz',      'mayor',         '2021-01-01', NULL),
    (16, 11, 'Ben Adler',      'mayor',         '2019-01-01', '2023-01-01'),
    (17, 11, 'Ana Torres',     'mayor',         '2023-01-01', NULL),
    (18, 11, 'Ken Moss',       'administrator', '2016-01-01', NULL),
    (19, 12, 'Joy Hart',       'mayor',         '2022-01-01', NULL),
    (20, 12, 'Carl Webb',      'mayor',         '2024-01-01', '2023-06-30');

INSERT INTO meetings (id, town_id, held_on, body, attendance, minutes_url) VALUES
    (1,  1,  '2026-01-12', 'council',  41, 'https://www.ashfordcity.gov/minutes/2026-01-12'),
    (2,  1,  '2026-02-09', 'council',  38, 'https://www.ashfordcity.gov/minutes/2026-02-09'),
    (3,  1,  '2026-02-23', 'planning', 12, NULL),
    (4,  1,  '2026-03-09', 'council',  55, 'https://www.ashfordcity.gov/minutes/2026-03-09'),
    (5,  2,  '2026-01-20', 'council',   9, NULL),
    (6,  2,  '2026-03-17', 'council',  11, NULL),
    (7,  3,  '2026-01-06', 'council',  27, 'https://www.brennanfalls.gov/minutes/0106'),
    (8,  3,  '2026-02-03', 'council',  31, 'https://www.brennanfalls.gov/minutes/0203'),
    (9,  3,  '2026-02-17', 'planning',  8, 'https://www.brennanfalls.gov/minutes/0217'),
    (10, 3,  '2026-03-03', 'council',  24, 'https://www.brennanfalls.gov/minutes/0303'),
    (11, 4,  '2026-01-14', 'council',  14, NULL),
    (12, 4,  '2026-02-11', 'council', NULL, NULL),
    (13, 5,  '2026-01-08', 'council',  19, 'https://www.dunmoretown.gov/minutes/jan'),
    (14, 5,  '2026-02-12', 'council',  22, 'https://www.dunmoretown.gov/minutes/feb'),
    (15, 5,  '2026-02-26', 'planning',  6, NULL),
    (16, 6,  '2026-01-21', 'council',   7, 'https://www.elkridge.gov/minutes/2026-01'),
    (17, 7,  '2026-01-13', 'council',  36, 'https://www.fairview.gov/minutes/2026-01-13'),
    (18, 7,  '2026-01-27', 'planning', 15, 'https://www.fairview.gov/minutes/2026-01-27'),
    (19, 7,  '2026-02-10', 'council',  44, 'https://www.fairview.gov/minutes/2026-02-10'),
    (20, 7,  '2026-03-10', 'council',  39, 'https://www.fairview.gov/minutes/2026-03-10'),
    (21, 8,  '2026-01-15', 'council',  18, 'https://www.glenoak.gov/minutes/0115'),
    (22, 8,  '2026-02-19', 'council',  16, 'https://www.glenoak.gov/minutes/0219'),
    (23, 9,  '2026-02-04', 'council',  13, NULL),
    (24, 11, '2026-01-07', 'council',  29, 'https://www.kestrelbay.gov/minutes/2026-01-07'),
    (25, 11, '2026-02-04', 'council',  33, 'https://www.kestrelbay.gov/minutes/2026-02-04'),
    (26, 11, '2026-02-18', 'planning', 10, 'https://www.kestrelbay.gov/minutes/2026-02-18'),
    (27, 11, '2026-03-04', 'council',  30, 'https://www.kestrelbay.gov/minutes/2026-03-04'),
    (28, 12, '2026-01-26', 'council',  12, 'https://lindentown.com/minutes/jan'),
    (29, 12, '2026-02-23', 'council',  15, 'https://lindentown.com/minutes/feb'),
    (30, 12, '2026-03-23', 'planning',  5, NULL);
