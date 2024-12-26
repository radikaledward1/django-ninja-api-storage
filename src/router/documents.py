import os
from ninja import File, Schema
from ninja import Router
from ninja.files import UploadedFile
from django.conf import settings
from services.documents_service import upload

router = Router()

class ErrorResponse(Schema):
    status: str
    message: str
    error: str

class SuccessResponse(Schema):
    status: str
    message: str
    document_id: str

@router.post("/upload", 
    response={200: SuccessResponse, 500: ErrorResponse})
async def upload_document(request, file: UploadedFile = File(...)):

    try:

        if not file.name.lower().endswith('.pdf'):
            return 500, {"status": "500", "message": "Solo se permiten archivos PDF", "error": "Formato de archivo inválido"}

        upload_results = await upload(file)
        
        return 200, {
            "status": "200",
            "message": "Archivo subido exitosamente",
            "document_id": upload_results["id"]
        }
    
    except Exception as e:
        return 500, {
            "status": "500",
            "message": "Error interno del servidor",
            "error": str(e)
        }