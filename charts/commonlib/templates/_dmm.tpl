{{/* vim: set filetype=mustache: */}}
{{/*
Sets environment variables from configMap. Name of this configMap is hardcoded
to "domino-dmm-configmap".
*/}}
{{- define "common.environment.from.configmap" -}}
- configMapRef:
    name: domino-dmm-configmap
{{- end -}}

{{/*
Sets Mongo DB secrets from Secrets.
*/}}
{{- define "common.mongodb.credentials" -}}
- name: MONGO_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_password
- name: MONGO_DB_URL
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_url
- name: MONGO_DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_username
- name: MONGO_DB_DATABASE
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_database
- name: MONGO_DB_AUTHENTICATION_SOURCE
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_authentication_source
- name: MONGO_DB_HOST
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_host
- name: MONGO_DB_PORT
  valueFrom:
    secretKeyRef:
      name: domino-dmm-mongodb
      key: mongo_db_port
{{- end -}}

{{/*
Sets Redis secret parameters.
*/}}
{{- define "common.redis.secrets" -}}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: redis-ha
      key: auth
{{- end -}}

{{/*
Sets Plier secret parameters.
*/}}
{{- define "common.plier.secrets" -}}
- name: PLIER_SECRET
  valueFrom:
    secretKeyRef:
      name: domino-dmm-plier
      key: plier_secret
{{- end -}}

+{{/*
Sets Salt secrets from Secrets.
*/}}
{{- define "common.salt.secrets" -}}
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: domino-dmm-salt
      key: secret_key
- name: SECRET_KEY_SALT
  valueFrom:
    secretKeyRef:
      name: domino-dmm-salt
      key: secret_key_salt
{{- end -}}
