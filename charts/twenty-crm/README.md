# Twenty CRM Helm Chart

This Helm chart deploys Twenty CRM on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)

## Installation

### Add the Helm repository
```bash
# Add this Helm chart repository
helm repo add twenty-crm https://0xmemorygrinder.github.io/twenty-crm-helm
helm repo update
```

### Install the chart
```bash
# Install with default values
helm install my-twenty twenty-crm/twenty-crm

# Install with custom values
helm install my-twenty twenty-crm/twenty-crm -f my-values.yaml

# Install a specific version
helm install my-twenty twenty-crm/twenty-crm --version 0.1.0
```

### Install from source
```bash
# Add Bitnami repository (for Redis subchart)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Download dependencies
helm dependency update .

# Install with default values
helm install my-twenty .

# Install with custom values
helm install my-twenty . -f my-values.yaml
```

## Configuration

### Database Configuration

The chart supports four database configurations:

1. **Zalando PostgreSQL Operator**: Uses Zalando PostgreSQL Operator to create a highly available PostgreSQL cluster
2. **Twenty-specific PostgreSQL**: Uses Twenty's custom PostgreSQL image with Spilo (single instance)
3. **External database**: Connect to an existing database
4. **~~Bitnami PostgreSQL subchart~~**: Removed in favor of Zalando operator

#### Using Zalando PostgreSQL Operator (Recommended for Production)

