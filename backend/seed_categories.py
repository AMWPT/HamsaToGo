"""Seed script — creates 3 categories then prints their IDs."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from firebase.config import init_firebase, get_firestore

init_firebase()
db = get_firestore()

categories = [
    {"name_en": "Hot Drinks",  "name_ar": "المشروبات الساخنة", "icon": "coffee",      "sort_order": 1},
    {"name_en": "Cold Drinks", "name_ar": "المشروبات الباردة", "icon": "local_bar",   "sort_order": 2},
    {"name_en": "Food",        "name_ar": "الطعام",                                                             "icon": "restaurant", "sort_order": 3},
]

for cat in categories:
    ref = db.collection("categories").document()
    ref.set(cat)
    print(f"[OK] {cat['name_en']} — id: {ref.id}")

print("Done.")
