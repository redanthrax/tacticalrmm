DEBUG = True
DOCKER_BUILD = True
ALLOWED_HOSTS = ['api.local', '*']
ADMIN_URL = 'dev'
REDIS_HOST = 'redis'
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'tacticalrmm',
        'USER': 'dev',
        'PASSWORD': 'dev',
        'HOST': 'postgres',
        'PORT': '5432',
    }
}
SECRET_KEY = 'dev'
SWAGGER_ENABLED = True

CORS_ORIGIN_ALLOW_ALL = True
