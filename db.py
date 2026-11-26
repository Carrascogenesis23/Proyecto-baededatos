import os

import psycopg2
from psycopg2.extensions import connection as PsycopgConnection


def get_connection() -> PsycopgConnection:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)

    database_name = os.getenv("DB_NAME") or os.getenv("PGDATABASE")
    database_user = os.getenv("DB_USER") or os.getenv("PGUSER")
    missing = []
    if not database_name:
        missing.append("DB_NAME (o PGDATABASE)")
    if not database_user:
        missing.append("DB_USER (o PGUSER)")
    if missing:
        raise RuntimeError(
            "Faltan variables de conexión a PostgreSQL: " + ", ".join(missing)
        )

    connection_options = {
        "dbname": database_name,
        "user": database_user,
        "host": os.getenv("DB_HOST") or os.getenv("PGHOST", "localhost"),
        "port": os.getenv("DB_PORT") or os.getenv("PGPORT", "5432"),
    }
    password = os.getenv("DB_PASSWORD") or os.getenv("PGPASSWORD")
    if password:
        connection_options["password"] = password

    return psycopg2.connect(**connection_options)
