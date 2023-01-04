DEBUG = False
DOCKER_BUILD = True
ALLOWED_HOSTS = ['dev.local', '*']
CORS_ORIGIN_ALLOW_ALL = True
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'tactical',
        'USER': 'dev',
        'PASSWORD': 'dev',
        'HOST': 'postgres',
        'PORT': '5432',
    }
}

REDIS_HOST    = 'redis'
ADMIN_ENABLED = False
