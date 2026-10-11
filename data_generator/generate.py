"""Generate a synthetic multi-channel e-commerce dataset.

All data is fictional. The generator is deterministic (fixed seed) so that
CI runs and local runs produce the same tables.

The raw files intentionally contain a few real-world data quality issues
(duplicate rows from re-ingestion, inconsistent casing and whitespace) so the
staging layer has something meaningful to clean up.

Usage:
    python data_generator/generate.py --out dbt/seeds
"""

from __future__ import annotations

import argparse
import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

SEED = 42
START = date(2025, 1, 1)
END = date(2025, 12, 31)

CHANNELS = ["marketplace_a", "marketplace_b", "marketplace_c", "own_store"]
CHANNEL_WEIGHTS = [0.40, 0.25, 0.15, 0.20]

CATEGORIES = {
    "Accessories": (800, 4000),
    "Home": (1500, 9000),
    "Apparel": (2000, 12000),
    "Outdoor": (3000, 20000),
    "Stationery": (300, 2500),
}

PREFECTURES = ["Tokyo", "Kanagawa", "Osaka", "Aichi", "Fukuoka", "Hokkaido", "Saitama", "Chiba"]


def write_csv(path: Path, header: list[str], rows: list[list]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def random_date(rng: random.Random, start: date, end: date) -> date:
    return start + timedelta(days=rng.randint(0, (end - start).days))


def generate(out: Path, n_customers: int, n_products: int, n_orders: int) -> None:
    rng = random.Random(SEED)
    out.mkdir(parents=True, exist_ok=True)

    # Products
    products = []
    for i in range(1, n_products + 1):
        category = rng.choice(list(CATEGORIES))
        low, high = CATEGORIES[category]
        price = round(rng.randint(low, high), -1)
        cost = round(price * rng.uniform(0.35, 0.65))
        products.append([f"P{i:04d}", f"{category} item {i:03d}", category, price, cost])
    write_csv(out / "raw_products.csv", ["product_id", "product_name", "category", "list_price", "unit_cost"], products)

    # Customers (emails with inconsistent casing / whitespace on purpose)
    customers = []
    for i in range(1, n_customers + 1):
        email = f"customer{i:05d}@example.com"
        if rng.random() < 0.1:
            email = f"  {email.upper()} "
        signup = random_date(rng, date(2023, 1, 1), END)
        customers.append([f"C{i:05d}", email, rng.choice(PREFECTURES), signup.isoformat()])
    write_csv(out / "raw_customers.csv", ["customer_id", "email", "prefecture", "signed_up_on"], customers)

    # Orders and order items
    orders, items = [], []
    item_seq = 1
    for i in range(1, n_orders + 1):
        order_id = f"O{i:06d}"
        customer = rng.choice(customers)
        signup = date.fromisoformat(customer[3])
        ordered_on = random_date(rng, max(signup, START), END) if signup <= END else END
        ordered_at = datetime.combine(ordered_on, datetime.min.time()) + timedelta(minutes=rng.randint(0, 1439))
        channel = rng.choices(CHANNELS, CHANNEL_WEIGHTS)[0]
        if rng.random() < 0.05:
            channel = f" {channel.upper()}"
        status = rng.choices(["completed", "cancelled", "returned"], [0.9, 0.06, 0.04])[0]
        shipping_fee = 0 if channel == "own_store" and rng.random() < 0.5 else rng.choice([0, 500, 700])

        for _ in range(rng.choices([1, 2, 3, 4], [0.6, 0.25, 0.1, 0.05])[0]):
            product = rng.choice(products)
            qty = rng.choices([1, 2, 3], [0.8, 0.15, 0.05])[0]
            discount = rng.choice([0, 0, 0, 0.1, 0.2])
            unit_price = round(product[3] * (1 - discount))
            items.append([f"L{item_seq:07d}", order_id, product[0], qty, unit_price])
            item_seq += 1

        row = [order_id, customer[0], channel, ordered_at.isoformat(sep=" "), status, shipping_fee]
        orders.append(row)
        # ~1% of orders are ingested twice (duplicate rows)
        if rng.random() < 0.01:
            orders.append(row)

    write_csv(
        out / "raw_orders.csv",
        ["order_id", "customer_id", "channel", "ordered_at", "status", "shipping_fee"],
        orders,
    )
    write_csv(out / "raw_order_items.csv", ["order_item_id", "order_id", "product_id", "quantity", "unit_price"], items)

    print(f"customers={len(customers)} products={len(products)} orders={len(orders)} items={len(items)} -> {out}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, default=Path("dbt/seeds"))
    parser.add_argument("--customers", type=int, default=800)
    parser.add_argument("--products", type=int, default=60)
    parser.add_argument("--orders", type=int, default=5000)
    args = parser.parse_args()
    generate(args.out, args.customers, args.products, args.orders)


if __name__ == "__main__":
    main()
