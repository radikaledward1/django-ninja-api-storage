import os
#from dotenv import load_dotenv

# Carga variables de entorno
#load_dotenv()

# Google Cloud Settings
GOOGLE_CLOUD_PROJECT_ID = os.getenv('GOOGLE_CLOUD_PROJECT_ID')
#GOOGLE_CLOUD_PROJECT_ID = 'tm-prj-dev'
GOOGLE_CLOUD_BUCKET_NAME = os.getenv('GOOGLE_CLOUD_BUCKET_NAME')
#GOOGLE_CLOUD_BUCKET_NAME = 'tm-dev-bucket'

SECRET_KEY = 'secret-key-1234567890-xyz'

WSGI_APPLICATION = 'core.wsgi.application'

ALLOWED_HOSTS = ['*']

DEBUG = True

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
            ],
        },
    },
]

INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
]

ROOT_URLCONF = 'router.urls'