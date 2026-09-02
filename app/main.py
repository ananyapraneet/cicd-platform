from fastapi import FastAPI

app = FastAPI(
    title="CI/CD Platform API",
    description="A simple application used to demonstrate a complete CI/CD pipeline.",
    version="1.0.0",
)


@app.get("/")
def root():
    return {"message": "CI/CD Platform API"}


@app.get("/health")
def health():
    return {"status": "healthy"}
