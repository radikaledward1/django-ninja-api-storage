from ninja import Router
from services.usuarios_service import obtener_perfil

router = Router()

@router.post("/login")
def login(request):
    return {"message": "login exitoso"}

@router.post("/registro")
def registro(request):
    return {"message": "registro exitoso"}

@router.get("/perfil/{name}")
def perfil(request, name: str):
    return obtener_perfil(name) 