import psycopg2
import random
import uuid
from datetime import datetime, timedelta


DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "sar_assistant",
    "user": "saruser",
    "password": "sarpass123"
}

NORMAL_CUSTOMER_IDS = [
    f"a0000001-0000-0000-0000-0000000000{str(i).zfill(2)}"
    for i in range(11, 36)
]

BRANCHES = [
    "Chicago Main", "Lincoln Park", "Loop Branch", "Wicker Park",
    "Evanston Branch", "Skokie Branch", "Oak Brook Branch",
    "Schaumburg Branch", "Naperville Branch", "River North"
]

EMPLOYERS = [
    ("TechCorp Inc", 4500), ("Acme Solutions", 3800), ("Global Media", 5200),
    ("Midwest Healthcare", 4100), ("City of Chicago", 3600), ("Cook County", 3900),
    ("United Airlines", 5500), ("Allstate Insurance", 4800), ("Motorola", 6200),
    ("Abbott Labs", 5800), ("Caterpillar Inc", 5000), ("John Deere", 4700),
    ("State Farm", 4300), ("McDonalds Corp", 3500), ("Walgreens", 3700)
]

VENDORS = [
    "AT&T", "ComEd", "Peoples Gas", "Amazon", "Target",
    "Jewel-Osco", "Costco", "Home Depot", "Walmart", "Verizon"
]


def generate_normal_transactions(conn):
    cursor = conn.cursor()
    base_date = datetime(2025, 9, 1)

    for cust_id in NORMAL_CUSTOMER_IDS:
        employer, salary = random.choice(EMPLOYERS)

        for month_offset in range(3):
            pay_date_1 = base_date + timedelta(days=month_offset * 30)
            pay_date_2 = pay_date_1 + timedelta(days=14)

            cursor.execute(
                """INSERT INTO transactions 
                (customer_id, type, amount, direction, counterparty_name, 
                 counterparty_country, description, branch, transaction_date)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (cust_id, "ach", salary, "inbound", employer,
                 "USA", "Payroll deposit", random.choice(BRANCHES),
                 pay_date_1.strftime("%Y-%m-%d 09:00:00"))
            )

            cursor.execute(
                """INSERT INTO transactions 
                (customer_id, type, amount, direction, counterparty_name, 
                 counterparty_country, description, branch, transaction_date)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (cust_id, "ach", salary, "inbound", employer,
                 "USA", "Payroll deposit", random.choice(BRANCHES),
                 pay_date_2.strftime("%Y-%m-%d 09:00:00"))
            )

            num_expenses = random.randint(2, 5)
            for _ in range(num_expenses):
                days_after = random.randint(1, 28)
                expense_date = pay_date_1 + timedelta(days=days_after)
                vendor = random.choice(VENDORS)
                amount = round(random.uniform(50, 2000), 2)
                txn_type = random.choice(["ach", "check"])

                cursor.execute(
                    """INSERT INTO transactions 
                    (customer_id, type, amount, direction, counterparty_name, 
                     counterparty_country, description, branch, transaction_date)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                    (cust_id, txn_type, amount, "outbound", vendor,
                     "USA", "Payment", random.choice(BRANCHES),
                     expense_date.strftime("%Y-%m-%d %H:%M:%S"))
                )

    conn.commit()
    cursor.close()
    print(f"Generated normal transactions for {len(NORMAL_CUSTOMER_IDS)} customers")


if __name__ == "__main__":
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        generate_normal_transactions(conn)
        print("Seed data generation complete")
    finally:
        conn.close()