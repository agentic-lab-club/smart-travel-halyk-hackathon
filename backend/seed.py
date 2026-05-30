"""Generate 1 year of correlated test data for a single user."""
import random
from datetime import datetime, timedelta
from typing import Any

import psycopg2
from psycopg2.extras import execute_values

from db import get_connection

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
USER_ID = 1
ACCOUNT_ID = 1001
START_DATE = datetime(2025, 6, 1)
END_DATE = datetime(2026, 5, 31, 23, 59, 59)

random.seed(42)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def rand_dt(base: datetime, hour_range: tuple[int, int] = (8, 22)) -> datetime:
    h = random.randint(*hour_range)
    m = random.randint(0, 59)
    s = random.randint(0, 59)
    return base.replace(hour=h, minute=m, second=s)


# -----------------------------------------------------------------------------
# Generators
# -----------------------------------------------------------------------------
def gen_account_transactions() -> list[dict[str, Any]]:
    txs: list[dict[str, Any]] = []
    tx_id = 1_000_000_000

    cats = {
        "salary": ("top_up", "income", "Зарплата", "employer_salary", "Зарплата за месяц"),
        "rent": ("card_payment", "expense", "Аренда квартиры", "housing", "Жилье"),
        "utilities": ("card_payment", "expense", "Коммунальные услуги", "housing", "ЖКХ"),
        "food": ("card_payment", "expense", None, "food", "Продукты"),
        "transport": ("card_payment", "expense", None, "transport", "Транспорт"),
        "entertainment": ("card_payment", "expense", None, "entertainment", "Развлечения"),
        "transfer": ("transfer_out", "expense", None, "transfers", "Перевод"),
        "withdrawal": ("withdrawal", "expense", None, "cash", "Снятие наличных"),
        "cashback": ("cashback", "income", "Кешбэк Halyk", "cashback", "Кешбэк"),
        "interest": ("interest_accrual", "income", "Начисление процентов", "savings", "Проценты"),
    }

    cur = START_DATE
    while cur <= END_DATE:
        year, month = cur.year, cur.month
        if month == 12:
            next_m = datetime(year + 1, 1, 1)
        else:
            next_m = datetime(year, month + 1, 1)
        days_in_month = (next_m - timedelta(days=1)).day

        # --- salary (1st-5th) ------------------------------------------------
        salary_day = random.randint(1, 5)
        salary_amount = random.randint(450_000, 650_000)
        txs.append({
            "id": tx_id,
            "dt": rand_dt(datetime(year, month, salary_day), (9, 17)),
            "type": cats["salary"][0],
            "direction": cats["salary"][1],
            "amount": salary_amount,
            "cp_name": cats["salary"][2],
            "cp_account": None,
            "cat_code": cats["salary"][3],
            "cat_name": cats["salary"][4],
            "channel": "mobile_app",
            "desc": "Зарплата",
            "status": "success",
        })
        tx_id += 1

        # --- rent (5th-7th) --------------------------------------------------
        rent_day = random.randint(5, 7)
        txs.append({
            "id": tx_id,
            "dt": rand_dt(datetime(year, month, rent_day)),
            "type": cats["rent"][0],
            "direction": cats["rent"][1],
            "amount": random.randint(120_000, 150_000),
            "cp_name": "Арендодатель",
            "cp_account": None,
            "cat_code": cats["rent"][3],
            "cat_name": cats["rent"][4],
            "channel": "mobile_app",
            "desc": "Оплата аренды",
            "status": "success",
        })
        tx_id += 1

        # --- utilities (10th-15th) -------------------------------------------
        util_day = random.randint(10, 15)
        txs.append({
            "id": tx_id,
            "dt": rand_dt(datetime(year, month, util_day)),
            "type": cats["utilities"][0],
            "direction": cats["utilities"][1],
            "amount": random.randint(15_000, 30_000),
            "cp_name": "АлматыЭнергоСбыт",
            "cp_account": None,
            "cat_code": cats["utilities"][3],
            "cat_name": cats["utilities"][4],
            "channel": "mobile_app",
            "desc": "Коммунальные услуги",
            "status": "success",
        })
        tx_id += 1

        # --- food (3-5 times) ------------------------------------------------
        for _ in range(random.randint(3, 5)):
            d = random.randint(1, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d)),
                "type": cats["food"][0],
                "direction": cats["food"][1],
                "amount": random.randint(3_000, 25_000),
                "cp_name": random.choice(["Magnum", "Small", "Ашан", "Galmart", "Metro"]),
                "cp_account": None,
                "cat_code": cats["food"][3],
                "cat_name": cats["food"][4],
                "channel": random.choice(["mobile_app", "pos_terminal"]),
                "desc": "Покупка продуктов",
                "status": "success",
            })
            tx_id += 1

        # --- transport (4-8 times) -------------------------------------------
        for _ in range(random.randint(4, 8)):
            d = random.randint(1, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d), (6, 23)),
                "type": cats["transport"][0],
                "direction": cats["transport"][1],
                "amount": random.randint(500, 5_000),
                "cp_name": random.choice(["OnTaxi", "Yandex Go", "Uber", "Metro", "Avtobus"]),
                "cp_account": None,
                "cat_code": cats["transport"][3],
                "cat_name": cats["transport"][4],
                "channel": random.choice(["mobile_app", "pos_terminal"]),
                "desc": "Транспорт",
                "status": "success",
            })
            tx_id += 1

        # --- entertainment (non-kino) 1-2 times ------------------------------
        for _ in range(random.randint(1, 2)):
            d = random.randint(1, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d)),
                "type": cats["entertainment"][0],
                "direction": cats["entertainment"][1],
                "amount": random.randint(5_000, 30_000),
                "cp_name": random.choice(["Steam", "PlayStation Store", "iTunes", "Netflix", "Spotify"]),
                "cp_account": None,
                "cat_code": cats["entertainment"][3],
                "cat_name": cats["entertainment"][4],
                "channel": "online_payment",
                "desc": "Развлечения",
                "status": "success",
            })
            tx_id += 1

        # --- transfer 0-1 times ----------------------------------------------
        if random.random() < 0.5:
            d = random.randint(1, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d)),
                "type": cats["transfer"][0],
                "direction": cats["transfer"][1],
                "amount": random.randint(10_000, 100_000),
                "cp_name": random.choice(["Иван И.", "Айгуль К.", "Дмитрий П.", "Асан Т."]),
                "cp_account": f"KZ{random.randint(100000000, 999999999)}",
                "cat_code": cats["transfer"][3],
                "cat_name": cats["transfer"][4],
                "channel": "mobile_app",
                "desc": "Перевод",
                "status": "success",
            })
            tx_id += 1

        # --- withdrawal 0-1 times --------------------------------------------
        if random.random() < 0.4:
            d = random.randint(1, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d)),
                "type": cats["withdrawal"][0],
                "direction": cats["withdrawal"][1],
                "amount": random.randint(10_000, 50_000),
                "cp_name": random.choice(["Halyk Bank ATM", "Kaspi ATM", "Jusan ATM"]),
                "cp_account": None,
                "cat_code": cats["withdrawal"][3],
                "cat_name": cats["withdrawal"][4],
                "channel": "atm",
                "desc": "Снятие наличных",
                "status": "success",
            })
            tx_id += 1

        # --- cashback 1-2 times ----------------------------------------------
        for _ in range(random.randint(1, 2)):
            d = random.randint(1, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d)),
                "type": cats["cashback"][0],
                "direction": cats["cashback"][1],
                "amount": random.randint(500, 5_000),
                "cp_name": cats["cashback"][2],
                "cp_account": None,
                "cat_code": cats["cashback"][3],
                "cat_name": cats["cashback"][4],
                "channel": "mobile_app",
                "desc": "Кешбэк",
                "status": "success",
            })
            tx_id += 1

        # --- interest 0-1 times ----------------------------------------------
        if random.random() < 0.5:
            d = random.randint(25, days_in_month)
            txs.append({
                "id": tx_id,
                "dt": rand_dt(datetime(year, month, d)),
                "type": cats["interest"][0],
                "direction": cats["interest"][1],
                "amount": random.randint(1_000, 10_000),
                "cp_name": cats["interest"][2],
                "cp_account": None,
                "cat_code": cats["interest"][3],
                "cat_name": cats["interest"][4],
                "channel": "mobile_app",
                "desc": "Начисление процентов",
                "status": "success",
            })
            tx_id += 1

        cur = next_m

    return txs


