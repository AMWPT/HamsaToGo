from fastapi import (
    APIRouter, Depends, File, HTTPException, Query, UploadFile, status,
)
from models.menu import (
    CategoryCreate, CategoryUpdate, CategoryResponse,
    MenuItemCreate, MenuItemUpdate, MenuItemResponse,
)
from services import firestore as db
from services import images
from dependencies import require_staff
from typing import List, Optional

router = APIRouter(prefix="/menu", tags=["Menu"])


# ═══════════════════════════════════════════════════════════════
#  CATEGORIES
# ═══════════════════════════════════════════════════════════════

@router.post("/categories", response_model=CategoryResponse, status_code=201,
             dependencies=[Depends(require_staff)])
def create_category(category: CategoryCreate):
    """Admin: Add a new category (e.g. Coffee, Food, Cold Drinks)."""
    data = db.create_category(category.model_dump())
    return CategoryResponse(**data)


@router.get("/categories")
def get_categories():
    """Get all categories ordered by sort_order."""
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


@router.patch("/categories/{category_id}", response_model=CategoryResponse,
              dependencies=[Depends(require_staff)])
def update_category(category_id: str, update: CategoryUpdate):
    """Admin: Update a category's name, icon, or sort order."""
    existing = db.get_category(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found.")
    updated = db.update_category(category_id, update.model_dump(exclude_none=True))
    return CategoryResponse(**updated)


@router.delete("/categories/{category_id}", status_code=204,
               dependencies=[Depends(require_staff)])
def delete_category(category_id: str):
    """Admin: Delete a category."""
    existing = db.get_category(category_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Category not found.")
    db.delete_category(category_id)


# ═══════════════════════════════════════════════════════════════
#  MENU ITEMS
# ═══════════════════════════════════════════════════════════════

@router.post("/items", response_model=MenuItemResponse, status_code=201,
             dependencies=[Depends(require_staff)])
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
                "name_ar": o.get("name_ar", ""),
                "choices": o.get("choices", []),
                "choices_ar": o.get("choices_ar", []),
                "required": o.get("required", False),
                "price_modifiers": o.get("price_modifiers", {}),
            }
            for o in raw_options
        ]
        clean_crops = [
            {
                "name_en": c.get("name_en", ""),
                "name_ar": c.get("name_ar", ""),
                "price_modifier": c.get("price_modifier", 0),
            }
            for c in i.get("crops", [])
        ]
        result.append({
            "id": i["id"],
            "category_id": i.get("category_id", ""),
            "name_en": i.get("name_en", ""),
            "name_ar": i.get("name_ar", ""),
            "description_en": i.get("description_en", ""),
            "description_ar": i.get("description_ar", ""),
            "crops": clean_crops,
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
            "name_ar": o.get("name_ar", ""),
            "choices": o.get("choices", []),
            "choices_ar": o.get("choices_ar", []),
            "required": o.get("required", False),
            "price_modifiers": o.get("price_modifiers", {}),
        }
        for o in raw_options
    ]
    clean_crops = [
        {
            "name_en": c.get("name_en", ""),
            "name_ar": c.get("name_ar", ""),
            "price_modifier": c.get("price_modifier", 0),
        }
        for c in i.get("crops", [])
    ]
    return {
        "id": i["id"],
        "category_id": i.get("category_id", ""),
        "name_en": i.get("name_en", ""),
        "name_ar": i.get("name_ar", ""),
        "description_en": i.get("description_en", ""),
        "description_ar": i.get("description_ar", ""),
        "crops": clean_crops,
        "price": i.get("price", 0.0),
        "available": i.get("available", True),
        "options": clean_options,
        "image_url": i.get("image_url"),
    }


@router.patch("/items/{item_id}", response_model=MenuItemResponse,
              dependencies=[Depends(require_staff)])
def update_menu_item(item_id: str, update: MenuItemUpdate):
    """Admin: Update a menu item (price, availability, names, etc.)."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    updated = db.update_menu_item(item_id, update.model_dump(exclude_none=True))
    return MenuItemResponse(**updated)


@router.patch("/items/{item_id}/toggle", response_model=MenuItemResponse,
              dependencies=[Depends(require_staff)])
def toggle_availability(item_id: str):
    """Admin: Quickly toggle an item's availability on/off."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    updated = db.update_menu_item(item_id, {"available": not existing["available"]})
    return MenuItemResponse(**updated)


@router.delete("/items/{item_id}", status_code=204,
               dependencies=[Depends(require_staff)])
def delete_menu_item(item_id: str):
    """Admin: Delete a menu item (and its photo, if any)."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    images.delete_by_url(existing.get("image_url") or "")
    db.delete_menu_item(item_id)


# ═══════════════════════════════════════════════════════════════
#  MENU ITEM IMAGES
# ═══════════════════════════════════════════════════════════════

MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB upload cap


@router.post("/items/{item_id}/image", response_model=MenuItemResponse,
             dependencies=[Depends(require_staff)])
async def upload_item_image(item_id: str, file: UploadFile = File(...)):
    """
    Admin: attach a photo to a menu item. Whatever the admin picks is
    normalized server-side to a consistent 1200x900 JPEG (center-cropped),
    so every item photo has identical dimensions in the app.
    """
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")

    raw = await file.read()
    if len(raw) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413,
                            detail="Image too large (max 10 MB).")
    try:
        url = images.process_and_upload(item_id, raw)
    except ValueError:
        raise HTTPException(status_code=400, detail="Not a valid image file.")

    # Clean up the previous image, then point the item at the new one.
    images.delete_by_url(existing.get("image_url") or "")
    updated = db.update_menu_item(item_id, {"image_url": url})
    return MenuItemResponse(**updated)


@router.delete("/items/{item_id}/image", response_model=MenuItemResponse,
               dependencies=[Depends(require_staff)])
def remove_item_image(item_id: str):
    """Admin: remove a menu item's photo."""
    existing = db.get_menu_item(item_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Menu item not found.")
    images.delete_by_url(existing.get("image_url") or "")
    updated = db.clear_menu_item_image(item_id)
    return MenuItemResponse(**updated)
