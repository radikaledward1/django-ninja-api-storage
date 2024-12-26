from datetime import timedelta
import os
import json
from google.cloud import storage
from django.conf import settings
import requests
from database.firestore_client import get_firestore_client
from services.metadata_service import get_metadata

# El metodo upload debera recibir el documento (file), el shipment_id (id), y el tipo de documento (type), esto para poder nombrar el folder en el bucket, 
# asi como para utilizarlo en otras propiedades al salvar en firestore, el tipo de documento puede ser: Invoice, PackingList, etc

# Las variables de ambiente deben de ser agregadas al Secret Manager de Google Cloud y luego deben de ser configuradas al Cloud Run


async def upload(file) -> dict:
    #return {"url": "https://example.com/document.pdf"}

    #TODO: Retrieve credentials from env or maybe a class can be created to handle this

    credentials = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    print(credentials)
    #credentials = '/Users/ogonzalez/Documents/O2D/documents/service-accounts/transmute/main-tm-dev-sa.json'
    #logger.info("Credentials path: " + credentials)    

    bucket_name = os.getenv('GOOGLE_CLOUD_BUCKET_NAME')
    print(bucket_name)
    #bucket_name = 'tm-dev-bucket'
    #logger.info("Bucket name: " + bucket_name)

    #if not os.path.exists(credentials):
    #    raise Exception("No se encontró el archivo de credenciales de servicio")

    if not credentials:
        raise Exception("No se encontraron las credenciales de servicio")

    try:
        credentials_info = json.loads(credentials)
        client = storage.Client.from_service_account_info(credentials_info)
    except Exception as e:
        raise Exception(f"Error al cargar las credenciales de servicio: {str(e)}")

    try:
        
        bucket = client.bucket(bucket_name)
        if not bucket.exists():
            raise Exception(f"El bucket {bucket_name} no existe")

        blob = bucket.blob(f"pdfs/{file.name}")
        blob.upload_from_file(file)
        
        # URI de Google Cloud Storage
        gcp_uri = f"gs://{bucket_name}/{blob.name}"
        
        #blob.make_public()
        
         # URL firmada
        signed_gcp_url = blob.generate_signed_url(
            # La URL será válida por 7 días, seria bueno meterla a una variable de ambiente
            expiration=timedelta(days=7)
        )

        document = {
            "gcp_uri": gcp_uri,
            "signed_gcp_url": signed_gcp_url
        }

        try:
            metadata = await get_metadata(document)
            document["document_metadata"] = metadata
        except Exception as e:
            raise Exception(f"Error al obtener la metadata: {str(e)}")
        
        document_id = save_document(document)

        return document_id

    except Exception as e:
        raise Exception(f"Error al subir el archivo: {str(e)}")
    
def save_document(document: dict) -> dict:
    db = get_firestore_client()

    if db is None:
        raise Exception("El cliente de Firestore no se encuentra inicializado")
    
    try:
        doc_ref = db.collection('shipments').add(document)
        return {"id": doc_ref[1].id}
    except Exception as e:
        raise Exception(f"Error al guardar el documento en Firestore: {str(e)}")