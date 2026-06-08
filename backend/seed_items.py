"""Seed script — adds 2 menu items per category for testing."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from firebase.config import init_firebase, get_firestore

init_firebase()
db = get_firestore()

HOT   = "9e9K0dYx8Ts7V7z2mT7h"
COLD  = "hNmlFa9NofRh3upij1ku"
FOOD  = "jzlSgrIfXLKp080S1sqy"

items = [
    # ── Hot Drinks ──────────────────────────────────────────────
    {
        "category_id":    HOT,
        "name_en":        "Cappuccino",
        "name_ar":        "كابتشينو",
        "description_en": "Espresso with steamed milk and a thick layer of foam",
        "description_ar": "إسبريسو مع حليب مبخر وطبقة كثيفة من الرغوة",
        "price":          18.0,
        "available":      True,
        "options": [
            {"name": "Size", "choices": ["Small", "Medium", "Large"], "required": True}
        ],
        "image_url": None,
    },
    {
        "category_id":    HOT,
        "name_en":        "Latte",
        "name_ar":        "لاتيه",
        "description_en": "Smooth espresso with velvety steamed milk",
        "description_ar": "إسبريسو ناعم مع حليب مبخر مخملي",
        "price":          20.0,
        "available":      True,
        "options": [
            {"name": "Size", "choices": ["Small", "Medium", "Large"], "required": True},
            {"name": "Milk", "choices": ["Whole", "Oat", "Almond"], "required": False},
        ],
        "image_url": None,
    },

    # ── Cold Drinks ─────────────────────────────────────────────
    {
        "category_id":    COLD,
        "name_en":        "Iced Americano",
        "name_ar":        "أمريكانو بارد",
        "description_en": "Espresso shots over ice with cold water",
        "description_ar": "شوت إسبريسو فوق الثلج مع الماء البارد",
        "price":          16.0,
        "available":      True,
        "options": [
            {"name": "Size", "choices": ["Medium", "Large"], "required": True}
        ],
        "image_url": None,
    },
    {
        "category_id":    COLD,
        "name_en":        "Cold Brew",
        "name_ar":        "كولد برو",
        "description_en": "Slow-steeped coffee, smooth and bold with low acidity",
        "description_ar": "قهوة منقوعة ببطء، ناعمة وقوية مع حموضة منخفضة",
        "price":          22.0,
        "available":      True,
        "options": [],
        "image_url": None,
    },

    # ── Food ────────────────────────────────────────────────────
    {
        "category_id":    FOOD,
        "name_en":        "Croissant",
        "name_ar":        "كرواسان",
        "description_en": "Buttery, flaky French pastry baked fresh daily",
        "description_ar": "معجنات فرنسية مقرمشة بالزبدة تُخبز طازجة يومياً",
        "price":          12.0,
        "available":      True,
        "options": [
            {"name": "Type", "choices": ["Plain", "Chocolate", "Almond"], "required": True}
        ],
        "image_url": None,
    },
    {
        "category_id":    FOOD,
        "name_en":        "Avocado Toast",
        "name_ar":        "توست الأفوكادو",
        "description_en": "Sourdough toast with smashed avocado and sea salt",
        "description_ar": "توست العجين المخمر مع الأفوكادو المهروس وملح البحر",
        "price":          28.0,
        "available":      True,
        "options": [],
        "image_url": None,
    },
]

for item in items:
    ref = db.collection("menu_items").document()
    ref.set(item)
    print(f"[OK] {item['name_en']} ({item['price']} SAR) — id: {ref.id}")

print("\nAll items seeded.")
