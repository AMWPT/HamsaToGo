from pydantic import BaseModel
from typing import Optional, List, Dict


# ─── Option (e.g. Size: Small / Medium / Large) ──────────────
class MenuOption(BaseModel):
    name: str                          # "Milk" (canonical — used as the key in order customizations)
    name_ar: str = ""                  # "الحليب" (display only; falls back to name)
    choices: List[str]                 # ["Full Fat Milk", "Coconut Milk (+5 SAR)"]
    choices_ar: List[str] = []         # Arabic display labels, parallel to choices
    required: bool = False
    price_modifiers: Dict[str, float] = {}   # {"Coconut Milk (+5 SAR)": 5.0} — signed; negatives discount


# ─── Coffee Crop (origin the customer must pick) ─────────────
class Crop(BaseModel):
    name_en: str                       # "Brazilian"
    name_ar: str                       # "برازيلي"
    price_modifier: float = 0          # signed SAR added to the item price


# ─── Category ────────────────────────────────────────────────
class CategoryCreate(BaseModel):
    name_en: str               # "Coffee"
    name_ar: str               # "قهوة"
    icon: Optional[str] = None # emoji or icon name (optional)
    sort_order: int = 0


class CategoryUpdate(BaseModel):
    name_en: Optional[str] = None
    name_ar: Optional[str] = None
    icon: Optional[str] = None
    sort_order: Optional[int] = None


class CategoryResponse(BaseModel):
    id: str
    name_en: str
    name_ar: str
    icon: Optional[str] = None
    sort_order: int


# ─── Menu Item ───────────────────────────────────────────────
class MenuItemCreate(BaseModel):
    category_id: str
    name_en: str               # "Cappuccino"
    name_ar: str               # "كابتشينو"
    description_en: Optional[str] = ""
    description_ar: Optional[str] = ""
    crops: List[Crop] = []          # Coffee origins the customer chooses from
    price: float
    available: bool = True
    options: List[MenuOption] = []
    image_url: Optional[str] = None


class MenuItemUpdate(BaseModel):
    category_id: Optional[str] = None
    name_en: Optional[str] = None
    name_ar: Optional[str] = None
    description_en: Optional[str] = None
    description_ar: Optional[str] = None
    crops: Optional[List[Crop]] = None
    price: Optional[float] = None
    available: Optional[bool] = None
    options: Optional[List[MenuOption]] = None
    image_url: Optional[str] = None


class MenuItemResponse(BaseModel):
    id: str
    category_id: str
    name_en: str
    name_ar: str
    description_en: Optional[str] = ""
    description_ar: Optional[str] = ""
    crops: List[Crop] = []
    price: float
    available: bool
    options: List[MenuOption]
    image_url: Optional[str] = None
