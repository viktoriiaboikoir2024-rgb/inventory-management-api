from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, status, Query
from sqlalchemy.orm import Session

from app.cache import cache_get, cache_set, cache_delete
from app.database import engine, Base, get_db
from app import models, schemas


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Inventory Management API",
    description="REST API for managing warehouse inventory",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/")
def root():
    return {"message": "Inventory Management API is running"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/items", response_model=list[schemas.ItemResponse])
def get_items(
    limit: int = Query(100, ge=1, le=1000),
    category: str | None = None,
    db: Session = Depends(get_db),
):
    key = f"items:list:{category or 'all'}:{limit}"
    cached = cache_get(key)
    if cached is not None:
        return cached

    query = db.query(models.Item)
    if category:
        query = query.filter(models.Item.category == category)
    items = query.order_by(models.Item.id).limit(limit).all()

    data = [
        schemas.ItemResponse.model_validate(i, from_attributes=True).model_dump(mode="json")
        for i in items
    ]
    cache_set(key, data)
    return data


@app.get("/items/{item_id}", response_model=schemas.ItemResponse)
def get_item(item_id: int, db: Session = Depends(get_db)):
    key = f"items:{item_id}"
    cached = cache_get(key)
    if cached is not None:
        return cached

    item = db.query(models.Item).filter(
        models.Item.id == item_id
    ).first()

    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    data = schemas.ItemResponse.model_validate(item, from_attributes=True).model_dump(mode="json")
    cache_set(key, data)
    return data


@app.post(
    "/items",
    response_model=schemas.ItemResponse,
    status_code=status.HTTP_201_CREATED
)
def create_item(
    item: schemas.ItemCreate,
    db: Session = Depends(get_db)
):
    db_item = models.Item(**item.model_dump())

    db.add(db_item)
    db.commit()
    db.refresh(db_item)

    return db_item


@app.put("/items/{item_id}", response_model=schemas.ItemResponse)
def update_item(
    item_id: int,
    item: schemas.ItemUpdate,
    db: Session = Depends(get_db)
):
    db_item = db.query(models.Item).filter(
        models.Item.id == item_id
    ).first()

    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    for key, value in item.model_dump().items():
        setattr(db_item, key, value)

    db.commit()
    db.refresh(db_item)

    cache_delete(f"items:{item_id}")

    return db_item


@app.delete("/items/{item_id}")
def delete_item(item_id: int, db: Session = Depends(get_db)):
    db_item = db.query(models.Item).filter(
        models.Item.id == item_id
    ).first()

    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")

    db.delete(db_item)
    db.commit()

    cache_delete(f"items:{item_id}")

    return {
        "message": "Item deleted successfully",
        "deleted_item": item_id
    }