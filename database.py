import sqlite3
from datetime import datetime

def init_db():
    conn = sqlite3.connect("receipts.db")
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store TEXT,
        total REAL,
        insights TEXT,
        date TEXT
    )
    """)

    conn.commit()
    conn.close()


def save_receipt(data):

    conn = sqlite3.connect("receipts.db")
    cursor = conn.cursor()

    cursor.execute("""
    INSERT INTO receipts (store, total, insights, date)
    VALUES (?, ?, ?, ?)
    """, (
        data.get("store", "Unknown"),
        data.get("total", 0),
        str(data.get("insights", [])),
        datetime.now().strftime("%Y-%m-%d")
    ))

    conn.commit()
    conn.close()