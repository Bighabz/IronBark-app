"""
Database layer for IronBark.

Reads DB_ENGINE from .env to decide between MySQL (PyMySQL) and MSSQL (pyodbc).
All queries use parameterized statements — no string concatenation, no f-strings
in SQL. The Red Team WILL try SQL injection.
"""

import os
import logging
from flask import g

log = logging.getLogger("ironbark.db")

_ENGINE = os.getenv("DB_ENGINE", "mysql").lower()


def init_app(app):
    app.teardown_appcontext(_close)


def _close(exc=None):
    conn = g.pop("db_conn", None)
    if conn is not None:
        try:
            conn.close()
        except Exception:
            pass


def get_db():
    if "db" not in g:
        if _ENGINE == "mysql":
            g.db = _MySQLDb()
        elif _ENGINE == "mssql":
            g.db = _MSSQLDb()
        else:
            raise RuntimeError(f"Unsupported DB_ENGINE: {_ENGINE}")
    return g.db


class _MySQLDb:
    def __init__(self):
        import pymysql
        import pymysql.cursors
        self.conn = pymysql.connect(
            host=os.getenv("DB_HOST", "10.0.1.200"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", "ironbark_app"),
            password=os.getenv("DB_PASSWORD", ""),
            database=os.getenv("DB_NAME", "ironbark"),
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True,
            connect_timeout=5,
        )
        g.db_conn = self.conn

    def query(self, sql, params=()):
        with self.conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall()

    def execute(self, sql, params=()):
        with self.conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.lastrowid


class _MSSQLDb:
    def __init__(self):
        import pyodbc
        driver = os.getenv("DB_ODBC_DRIVER", "ODBC Driver 17 for SQL Server")
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={os.getenv('DB_HOST', '10.0.1.200')},{os.getenv('DB_PORT','1433')};"
            f"DATABASE={os.getenv('DB_NAME', 'ironbark')};"
            f"UID={os.getenv('DB_USER', 'ironbark_app')};"
            f"PWD={os.getenv('DB_PASSWORD', '')};"
            "TrustServerCertificate=yes;"
            "Connection Timeout=5;"
        )
        self.conn = pyodbc.connect(conn_str, autocommit=True)
        g.db_conn = self.conn

    def _rows_to_dicts(self, cur):
        cols = [c[0] for c in cur.description] if cur.description else []
        return [dict(zip(cols, row)) for row in cur.fetchall()]

    def query(self, sql, params=()):
        # pyodbc uses ? placeholders — translate %s from our calling code.
        sql = sql.replace("%s", "?")
        cur = self.conn.cursor()
        cur.execute(sql, params)
        return self._rows_to_dicts(cur)

    def execute(self, sql, params=()):
        sql = sql.replace("%s", "?")
        cur = self.conn.cursor()
        cur.execute(sql, params)
        return cur.rowcount
