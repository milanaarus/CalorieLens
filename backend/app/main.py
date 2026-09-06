from fastapi import FastAPI


app = FastAPI(
    title="Calorie AI API",
    description="API для оценки калорийности блюд по фото",
    version="0.1.0"
)


@app.get("/")
async def root():
    return {"message": "Calorie AI API is running!"}


@app.get("/health")
async def health_check():
    return {"status": "ok"}
