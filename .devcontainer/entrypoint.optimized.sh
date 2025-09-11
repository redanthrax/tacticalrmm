#!/usr/bin/env bash

set -e

: "${TRMM_USER:=tactical}"
: "${TRMM_PASS:=tactical}"
: "${POSTGRES_HOST:=tactical-postgres}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_USER:=tactical}"
: "${POSTGRES_PASS:=tactical}"
: "${POSTGRES_DB:=tacticalrmm}"
: "${MESH_SERVICE:=tactical-meshcentral}"
: "${MESH_WS_URL:=ws://${MESH_SERVICE}:4443}"
: "${MESH_USER:=meshcentral}"
: "${MESH_PASS:=meshcentralpass}"
: "${MESH_HOST:=tactical-meshcentral}"
: "${API_HOST:=tactical-backend}"
: "${REDIS_HOST:=tactical-redis}"
: "${API_PORT:=8000}"

: "${CERT_PRIV_PATH:=${TACTICAL_DIR}/certs/privkey.pem}"
: "${CERT_PUB_PATH:=${TACTICAL_DIR}/certs/fullchain.pem}"

# Add python venv to path
export PATH="${VIRTUAL_ENV}/bin:$PATH"

function check_tactical_ready {
  echo "Checking if tactical is ready..."
  local max_wait=300  # 5 minutes max wait
  local wait_time=0
  
  while [ $wait_time -lt $max_wait ] && [ ! -f "${TACTICAL_READY_FILE}" ]; do
    echo "waiting for init container to finish install or update... (${wait_time}s/${max_wait}s)"
    sleep 5
    wait_time=$((wait_time + 5))
  done
  
  if [ ! -f "${TACTICAL_READY_FILE}" ]; then
    echo "ERROR: Tactical ready file not found after ${max_wait}s. Init container may have failed."
    exit 1
  fi
  echo "Tactical is ready!"
}

function wait_for_service {
  local host=$1
  local port=$2
  local service_name=$3
  local max_wait=${4:-120}  # Default 2 minutes
  local wait_time=0
  
  echo "Waiting for ${service_name} at ${host}:${port}..."
  
  while [ $wait_time -lt $max_wait ]; do
    if timeout 1 bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null; then
      echo "${service_name} is ready!"
      return 0
    fi
    sleep 2
    wait_time=$((wait_time + 2))
  done
  
  echo "ERROR: ${service_name} at ${host}:${port} not ready after ${max_wait}s"
  return 1
}

