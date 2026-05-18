import sqlite3

conn = sqlite3.connect("receipts.db")

cursor = conn.cursor()

cursor.execute("SELECT * FROM receipts")

rows = cursor.fetchall()

for row in rows:
    print(row)