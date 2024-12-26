from ninja import NinjaAPI
from . import usuarios
from . import documents

api = NinjaAPI()

# Registrar los routers
api.add_router("/usuarios/", usuarios.router) 
api.add_router("/documents/", documents.router)