**Prerequisites**: The [Zalando PostgreSQL Operator](https://github.com/zalando/postgres-operator) must be installed in your cluster first.

```yaml
zalandoPostgresql:
  enabled: true
  teamId: "twenty-crm"
  clusterName: "twenty-crm-db"
  numberOfInstances: 2  # High availability with 2 replicas
  version: "16"
  database: "default"
  volume:
    size: 10Gi
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1024Mi
  # Optional: Enable connection pooler (PgBouncer)
  enableConnectionPooler: true
  connectionPooler:
    numberOfInstances: 2
    mode: "transaction"
```

The operator will automatically:
- Create a highly available PostgreSQL cluster
- Set up replication between instances
- Create necessary secrets for database credentials
- Provide automatic failover

#### Using Twenty's PostgreSQL Image

To use Twenty's PostgreSQL image (single instance, not HA):
```yaml
postgres:
  enabled: true
zalandoPostgresql:
  enabled: false
externalDatabase:
  enabled: false
```

#### Using an External Database

To use an external database:
```yaml
zalandoPostgresql:
  enabled: false
postgres:
  enabled: false
externalDatabase:
  enabled: true
  host: my-database.example.com
  port: 5432
  database: twentycrm
  username: myuser
  password: mypassword
```

### Redis Configuration

The chart supports two Redis configurations:

1. **Redis subchart (default)**: Uses Bitnami Redis chart
2. **External Redis**: Connect to an existing Redis instance

To use external Redis:
```yaml
redis:
  enabled: false
externalRedis:
  enabled: true
  host: my-redis.example.com
  port: 6379
  password: mypassword  # optional
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: crm.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: twenty-tls
      hosts:
        - crm.example.com
```

### Persistence

```yaml
persistence:
  server:
    enabled: true
    size: 10Gi
    storageClass: ""  # Use default storage class
  dockerData:
    enabled: true
    size: 10Gi
```

### Server Configuration

Configure the Twenty server deployment:

```yaml
server:
  enabled: true
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "1024Mi"
      cpu: "1000m"
  service:
    type: ClusterIP
    port: 3000
  env:
    nodePort: "3000"
    serverUrl: "https://crm.example.com:443"
    signInPrefilled: "false"
    storageType: "local"
    accessTokenExpiresIn: "7d"
    loginTokenExpiresIn: "1h"
```

### Worker Configuration

Configure the Twenty worker deployment:

```yaml
worker:
  enabled: true
  resources:
    requests:
      memory: "1024Mi"
      cpu: "250m"
    limits:
      memory: "2048Mi"
      cpu: "1000m"
  env:
    disableDbMigrations: "false"
```

### Application Secret

You can either provide the app secret directly or reference an existing secret:

```yaml
# Direct value (leave empty to auto-generate)
secrets:
  appSecret: "your-secret-key"

# Existing secret
secrets:
  existingSecret: "tokens"
  appSecretKey: "accessToken"
```

## Upgrading

```bash
# Upgrade from the repository
helm upgrade my-twenty twenty-crm/twenty-crm

# Upgrade from source
helm upgrade my-twenty .
```

## Uninstallation

```bash
helm uninstall my-twenty
```

## Values

### Core Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | 1 | Number of replicas |
| image.repository | string | twentycrm/twenty | Container image repository |
| image.pullPolicy | string | Always | Image pull policy |
| image.tag | string | latest | Container image tag |

### Server Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.enabled | bool | true | Enable Twenty server deployment |
| server.resources.requests.memory | string | 256Mi | Server memory request |
| server.resources.requests.cpu | string | 250m | Server CPU request |
| server.resources.limits.memory | string | 1024Mi | Server memory limit |
| server.resources.limits.cpu | string | 1000m | Server CPU limit |
| server.service.type | string | ClusterIP | Service type |
| server.service.port | int | 3000 | Service port |
| server.env.nodePort | string | 3000 | Node port |
| server.env.serverUrl | string | https://crm.example.com:443 | Server URL |
| server.env.signInPrefilled | string | false | Pre-fill sign-in form |
| server.env.storageType | string | local | Storage type |
| server.env.accessTokenExpiresIn | string | 7d | Access token expiration |
| server.env.loginTokenExpiresIn | string | 1h | Login token expiration |

### Worker Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| worker.enabled | bool | true | Enable Twenty worker deployment |
| worker.resources.requests.memory | string | 1024Mi | Worker memory request |
| worker.resources.requests.cpu | string | 250m | Worker CPU request |
| worker.resources.limits.memory | string | 2048Mi | Worker memory limit |
| worker.resources.limits.cpu | string | 1000m | Worker CPU limit |
| worker.env.disableDbMigrations | string | false | Disable database migrations |

### Database Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| zalandoPostgresql.enabled | bool | false | Enable Zalando PostgreSQL Operator cluster |
| zalandoPostgresql.teamId | string | twenty-crm | Team ID for the PostgreSQL cluster |
| zalandoPostgresql.clusterName | string | twenty-crm-db | Name of the PostgreSQL cluster |
| zalandoPostgresql.numberOfInstances | int | 2 | Number of PostgreSQL instances (replicas) |
| zalandoPostgresql.version | string | 16 | PostgreSQL version |
| zalandoPostgresql.database | string | default | Database name |
| zalandoPostgresql.volume.size | string | 10Gi | Volume size for PostgreSQL data |
| zalandoPostgresql.volume.storageClass | string | "" | Storage class (empty = default) |
| zalandoPostgresql.resources.requests.cpu | string | 100m | CPU request |
| zalandoPostgresql.resources.requests.memory | string | 256Mi | Memory request |
| zalandoPostgresql.resources.limits.cpu | string | 1000m | CPU limit |
| zalandoPostgresql.resources.limits.memory | string | 1024Mi | Memory limit |
| zalandoPostgresql.enableConnectionPooler | bool | false | Enable PgBouncer connection pooler |
| zalandoPostgresql.connectionPooler.numberOfInstances | int | 2 | Number of pooler instances |
| zalandoPostgresql.connectionPooler.mode | string | transaction | Pooler mode (session, transaction, statement) |
| postgres.enabled | bool | false | Enable Twenty-specific PostgreSQL |
| postgres.image.repository | string | twentycrm/twenty-postgres-spilo | Twenty PostgreSQL image |
| postgres.image.tag | string | latest | Twenty PostgreSQL image tag |
| externalDatabase.enabled | bool | false | Use external database |
| externalDatabase.host | string | "" | External database host |
| externalDatabase.port | int | 5432 | External database port |
| externalDatabase.database | string | default | External database name |
| externalDatabase.username | string | postgres | External database username |
| externalDatabase.password | string | postgres | External database password |
| externalDatabase.existingSecret | string | "" | Existing secret for database password |
| externalDatabase.existingSecretPasswordKey | string | "" | Key in existing secret for password |

### Redis Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| redis.enabled | bool | true | Enable Redis subchart |
| redis.architecture | string | standalone | Redis architecture |
| redis.auth.enabled | bool | false | Enable Redis authentication |
| redis.master.resources.requests.memory | string | 1024Mi | Redis memory request |
| redis.master.resources.requests.cpu | string | 250m | Redis CPU request |
| redis.master.resources.limits.memory | string | 2048Mi | Redis memory limit |
| redis.master.resources.limits.cpu | string | 500m | Redis CPU limit |
| externalRedis.enabled | bool | false | Use external Redis |
| externalRedis.host | string | "" | External Redis host |
| externalRedis.port | int | 6379 | External Redis port |
| externalRedis.password | string | "" | External Redis password |
| externalRedis.existingSecret | string | "" | Existing secret for Redis password |
| externalRedis.existingSecretPasswordKey | string | "" | Key in existing secret for password |

### Ingress Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.enabled | bool | true | Enable ingress |
| ingress.className | string | traefik | Ingress class name |
| ingress.annotations | object | {} | Ingress annotations |
| ingress.hosts | array | [] | Ingress hosts configuration |
| ingress.tls | array | [] | Ingress TLS configuration |

### Persistence Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| persistence.server.enabled | bool | true | Enable server persistence |
| persistence.server.size | string | 10Gi | Server volume size |
| persistence.server.storageClass | string | "" | Server storage class |
| persistence.server.accessMode | string | ReadWriteOnce | Server volume access mode |
| persistence.dockerData.enabled | bool | true | Enable docker data persistence |
| persistence.dockerData.size | string | 10Gi | Docker data volume size |
| persistence.dockerData.storageClass | string | "" | Docker data storage class |
| persistence.dockerData.accessMode | string | ReadWriteOnce | Docker data access mode |

### Secrets Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secrets.appSecret | string | "" | Application secret (auto-generated if empty) |
| secrets.existingSecret | string | "" | Use existing secret |
| secrets.appSecretKey | string | accessToken | Key in existing secret |