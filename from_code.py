"""SQL from code, and SQL injection: the Lesson 12 demo.

Runs against the larkspur container. Every change it makes is rolled back.
Part 7 connects as a read-only role. Create it first:
  docker exec larkspur psql -U postgres -d larkspur -c "CREATE ROLE web_reader LOGIN PASSWORD 'practice-only'; GRANT SELECT ON towns TO web_reader;"
Then run it with:
  docker run --rm --network container:larkspur -v "$PWD":/practice -w /practice \
    python:3.13-slim sh -c "pip install -q --root-user-action=ignore 'psycopg[binary]' && python from_code.py"
"""
import psycopg
from psycopg import sql
from psycopg.rows import dict_row

ADMIN = "host=localhost dbname=larkspur user=postgres password=practice"
READER = "host=localhost dbname=larkspur user=web_reader password=practice-only"


def show(title):
    print(f"\n===== {title}")


def run(conn, query, params=None):
    """Run one query, print its rows or its error. Roll back afterwards."""
    print("SQL:", query if isinstance(query, str) else query.as_string(conn))
    if params is not None:
        print("params:", params)
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            while True:
                if cur.description:
                    rows = cur.fetchall()
                    for row in rows:
                        print("  ", row)
                    print(f"   ({len(rows)} rows)")
                else:
                    print("  ", cur.statusmessage)
                if not cur.nextset():
                    break
            if "DROP" in str(query):
                cur.execute("SELECT to_regclass('meetings') AS meetings_table")
                print("   before rollback, meetings table is:", cur.fetchone()["meetings_table"])
    except psycopg.Error as e:
        print("   ERROR:", type(e).__name__, "-", str(e).splitlines()[0])
    finally:
        conn.rollback()


def find_town_unsafe(conn, name):
    # DON'T: the user's text becomes part of the SQL
    run(conn, f"SELECT id, name, kind FROM towns WHERE name = '{name}'")


def find_town_safe(conn, name):
    # DO: the SQL is fixed; the user's text is sent separately, as data
    run(conn, "SELECT id, name, kind FROM towns WHERE name = %s", (name,))


ATTEMPTS = [
    "Ashford",
    "O'Brien",
    "x' OR '1'='1",
    "x' UNION SELECT id, name, role FROM leaders --",
    "x'; DROP TABLE meetings; --",
]

with psycopg.connect(ADMIN, row_factory=dict_row) as conn:
    show("1. connect, and read")
    with conn.cursor() as cur:
        cur.execute("SELECT current_user, version()")
        row = cur.fetchone()
        print(row["current_user"], "|", row["version"].split(",")[0])
        cur.execute("SELECT id, name, population FROM towns ORDER BY id LIMIT 3")
        for town in cur.fetchall():
            print("  ", town)
    conn.rollback()

    show("2. building SQL from strings")
    for text in ATTEMPTS:
        print(f"\n--- input: {text!r}")
        find_town_unsafe(conn, text)

    show("did meetings survive?")
    run(conn, "SELECT count(*) FROM meetings")

    show("3. the same inputs, as parameters")
    for text in ATTEMPTS:
        print(f"\n--- input: {text!r}")
        find_town_safe(conn, text)

    show("4. what a parameter can't be: a column name")
    run(conn, "SELECT name, population FROM towns ORDER BY %s DESC LIMIT 3", ("population",))
    run(conn, "SELECT name, population FROM towns ORDER BY %s DESC LIMIT 3", ("population; DROP TABLE towns",))
    allowed = {"name", "population", "founded"}
    for choice in ["population", "population; DROP TABLE towns"]:
        print(f"\n--- sort by: {choice!r}")
        if choice not in allowed:
            print("   refused: not an allowed column")
            continue
        query = sql.SQL("SELECT name, {col} FROM towns ORDER BY {col} DESC NULLS LAST LIMIT 3").format(
            col=sql.Identifier(choice))
        run(conn, query)

    show("5. LIKE, and lists, as parameters")
    run(conn, "SELECT name FROM towns WHERE name ILIKE '%%' || %s || '%%' ORDER BY name", ("ash",))
    run(conn, "SELECT id, name FROM towns WHERE id = ANY(%s) ORDER BY id", ([1, 5, 10],))

    show("6. a transaction in code")
    try:
        with conn.transaction():
            with conn.cursor() as cur:
                cur.execute("UPDATE towns SET population = %s WHERE id = %s", (8500, 4))
                print("   updated:", cur.rowcount, "row")
                cur.execute("UPDATE towns SET population = %s WHERE id = %s", ("unknown", 4))
    except psycopg.Error as e:
        print("   ERROR:", type(e).__name__, "-", str(e).splitlines()[0])
    with conn.cursor() as cur:
        cur.execute("SELECT population FROM towns WHERE id = 4")
        print("   Cedar Hollow's population afterwards:", cur.fetchone()["population"])
    conn.rollback()

with psycopg.connect(READER, row_factory=dict_row) as conn:
    show("7. the same attack, as a read-only role")
    find_town_unsafe(conn, "x'; DROP TABLE meetings; --")
    find_town_unsafe(conn, "x' UNION SELECT id, name, role FROM leaders --")
