"""
Menu item images — every upload is normalized to one consistent size
(center-cropped 1200x900 JPEG) and served from a public Cloud Storage
bucket, so all item photos look uniform in the app regardless of what
the admin picks from their library.
"""

import io
import os
import time

from google.cloud import storage
from PIL import Image, ImageOps

BUCKET = os.getenv("MENU_IMAGES_BUCKET", "hamsacafe-1-menu-images")

# All menu images are normalized to this exact size (4:3).
TARGET_W, TARGET_H = 1200, 900
JPEG_QUALITY = 85

_client = None


def _get_bucket():
    global _client
    if _client is None:
        _client = storage.Client()
    return _client.bucket(BUCKET)


def process_and_upload(item_id: str, raw: bytes) -> str:
    """
    Validate and normalize an uploaded image, then upload it publicly.
    Returns the public URL. Raises ValueError if the bytes aren't a
    readable image.
    """
    try:
        img = Image.open(io.BytesIO(raw))
        img = ImageOps.exif_transpose(img)  # respect phone camera rotation
        img = img.convert("RGB")
    except Exception:
        raise ValueError("Not a valid image file.")

    # Scale + center-crop to exactly TARGET_W x TARGET_H.
    img = ImageOps.fit(img, (TARGET_W, TARGET_H), Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    buf.seek(0)

    # Unique name per upload so a replaced image isn't served stale from
    # browser caches that still hold the old file under the same name.
    blob_name = f"menu-items/{item_id}-{int(time.time())}.jpg"
    blob = _get_bucket().blob(blob_name)
    blob.upload_from_file(buf, content_type="image/jpeg")
    return f"https://storage.googleapis.com/{BUCKET}/{blob_name}"


def delete_by_url(url: str) -> None:
    """Best-effort removal of a previously uploaded image."""
    prefix = f"https://storage.googleapis.com/{BUCKET}/"
    if not url or not url.startswith(prefix):
        return
    try:
        _get_bucket().blob(url[len(prefix):]).delete()
    except Exception as e:
        print(f"[Images] Failed to delete old image {url}: {e}")