def gen_kino_transactions() -> list[dict[str, Any]]:
    txs: list[dict[str, Any]] = []
    tx_id = 2_000_000_000

    events = {
        "movie": {
            "names": ["Дюна: Часть вторая", "Барби", "Оппенгеймер", "Человек-паук: Нет пути домой",
                      "Аватар: Путь воды", "Джон Уик 4", "Мстители: Финал", "Интерстеллар", "Начало", "Темный рыцарь"],
            "genres": ["action", "comedy", "drama", "anime", "sci-fi", "thriller"],
            "price": (2_500, 6_000),
            "tickets": (1, 4),
        },
        "concert": {
            "names": ["Rock Fest 2025", "Jazz Night", "Поп-концерт", "Indie Session", "Hip-Hop Party", "Klassika Open Air"],
            "genres": ["rock", "pop", "jazz", "hip-hop", "classical"],
            "price": (10_000, 50_000),
            "tickets": (1, 2),
        },
        "theatre": {
            "names": ["Гамлет", "Ромео и Джульетта", "Чайка", "Ревизор", "Евгений Онегин", "Король Лир"],
            "genres": ["drama", "comedy", "tragedy"],
            "price": (5_000, 20_000),
            "tickets": (1, 3),
        },
        "tour": {
            "names": ["Тур по Алматинским горам", "Шымбулак экстрим", "Чарынский каньон", "Кольсайские озера",
                      "Боровое золотое кольцо", "Алтын-Эмель сафари", "Туркестан исторический", "Актау пляжный"],
            "genres": ["mountain_tour", "city_tour", "bike_tour", "beach_tour", "historical_tour"],
            "price": (80_000, 300_000),
            "tickets": (1, 2),
        },
        "sport": {
            "names": ["Футбол: Казахстан - Европа", "Баскетбол Финал", "Теннис ATP", "Хоккей КХЛ", "UFC Fight Night"],
            "genres": ["football", "basketball", "tennis", "hockey", "mma"],
            "price": (3_000, 15_000),
            "tickets": (1, 4),
        },
        "family": {
            "names": ["Цирк Шапито", "Детский мюзикл", "Новогоднее представление", "Парк развлечений VIP"],
            "genres": ["kids_show", "circus", "musical"],
            "price": (5_000, 25_000),
            "tickets": (2, 5),
        },
    }

    cities = {
        "Алматы": ["Kinopark 5", "Chaplin MEGA", "Cinemax Dostyk", "Алматы Арена", "Дворец Республики"],
        "Астана": ["Kinopark Keruen", "Chaplin Asia Park", "Стадион Астана Арена", "Театр оперы и балета"],
        "Шымкент": ["Kinopark Shymkent", "Центральный стадион", "Театр драмы"],
        "Актау": ["Kinopark Aktau", "Пляжный комплекс", "Актау Арена"],
        "Туркестан": ["Исторический комплекс", "Туркестан Арена"],
    }

    city_weights = ["Алматы"] * 4 + ["Астана"] * 3 + ["Шымкент"] * 2 + ["Актау", "Туркестан"]

    cur = START_DATE
    month_idx = 0
    while cur <= END_DATE:
        year, month = cur.year, cur.month
        if month == 12:
            next_m = datetime(year + 1, 1, 1)
        else:
            next_m = datetime(year, month + 1, 1)
        days_in_month = (next_m - timedelta(days=1)).day

        # --- after salary (3rd-8th) 1-2 events -------------------------------
        after_salary_count = random.randint(1, 2)
        for _ in range(after_salary_count):
            d = random.randint(3, 8)
            _add_kino(txs, tx_id, year, month, d, days_in_month, events, cities, city_weights)
            tx_id += 1

        # --- mid-month (15th-20th) 0-1 events --------------------------------
        if random.random() < 0.35:
            d = random.randint(15, 20)
            _add_kino(txs, tx_id, year, month, d, days_in_month, events, cities, city_weights)
            tx_id += 1

        # --- August extra tours ----------------------------------------------
        if month == 8:
            for _ in range(2):
                d = random.randint(10, 25)
                _add_kino(txs, tx_id, year, month, d, days_in_month, events, cities, city_weights, force_class="tour")
                tx_id += 1

        cur = next_m
        month_idx += 1

    return txs


