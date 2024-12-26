import os
import json
from google.cloud import firestore

db = None

def get_firestore_client():
    global db

    try:
        if db is not None:
            return db
        
        credentials = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        #credentials = '/Users/ogonzalez/Documents/O2D/documents/service-accounts/transmute/main-tm-dev-sa.json'

        if not credentials:
            raise Exception("Firestore client: No se encontró el archivo de credenciales de servicio")
        
        try:
            # Configuración del cliente con opciones específicas como la base de datos, etc
            #client_options = {
            #    'database_id': 'tu-base-de-datos',  # Nombre de tu base de datos
            #}
    
            credentials_info = json.loads(credentials)
            db = firestore.Client.from_service_account_info(credentials_info)

        except Exception as e:
            raise Exception(f"Firestore client: Error al cargar las credenciales de servicio: {str(e)}")

        print("Firestore client: Conexión a Firestore establecida.")

        return db
    
    except Exception as e:
        raise Exception(f"Firestore client: Error al conectar a Firestore: {str(e)}")
        return None