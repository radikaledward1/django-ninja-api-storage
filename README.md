# TM Docs Storage API
Python API to upload documents to Google Cloud Storage, get the metadata from the metadata API and save the Documents information in Firestore.

### Requirements

- Python 3.10
- Django 5.1.4
- Django Ninja 1.3.0
- Django Extensions 3.2.3
- Google Cloud Storage 2.19.0
- Google Cloud Firestore 2.19.0
- Python Dotenv 1.0.1
- Aiohttp 3.8.6

### Local Environment

```bash
python -m venv .enviroment
source .enviroment/bin/activate
```

### Set the project requirements

```bash
pip freeze > requirements.txt
```

### Install dependencies
```bash
pip install -r requirements.txt
```

### Run

In src directory run:
```bash
python manage.py runserver
```

### Open API
When you run the server, you can access the API documentation at:
```bash
http://127.0.0.1:8000/api/docs
```