def _add_kino(txs, tx_id, year, month, day, days_in_month, events, cities, city_weights, force_class=None):
    if force_class:
        cls = force_class
    else:
        cls = random.choices(
            ["movie", "concert", "theatre", "tour", "sport", "family"],
            weights=[60, 15, 10, 5, 5, 5]
        )[0]

    info = events[cls]
    city = random.choice(city_weights)
    venue = random.choice(cities[city])
    event_name = random.choice(info["names"])
    genre = random.choice(info["genres"]) if cls == "movie" else (random.choice(info["genres"]) if random.random() < 0.7 else None)

    tickets = random.randint(*info["tickets"])
    price = round(random.uniform(*info["price"]), 2)
    total = round(price * tickets, 2)

    pay_method = random.choices(
        ["halyk_card", "bonus", "apple_pay", "halyk_bonus_mix"],
        weights=[60, 15, 15, 10]
    )[0]

    if pay_method == "bonus":
        bonus = total
    elif pay_method == "halyk_bonus_mix":
        bonus = round(total * random.uniform(0.2, 0.5), 2)
    else:
        bonus = round(total * random.uniform(0, 0.1), 2) if random.random() < 0.3 else 0

    cashback = round(total * random.uniform(0.01, 0.05), 2) if pay_method in ("halyk_card", "halyk_bonus_mix") and random.random() < 0.6 else 0
    status = random.choices(["paid", "cancelled", "refunded"], weights=[85, 10, 5])[0]

    purchase_dt = rand_dt(datetime(year, month, min(day, days_in_month)))
    event_dt = purchase_dt + timedelta(days=random.randint(1, 14), hours=random.randint(0, 23))

    txs.append({
        "id": tx_id,
        "purchase_dt": purchase_dt,
        "event_dt": event_dt,
        "event_name": event_name,
        "class_code": cls,
        "subclass_code": f"{genre}_{cls}" if genre else cls,
        "genre_code": genre,
        "city": city,
        "venue_name": venue,
        "tickets_count": tickets,
        "ticket_price": price,
        "total_amount": total,
        "payment_method": pay_method,
        "bonus_used": bonus,
        "cashback_amount": cashback,
        "source_platform": random.choice(["kino_kz_app", "kino_kz_web", "halyk_app"]),
        "status": status,
    })


