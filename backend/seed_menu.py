"""Seed script — clears old items and adds full menu."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
os.environ['PYTHONIOENCODING'] = 'utf-8'

from firebase.config import init_firebase, get_firestore

init_firebase()
db = get_firestore()

# ─── Category IDs ─────────────────────────────────────────────
HOT  = "9e9K0dYx8Ts7V7z2mT7h"
COLD = "hNmlFa9NofRh3upij1ku"

# ─── Options ──────────────────────────────────────────────────
TEMP = {
    "name": "Temperature",
    "choices": ["Standard", "Extra Hot"],
    "required": True,
    "price_modifiers": {},
}
MILK = {
    "name": "Milk",
    "choices": ["Full Fat Milk", "Lactose Free", "Coconut Milk (+5 SAR)", "Almond Milk (+5 SAR)"],
    "required": True,
    "price_modifiers": {
        "Coconut Milk (+5 SAR)": 5.0,
        "Almond Milk (+5 SAR)": 5.0,
    },
}

# ─── Delete old items ─────────────────────────────────────────
print("Deleting old items...")
old = db.collection("menu_items").stream()
count = 0
for doc in old:
    doc.reference.delete()
    count += 1
print(f"Deleted {count} old items.")

# ─── New items ────────────────────────────────────────────────
items = [
    # ── Hot Drinks ───────────────────────────────────────────
    {
        "category_id": HOT,
        "name_en": "Double Espresso",
        "name_ar": "دبل اسبريسو",
        "price": 12.0,
        "available": True,
        "options": [TEMP],
    },
    {
        "category_id": HOT,
        "name_en": "Americano",
        "name_ar": "امريكانو",
        "price": 13.0,
        "available": True,
        "options": [],
    },
    {
        "category_id": HOT,
        "name_en": "Cortado",
        "name_ar": "كورتادو",
        "price": 13.0,
        "available": True,
        "options": [TEMP, MILK],
    },
    {
        "category_id": HOT,
        "name_en": "Flat White",
        "name_ar": "فلات وايت",
        "price": 14.0,
        "available": True,
        "options": [TEMP, MILK],
    },
    {
        "category_id": HOT,
        "name_en": "Cappuccino",
        "name_ar": "كابتشينو",
        "price": 15.0,
        "available": True,
        "options": [TEMP, MILK],
    },
    {
        "category_id": HOT,
        "name_en": "Latte",
        "name_ar": "لاتيه",
        "price": 16.0,
        "available": True,
        "options": [TEMP, MILK],
    },
    {
        "category_id": HOT,
        "name_en": "Coffee of the Day",
        "name_ar": "قهوة اليوم",
        "price": 10.0,
        "available": True,
        "options": [],
    },
    {
        "category_id": HOT,
        "name_en": "Drip Coffee",
        "name_ar": "قهوة مقطرة",
        "price": 17.0,
        "available": True,
        "options": [],
    },
    {
        "category_id": HOT,
        "name_en": "Coffee of the Day 1L",
        "name_ar": "قهوة اليوم 1 لتر",
        "price": 44.0,
        "available": True,
        "options": [],
    },

    # ── Cold Drinks ──────────────────────────────────────────
    {
        "category_id": COLD,
        "name_en": "Latte (Iced)",
        "name_ar": "لاتيه بارد",
        "price": 16.0,
        "available": True,
        "options": [MILK],
    },
    {
        "category_id": COLD,
        "name_en": "Coffee of the Day (Iced)",
        "name_ar": "قهوة اليوم باردة",
        "price": 10.0,
        "available": True,
        "options": [],
    },
    {
        "category_id": COLD,
        "name_en": "Drip Coffee (Iced)",
        "name_ar": "قهوة مقطرة باردة",
        "price": 17.0,
        "available": True,
        "options": [],
    },
]

print(f"Adding {len(items)} items...")
for item in items:
    ref = db.collection("menu_items").document()
    ref.set(item)
    print(f"  [OK] {item['name_en']} — {item['price']} SAR")

print(f"\nDone. {len(items)} items added.")
