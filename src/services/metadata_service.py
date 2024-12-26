
import os
import aiohttp

async def get_metadata(document: dict) -> dict:
    try:
        get_metadata_api_url = os.getenv('TM_DOCS_METADATA_API_URL')
        async with aiohttp.ClientSession() as session:
            async with session.post(get_metadata_api_url, json=document) as response:
                metadata = await response.json()
        return metadata
    except Exception as e:
        raise Exception(f"Error al obtener la metadata del api de metadata: {str(e)}")