def add_linked_card_payments(account_txs: list[dict], kino_txs: list[dict]) -> list[dict]:
    """Add card_payment account transactions for kino purchases paid by card."""
    next_id = max(t["id"] for t in account_txs) + 1 if account_txs else 1_000_000_000
    for kt in kino_txs:
        if kt["payment_method"] not in ("halyk_card", "halyk_bonus_mix"):
            continue
        card_amount = kt["total_amount"] - kt["bonus_used"]
        if card_amount <= 0:
            continue
        account_txs.append({
            "id": next_id,
            "dt": kt["purchase_dt"] + timedelta(minutes=random.randint(0, 3)),
            "type": "card_payment",
            "direction": "expense",
            "amount": round(card_amount, 2),
            "cp_name": "Kino.kz",
            "cp_account": None,
            "cat_code": "entertainment",
            "cat_name": "Билеты и развлечения",
            "channel": random.choice(["mobile_app", "online_payment"]),
            "desc": f"{kt['event_name']} ({kt['class_code']})",
            "status": "success",
        })
        next_id += 1
    return account_txs


def compute_balances(txs: list[dict]) -> list[dict]:
    txs.sort(key=lambda x: (x["dt"], x["id"]))
    balance = 500_000  # starting balance
    for t in txs:
        t["balance_before"] = round(balance, 2)
        if t["direction"] == "income":
            balance += t["amount"]
        else:
            balance -= t["amount"]
        t["balance_after"] = round(balance, 2)
    return txs


def insert_account_transactions(conn, txs: list[dict]):
    sql = """
    INSERT INTO account_transactions (
        transaction_id, user_id, account_id, account_type,
        transaction_datetime, transaction_type, direction,
        amount, currency, balance_before, balance_after,
        counterparty_name, counterparty_account,
        category_code, category_name, channel, description, status
    ) VALUES %s
    """
    values = [
        (
            t["id"], USER_ID, ACCOUNT_ID, "card",
            t["dt"], t["type"], t["direction"],
            t["amount"], "KZT", t.get("balance_before"), t.get("balance_after"),
            t["cp_name"], t.get("cp_account"),
            t["cat_code"], t["cat_name"], t["channel"], t["desc"], t["status"]
        )
        for t in txs
    ]
    with conn.cursor() as cur:
        execute_values(cur, sql, values)
    conn.commit()


def insert_kino_transactions(conn, txs: list[dict]):
    sql = """
    INSERT INTO kino_ticket_transactions (
        transaction_id, user_id, purchase_datetime, event_datetime,
        event_name, class_code, subclass_code, genre_code,
        city, venue_name, tickets_count, ticket_price, total_amount,
        payment_method, bonus_used, cashback_amount,
        source_platform, status
    ) VALUES %s
    """
    values = [
        (
            t["id"], USER_ID, t["purchase_dt"], t["event_dt"],
            t["event_name"], t["class_code"], t["subclass_code"], t["genre_code"],
            t["city"], t["venue_name"], t["tickets_count"], t["ticket_price"], t["total_amount"],
            t["payment_method"], t["bonus_used"], t["cashback_amount"],
            t["source_platform"], t["status"]
        )
        for t in txs
    ]
    with conn.cursor() as cur:
        execute_values(cur, sql, values)
    conn.commit()


def main():
    print("Generating account transactions ...")
    account_txs = gen_account_transactions()
    print(f"  Generated {len(account_txs)} account tx")

    print("Generating kino transactions ...")
    kino_txs = gen_kino_transactions()
    print(f"  Generated {len(kino_txs)} kino tx")

    print("Linking card payments ...")
    account_txs = add_linked_card_payments(account_txs, kino_txs)
    print(f"  Account tx after linkage: {len(account_txs)}")

    print("Computing balances ...")
    account_txs = compute_balances(account_txs)

    conn = get_connection()
    try:
        print("Inserting account_transactions ...")
        insert_account_transactions(conn, account_txs)
        print("Inserting kino_ticket_transactions ...")
        insert_kino_transactions(conn, kino_txs)
        print("Done!")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
