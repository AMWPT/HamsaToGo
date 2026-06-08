from fastapi import APIRouter, HTTPException, status, Query
from models.menu import (
    CategoryCreate, CategoryUpdate, CategoryResponse,
    MenuItemCreate, MenuItemUpdate, MenuItemResponse,
)
from services import firestore as db
from typing import List, Optional

router = APIRouter(prefix="/menu", tags=["Menu"])


# ═══════════════════════════════════════════════════════════════
#  CATEGORIES
# ═══════════════════════════════════════════════════════════════

@router.post("/categories", response_model=CategoryResponse, status_code=201)
def create_category(category: CategoryCreate):
    """Admin: Add a new category (e.g. Coffee, Food, Cold Drinks)."""
    data = db.create_category(category.model_dump())
    return CategoryResponse(**data)


@router.get("/categories")
def get_categories():
    """Get all categories ordered by sort_order."""
    try:
        categories = db.get_all_categories()
        return [
            {
                "id": c["id"],
                "name_en": c.get("name_en", ""),
                "name_ar": c.get("name_ar", ""),
                "icon": c.get("icon"),
                "sort_order": c.get("sort_order", 0),
            }
            for c in categories
        ]
    except Exception as e:
        import traceback
        raise HTTPException(status_code=500, detail=traceback.format_exc())


@router.patch("/categories/{category_id}", response_model=CategoryResponse)
def update_category(category_id: str, update: CategoryUpdate):
    """Admin: Update a category's name, icon, or sort order."""
    existing = db.get_category(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found.")
    updated = db.update_category(category_id, update.model_dump(exclude_none=True))
    return CategoryResponse(**updated)


@router.delete("/categories/{category_id}", status_code=204)
def delete_category(category_id: str):
    """Admin: Delete a category."""
    existing = db.get_category(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found.")
    db.delete_category(category_id)


# ═══════════════════════════════════════════════════════════════
#  MENU ITEMS
# ═══════════════════════════════════════════════════════════════

@router.post("/items", response_model=MenuItemResponse, status_code=201)
def create_menu_item(item: MenuItemCreate):
    """Admin: Add a new menu item with English and Arabic names."""
    # Verify the category exists
    category = db.get_category(item.category_id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found.")

    data = db.create_menu_item(item.model_dump())
    return MenuItemResponse(**data)


@router.get("/items")
def get_menu_items(
    category_id: Optional[str] = Query(None, description="Filter by category"),
    available_only: bool = Query(True, description="Show only available items"),
):
    """
    Get menu items.
    - Customers: available_only=true (default)
    - Admin: available_only=false to see all items
    """
    if category_id:
        items = db.get_menu_items_by_category(category_id, available_only)
    else:
        items = db.get_all_menu_items(available_only)
    result = []
    for i in items:
        raw_options = i.get("options", [])
        clean_options = [
            {
                "name": o.get("name", ""),
                "choices": o.get("choices", []),
                "required": o.get("required", False),
                "price_modifiers": o.get("price_modifiers", {}),
            }
            for o in raw_options
        ]
        result.append({
            "id": i["id"],
            "category_id": i.get("category_id", ""),
            "name_en": i.get("name_en", ""),
            "name_ar": i.get("name_ar", ""),
            "description_en": i.get("description_en", ""),
            "description_ar": i.get("description_ar", ""),
            "price": i.get("price", 0.0),
            "available": i.get("available", True),
            "options": clean_options,
            "image_url": i.get("image_url"),
        })
    return result


@router.get("/items/{item_id}")
def get_menu_item(item_id: str):
    """Get a single menu item by ID."""
    i = db.get_menu_item(item_id)
    if not i:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    raw_options = i.get("options", [])
    clean_options = [
        {
            "name": o.get("name", ""),
            "choices": o.get("choices", []),
            "required": o.get("required", False),
            "price_modifiers": o.get("price_modifiers", {}),
        }
        for o in raw_options
    ]
    return {
        "id": i["id"],
        "category_id": i.get("category_id", ""),
        "name_en": i.get("name_en", ""),
        "name_ar": i.get("name_ar", ""),
        "description_en": i.get("description_en", ""),
        "description_ar": i.get("description_ar", ""),
        "price": i.get("price", 0.0),
        "available": i.get("available", True),
        "options": clean_options,
        "image_url": i.get("image_url"),
    }


@router.patch("/items/{item_id}", response_model=MenuItemResponse)
def update_menu_item(item_id: str, update: MenuItemUpdate):
    """Admin: Update a menu item (price, availability, names, etc.)."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    updated = db.update_menu_item(item_id, update.model_dump(exclude_none=True))
    return MenuItemResponse(**updated)


@router.patch("/items/{item_id}/toggle", response_model=MenuItemResponse)
def toggle_availability(item_id: str):
    """Admin: Quickly toggle an item's availability on/off."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    updated = db.update_menu_item(item_id, {"available": not existing["available"]})
    return MenuItemResponse(**updated)


@router.delete("/items/{item_id}", status_code=204)
def delete_menu_item(item_id: str):
    """Admin: Delete a menu item."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    db.delete_menu_item(item_id)
