#!/bin/zsh

set -e  # Exit immediately if a command exits with a non-zero status.

# Variables para pintar el texto de color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Variables específicas del proyecto
PROJECT_ID="tm-prj-dev"
IMAGE_NAME="api-tm-docs-storage"
REGION="us-central1"
REPOSITORY="api-tm-docs-storage"  # Nombre del repositorio en Artifact Registry
TAG="dev"
YOUR_VPC_CONNECTOR_NAME=""

# Cambiando al Project ID
gcloud config set project ${PROJECT_ID}

# Construye la URL completa de la imagen
IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}"

echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Iniciando despliegue para el proyecto $PROJECT_ID ${NC}"

# Verifica que gcloud esté instalado
if ! command -v gcloud &> /dev/null
then
    echo -e "${RED} ERROR: ${NC} => gcloud no está instalado. Por favor, instala Google Cloud SDK."
    exit 1
fi

# Verifica que docker esté instalado
if ! command -v docker &> /dev/null
then
    echo -e "${RED} ERROR: ${NC} => Docker no está instalado. Por favor, instala Docker."
    exit 1
fi

# Verifica que el Dockerfile existe
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED} ERROR: ${NC} => Error: No se encontró el archivo Dockerfile en el directorio actual."
    echo " =>=> Directorio actual: $(pwd)"
    exit 1
fi

# Asegúrate de que estamos autenticados con GCP
gcloud auth print-access-token &> /dev/null || (echo -e "${RED} ERROR: ${NC} => No estás autenticado con GCP. Ejecuta 'gcloud auth login'" && exit 1)

# Habilita las APIs necesarias
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Habilitando APIs necesarias... ${NC}"
gcloud services enable artifactregistry.googleapis.com run.googleapis.com

# Crea el repositorio en Artifact Registry si no existe
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Verificando/Creando repositorio en Artifact Registry... ${NC}"
gcloud artifacts repositories describe $REPOSITORY --location=$REGION --project=$PROJECT_ID > /dev/null 2>&1 || \
gcloud artifacts repositories create $REPOSITORY --repository-format=docker --location=$REGION --project=$PROJECT_ID

# Configura Docker para usar las credenciales de gcloud con Artifact Registry
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Configurando Docker para usar credenciales de gcloud con Artifact Registry... ${NC}"
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Construye la imagen Docker
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Construyendo la imagen Docker... ${NC}"
docker build -t $IMAGE_URL:${TAG} . --no-cache --platform linux/amd64 || (echo -e "${RED} ERROR: ${NC} => No se pudo construir la imagen Docker" && exit 1)

# Sube la imagen a Artifact Registry
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Subiendo la imagen a Artifact Registry... ${NC}"
docker push ${IMAGE_URL}:${TAG} || (echo -e "${RED} ERROR: ${NC} => No se pudo subir la imagen a Artifact Registry" && exit 1)

# Verifica que la imagen se haya subido correctamente
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Verificando la imagen en Artifact Registry... ${NC}"
#gcloud artifacts docker images list $IMAGE_URL:${TAG} --format='value(IMAGE)' | grep -q ${IMAGE_NAME} || (echo "No se pudo verificar la imagen en Artifact Registry" && exit 1)
gcloud artifacts docker images list ${IMAGE_URL}:${TAG} --format='value(IMAGE)' || (echo -e "${RED} ERROR:${NC} No se pudo verificar la imagen en Artifact Registry" && exit 1)

# Despliega en Cloud Run
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Desplegando en Cloud Run..."
gcloud run deploy ${IMAGE_NAME} \
  --image ${IMAGE_URL}:${TAG} \
  --platform managed \
  --region ${REGION} \
  --timeout=300 \
  --ingress all \
  --allow-unauthenticated || (echo -e "${RED} ERROR:${NC} No se pudo desplegar en Cloud Run" && exit 1)

# Configura los permisos IAM
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Configurando permisos IAM... ${NC}"
if ! gcloud run services add-iam-policy-binding ${IMAGE_NAME} \
  --region=${REGION} \
  --member=allUsers \
  --role=roles/run.invoker; then
    echo -e "${YELLOW}*** ADVERTENCIA: No se pudieron configurar los permisos IAM automáticamente."
    echo -e "*** Es posible que necesites configurar los permisos manualmente o contactar a tu administrador de GCP."
    echo -e "*** Comando para configurar manualmente: ${NC}"
    echo -e "*** gcloud run services add-iam-policy-binding ${IMAGE_NAME} --region=${REGION} --member=allUsers --role=roles/run.invoker"
fi

# Configura el acceso interno para Cloud Run
echo
echo -e "${BOLD}${GREEN} => Configurando acceso interno para Cloud Run... ${NC}"
if ! gcloud run services update ${IMAGE_NAME} \
  --region=${REGION} \
  --ingress=all \
  --project=${PROJECT_ID}; then
    echo -e "${YELLOW}*** ADVERTENCIA: No se pudo configurar el acceso interno automáticamente."
    echo -e "*** Es posible que necesites configurar el acceso manualmente o contactar a tu administrador de GCP."
    echo -e "*** Comando para configurar manualmente: ${NC}"
    echo -e "*** gcloud run services update ${IMAGE_NAME} --region=${REGION} --ingress=all --project=${PROJECT_ID}"
fi

# Configurar la política de VPC connector si se proporciona un nombre
if [ ! -z "$VPC_CONNECTOR_NAME" ]; then
    echo
    echo -e "${BOLD}${GREEN} => Configurando VPC connector... ${NC}"
    if ! gcloud run services update ${IMAGE_NAME} \
      --region=${REGION} \
      --vpc-connector=${VPC_CONNECTOR_NAME} \
      --project=${PROJECT_ID}; then
        echo -e "${YELLOW}*** ADVERTENCIA: No se pudo configurar el VPC connector automáticamente."
        echo -e "*** Asegúrate de que el VPC connector '${VPC_CONNECTOR_NAME}' existe y tienes los permisos necesarios."
        echo -e "*** Comando para configurar manualmente: ${NC}"
        echo -e "*** gcloud run services update ${IMAGE_NAME} --region=${REGION} --vpc-connector=${VPC_CONNECTOR_NAME} --project=${PROJECT_ID}"
    fi
else
    echo
    echo -e "${BOLD}${GREEN} => No se especificó VPC connector. Omitiendo este paso. ${NC}"
fi


echo
echo -e "${BOLD}${GREEN} => Configuración completada. ${NC}"

# Muestra la URL del servicio
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Despliegue completado. URL del servicio: ${NC}"
gcloud run services describe ${IMAGE_NAME} --platform managed --region ${REGION} --format='value(status.url)'

# Elimina la imagen Docker local
echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Eliminando la imagen Docker local... ${NC}"
if docker image rm ${IMAGE_URL}:${TAG}; then
    echo -e "${GREEN}Imagen Docker local eliminada con éxito.${NC}"
else
    echo -e "${YELLOW}*** ADVERTENCIA: No se pudo eliminar la imagen Docker local."
    echo -e "*** Es posible que la imagen ya haya sido eliminada o que no exista localmente.${NC}"
fi

echo # Linea en blanco intencionalmente
echo -e "${BOLD}${GREEN} => Proceso de despliegue y limpieza completado. ${NC}"

# # Muestra los logs recientes del servicio
# echo "Mostrando logs recientes del servicio..."
# gcloud run services logs read ${IMAGE_NAME} --platform managed --region ${REGION} --limit 50