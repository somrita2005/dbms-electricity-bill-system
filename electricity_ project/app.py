from flask import Flask, render_template
import mysql.connector
 
app = Flask(__name__)
 
# -----------------------------------------------
# MySQL Connection — change these to your details
# -----------------------------------------------
def get_db():
    conn = mysql.connector.connect(
        host="localhost",
        user="root",           # your MySQL Workbench username
        password="somrita",           # your MySQL Workbench password
        database="electricity_db"
    )
    return conn
 
 
# -----------------------------------------------
# Home — Dashboard
# -----------------------------------------------
@app.route("/")
def home():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
 
    cursor.execute("SELECT COUNT(*) AS total FROM consumers WHERE status = 'Active'")
    total_consumers = cursor.fetchone()["total"]
 
    cursor.execute("SELECT COUNT(*) AS total FROM bills WHERE status != 'Paid'")
    unpaid_bills = cursor.fetchone()["total"]
 
    cursor.execute("SELECT SUM(amount_paid) AS total FROM payments WHERE status = 'Success'")
    total_collected = cursor.fetchone()["total"] or 0
 
    cursor.execute("SELECT COUNT(*) AS total FROM complaints WHERE status = 'Open'")
    open_complaints = cursor.fetchone()["total"]
 
    conn.close()
    return render_template("index.html",
        total_consumers=total_consumers,
        unpaid_bills=unpaid_bills,
        total_collected=total_collected,
        open_complaints=open_complaints
    )
 
 
# -----------------------------------------------
# Consumers — list all consumers
# -----------------------------------------------
@app.route("/consumers")
def consumers():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM consumers ORDER BY created_at DESC")
    data = cursor.fetchall()
    conn.close()
    return render_template("consumers.html", consumers=data)
 
 
# -----------------------------------------------
# Bills — list all unpaid/overdue bills
# -----------------------------------------------
@app.route("/bills")
def bills():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT b.bill_number, c.full_name, c.phone,
               b.units_consumed, b.total_amount, b.due_date, b.status
        FROM bills b
        JOIN consumers c ON b.consumer_id = c.consumer_id
        ORDER BY b.due_date DESC
    """)
    data = cursor.fetchall()
    conn.close()
    return render_template("bills.html", bills=data)
 
 
# -----------------------------------------------
# Payments — payment history
# -----------------------------------------------
@app.route("/payments")
def payments():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT p.payment_id, c.full_name, b.bill_number,
               p.amount_paid, p.payment_date, p.payment_mode, p.status
        FROM payments p
        JOIN consumers c ON p.consumer_id = c.consumer_id
        JOIN bills b ON p.bill_id = b.bill_id
        ORDER BY p.payment_date DESC
    """)
    data = cursor.fetchall()
    conn.close()
    return render_template("payments.html", payments=data)
 
 
# -----------------------------------------------
# Complaints — open complaints
# -----------------------------------------------
@app.route("/complaints")
def complaints():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT c.complaint_id, co.full_name, co.phone,
               c.subject, c.description, c.status, c.created_at
        FROM complaints c
        JOIN consumers co ON c.consumer_id = co.consumer_id
        ORDER BY c.created_at DESC
    """)
    data = cursor.fetchall()
    conn.close()
    return render_template("complaints.html", complaints=data)
 
 
# -----------------------------------------------
# Run the app
# -----------------------------------------------
if __name__ == "__main__":
    app.run(debug=True)
 