function django_setup {
  # Wait for services in parallel using background jobs
  echo "Waiting for required services..."
  
  wait_for_service "${POSTGRES_HOST}" "${POSTGRES_PORT}" "PostgreSQL" &
  postgres_pid=$!
  
  wait_for_service "${MESH_SERVICE}" "4443" "MeshCentral" &
  mesh_pid=$!
  
  # Wait for both services
  if ! wait $postgres_pid; then
    echo "ERROR: PostgreSQL connection failed"
    exit 1
  fi
  
  if ! wait $mesh_pid; then
    echo "ERROR: MeshCentral connection failed"
    exit 1
  fi

  echo "All services are ready, setting up Django environment..."

  # Check if mesh token exists before reading
  local mesh_token_file="${TACTICAL_DIR}/tmp/mesh_token"
  if [ ! -f "$mesh_token_file" ]; then
    echo "ERROR: Mesh token file not found: $mesh_token_file"
    exit 1
  fi
  
  MESH_TOKEN="$(cat "$mesh_token_file")"
  
  if [ -z "$MESH_TOKEN" ]; then
    echo "ERROR: Mesh token is empty"
    exit 1
  fi

  DJANGO_SEKRET=$(openssl rand -base64 60 | tr -d '\n')

  BASE_DOMAIN=$(echo "import tldextract; no_fetch_extract = tldextract.TLDExtract(suffix_list_urls=()); extracted = no_fetch_extract('${API_HOST}'); print(f'{extracted.domain}.{extracted.suffix}')" | python)

  # Create local settings with optimized configuration
  localvars="$(
    cat <<EOF
SECRET_KEY = '${DJANGO_SEKRET}'

DEBUG = True

DOCKER_BUILD = True

SWAGGER_ENABLED = True

CERT_FILE = '${CERT_PUB_PATH}'
KEY_FILE = '${CERT_PRIV_PATH}'

SCRIPTS_DIR = '/community-scripts'

ADMIN_URL = 'admin/'

ALLOWED_HOSTS = ['${API_HOST}', '${APP_HOST}', '*']

CORS_ORIGIN_WHITELIST = ['https://${APP_HOST}']

SESSION_COOKIE_DOMAIN = '${BASE_DOMAIN}'
CSRF_COOKIE_DOMAIN = '${BASE_DOMAIN}'
CSRF_TRUSTED_ORIGINS = ['https://${API_HOST}', 'https://${APP_HOST}']

HEADLESS_FRONTEND_URLS = {'socialaccount_login_error': 'https://${APP_HOST}/account/provider/callback'}

# Database configuration with optimized settings
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${POSTGRES_DB}',
        'USER': '${POSTGRES_USER}',
        'PASSWORD': '${POSTGRES_PASS}',
        'HOST': '${POSTGRES_HOST}',
        'PORT': '${POSTGRES_PORT}',
        'CONN_MAX_AGE': 60,
        'OPTIONS': {
            'connect_timeout': 10,
        }
    },
    'reporting': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${POSTGRES_DB}',
        'USER': 'reporting_user',
        'PASSWORD': 'read_password',
        'HOST': '${POSTGRES_HOST}',
        'PORT': '${POSTGRES_PORT}',
        'OPTIONS': {
            'options': '-c default_transaction_read_only=on',
            'connect_timeout': 10,
        }
    }
}

MESH_USERNAME = '${MESH_USER}'
MESH_SITE = 'https://${MESH_HOST}'
MESH_TOKEN_KEY = '${MESH_TOKEN}'
REDIS_HOST = '${REDIS_HOST}'
MESH_WS_URL = '${MESH_WS_URL}'
ADMIN_ENABLED = True
TRMM_INSECURE = True
BETA_API_ENABLED = False

# Cache optimization
CACHES = {
    'default': {
        'BACKEND': 'tacticalrmm.cache.TacticalRedisCache',
        'LOCATION': f'redis://${REDIS_HOST}:6379',
        'OPTIONS': {
            'parser_class': 'redis.connection._HiredisParser',
            'pool_class': 'redis.BlockingConnectionPool',
            'db': '10',
            'connection_pool_kwargs': {'max_connections': 20},
        },
    }
}

# Logging optimization
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
        },
        'tacticalrmm': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
    },
}
EOF
  )"

  echo "${localvars}" > "${WORKSPACE_DIR}/api/tacticalrmm/tacticalrmm/local_settings.py"

  echo "Running Django management commands..."
  
  # Run commands with error checking and optimization
  "${VIRTUAL_ENV}/bin/python" manage.py pre_update_tasks || {
    echo "ERROR: pre_update_tasks failed"
    exit 1
  }
  
  "${VIRTUAL_ENV}/bin/python" manage.py migrate --no-input || {
    echo "ERROR: migrations failed"
    exit 1
  }
  
  # Run these in parallel where possible
  "${VIRTUAL_ENV}/bin/python" manage.py generate_json_schemas &
  schema_pid=$!
  
  "${VIRTUAL_ENV}/bin/python" manage.py collectstatic --no-input &
  static_pid=$!
  
  # Wait for parallel tasks
  wait $schema_pid && echo "JSON schemas generated"
  wait $static_pid && echo "Static files collected"
  
  # Continue with sequential tasks that depend on previous ones
  "${VIRTUAL_ENV}/bin/python" manage.py initial_db_setup
  "${VIRTUAL_ENV}/bin/python" manage.py initial_mesh_setup
  
  # These can also run in parallel
  "${VIRTUAL_ENV}/bin/python" manage.py load_chocos &
  chocos_pid=$!
  
  "${VIRTUAL_ENV}/bin/python" manage.py load_community_scripts &
  scripts_pid=$!
  
  wait $chocos_pid && echo "Chocolatey packages loaded"
  wait $scripts_pid && echo "Community scripts loaded"
  
  "${VIRTUAL_ENV}/bin/python" manage.py reload_nats
  "${VIRTUAL_ENV}/bin/python" manage.py create_natsapi_conf
  "${VIRTUAL_ENV}/bin/python" manage.py create_installer_user
  "${VIRTUAL_ENV}/bin/python" manage.py post_update_tasks

  # create super user if it doesn't exist
  echo "from accounts.models import User; User.objects.create_superuser('${TRMM_USER}', 'admin@example.com', '${TRMM_PASS}') if not User.objects.filter(username='${TRMM_USER}').exists() else print('User already exists')" | python manage.py shell
}

