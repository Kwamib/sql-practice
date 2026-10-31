# sql-practice

Practice data for the SQL track on [kwamib.dev](https://kwamib.dev/resources/sql).
Larkspur County is made up: every town, person, phone number and website is
invented.

Start Postgres in a container, with this folder inside it at `/practice`:

    docker run -d --name larkspur -e POSTGRES_PASSWORD=practice -v "$PWD":/practice postgres:16

Load the data, then open `psql` on it:

    docker exec larkspur psql -U postgres -f /practice/larkspur.sql
    docker exec -it larkspur psql -U postgres -d larkspur

Loading again starts the database fresh. When you're done for the day,
`docker stop larkspur`; `docker start larkspur` brings it back. `docker rm -f larkspur`
removes it completely.

The data has a few mistakes in it on purpose, the kind real data always has.
The lessons find them.
