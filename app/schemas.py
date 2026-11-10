from pydantic import BaseModel, Field

class ItemCreate(BaseModel): 
    name: str = Field(min_length=1) 
    category: str = Field(min_length=1) 
    quantity: int = Field(ge=0) 
    price: float = Field(gt=0)

class ItemUpdate(BaseModel): 
    name: str = Field(min_length=1) 
    category: str = Field(min_length=1) 
    quantity: int = Field(ge=0) 
    price: float = Field(gt=0)

class ItemResponse(BaseModel): 
    id: int 
    name: str 
    category: str 
    quantity: int 
    price: float

    model_config = {"from_attributes": True}