if [ "$1" = 'tactical-init-dev' ]; then
  echo "Starting tactical initialization..."
  
  # make directories if they don't exist
  mkdir -p "${TACTICAL_DIR}/tmp"

  test -f "${TACTICAL_READY_FILE}" && rm "${TACTICAL_READY_FILE}"

  # Create all directories at once
  mkdir -p \
    /meshcentral-data \
    "${TACTICAL_DIR}/tmp" \
    "${TACTICAL_DIR}/certs" \
    "${TACTICAL_DIR}/reporting" \
    "${TACTICAL_DIR}/reporting/assets" \
    /mongo/data/db \
    /redis/data \
    "${TACTICAL_DIR}/api/tacticalrmm/private/exe" \
    "${TACTICAL_DIR}/api/tacticalrmm/private/log"
  
  # Create files and set ownership
  touch /meshcentral-data/.initialized && chown -R 1000:1000 /meshcentral-data
  touch "${TACTICAL_DIR}/tmp/.initialized" && chown -R 1000:1000 "${TACTICAL_DIR}"
  touch "${TACTICAL_DIR}/certs/.initialized" && chown -R 1000:1000 "${TACTICAL_DIR}/certs"
  touch /mongo/data/db/.initialized && chown -R 1000:1000 /mongo/data/db
  touch /redis/data/.initialized && chown -R 1000:1000 /redis/data
  touch "${TACTICAL_DIR}/reporting/.initialized" && chown -R 1000:1000 "${TACTICAL_DIR}/reporting"
  touch "${TACTICAL_DIR}/api/tacticalrmm/private/log/django_debug.log"

  echo "Python virtual environment and Django setup..."
  django_setup

  # chown everything to tactical user
  chown -R "${TACTICAL_USER}":"${TACTICAL_USER}" "${WORKSPACE_DIR}"
  chown -R "${TACTICAL_USER}":"${TACTICAL_USER}" "${TACTICAL_DIR}"

  # create install ready file
  su -c "echo 'tactical-init' > ${TACTICAL_READY_FILE}" "${TACTICAL_USER}"
  echo "Tactical initialization completed successfully!"
fi

if [ "$1" = 'tactical-api' ]; then
  echo "Starting Tactical API server..."
  check_tactical_ready
  exec "${VIRTUAL_ENV}/bin/python" manage.py runserver 0.0.0.0:"${API_PORT}"
fi

if [ "$1" = 'tactical-celery-dev' ]; then
  echo "Starting Tactical Celery worker..."
  check_tactical_ready
  exec "${VIRTUAL_ENV}/bin/celery" -A tacticalrmm worker -l info --concurrency=4
fi

if [ "$1" = 'tactical-celerybeat-dev' ]; then
  echo "Starting Tactical Celery beat..."
  check_tactical_ready
  test -f "${WORKSPACE_DIR}/api/tacticalrmm/celerybeat.pid" && rm "${WORKSPACE_DIR}/api/tacticalrmm/celerybeat.pid"
  exec "${VIRTUAL_ENV}/bin/celery" -A tacticalrmm beat -l info
fi

if [ "$1" = 'tactical-websockets-dev' ]; then
  echo "Starting Tactical WebSockets server..."
  check_tactical_ready
  exec "${VIRTUAL_ENV}/bin/daphne" tacticalrmm.asgi:application --port 8383 -b 0.0.0.0
fi
