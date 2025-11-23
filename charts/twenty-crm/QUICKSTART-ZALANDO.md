# Quick Start: Zalando PostgreSQL Operator with Twenty CRM

This guide helps you quickly deploy Twenty CRM with the Zalando PostgreSQL Operator for a highly available PostgreSQL cluster.

## Prerequisites

1. **Kubernetes Cluster** (1.19+)
2. **Helm** (3.0+)
3. **Zalando PostgreSQL Operator** installed

### Install Zalando PostgreSQL Operator

If you haven't installed the Zalando PostgreSQL Operator yet:

```bash
# Install the operator
kubectl apply -k github.com/zalando/postgres-operator/manifests

# Verify the operator is running
kubectl get pods -n default | grep postgres-operator
```

For more installation options, see: https://postgres-operator.readthedocs.io/en/latest/quickstart/

## Quick Deploy

### 1. Add Helm Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Update Dependencies

```bash
cd charts/twenty-crm
helm dependency update
```

### 3. Deploy with Zalando PostgreSQL

Use the provided example values file:

```bash
helm install twenty-crm . -f values-zalando.yaml
```

Or create your own values file:

```yaml
# my-values.yaml
zalandoPostgresql:
  enabled: true
  teamId: "my-team"
  clusterName: "twenty-crm-db"
  numberOfInstances: 2
  version: "16"
  
postgres:
  enabled: false

server:
  env:
    serverUrl: "https://my-domain.com"

ingress:
  enabled: true
  hosts:
    - host: my-domain.com
      paths:
        - path: /
          pathType: Prefix
```

Then deploy:

```bash
helm install twenty-crm . -f my-values.yaml
```

## Verify Deployment

### Check PostgreSQL Cluster

```bash
# Check if the PostgreSQL cluster is created
kubectl get postgresql

# Check PostgreSQL pods
kubectl get pods -l application=spilo

# Check PostgreSQL cluster status
kubectl get postgresql twenty-crm-db -o yaml
```

### Check Database Secret

The operator automatically creates a secret for the postgres user:

```bash
# View the secret (credentials)
kubectl get secret postgres.twenty-crm-db.credentials.postgresql.acid.zalan.do

# Get the password
kubectl get secret postgres.twenty-crm-db.credentials.postgresql.acid.zalan.do \
  -o jsonpath='{.data.password}' | base64 -d
```

### Check Twenty CRM Deployment

```bash
# Check all pods
kubectl get pods

# Check server logs
kubectl logs -l app.kubernetes.io/component=server

# Check worker logs
kubectl logs -l app.kubernetes.io/component=worker
```

## Access Your Twenty CRM Instance

### Via Ingress (if configured)

```bash
# Your instance should be available at the configured host
curl https://my-domain.com
```

### Via Port Forward

```bash
# Port forward to the server service
kubectl port-forward svc/twenty-crm-server 3000:3000

# Access at http://localhost:3000
```

## Connection Pooler (Optional)

To enable PgBouncer connection pooler for better performance:

```yaml
zalandoPostgresql:
  enabled: true
  enableConnectionPooler: true
  connectionPooler:
    numberOfInstances: 2
    mode: "transaction"  # or "session" for applications that need session features
```

The pooler will be available at: `{clusterName}-pooler.{namespace}.svc.cluster.local:5432`

## High Availability Features

When `numberOfInstances: 2` or more:

- **Automatic Failover**: If the master fails, a replica is automatically promoted
- **Replication**: All instances maintain synchronized replicas
- **Load Balancing**: Read replicas can handle read-only queries
- **Backup & Recovery**: Operator handles WAL archiving and PITR

## Common Operations

### Scale PostgreSQL Cluster

```bash
# Edit the postgresql resource
kubectl edit postgresql twenty-crm-db

# Or update via Helm values and upgrade
helm upgrade twenty-crm . -f my-values.yaml
```

### View PostgreSQL Logs

```bash
# Master pod logs
kubectl logs -l application=spilo,spilo-role=master

# Replica pod logs
kubectl logs -l application=spilo,spilo-role=replica
```

### Connect to PostgreSQL Directly

```bash
# Get the password
export PGPASSWORD=$(kubectl get secret postgres.twenty-crm-db.credentials.postgresql.acid.zalan.do \
  -o jsonpath='{.data.password}' | base64 -d)

# Port forward to PostgreSQL
kubectl port-forward svc/twenty-crm-db 5432:5432

# Connect with psql
psql -h localhost -U postgres -d default
```

### Backup Database

The Zalando operator handles continuous WAL archiving. To take a manual backup:

```bash
# Create a logical backup (if logical backups are enabled in operator config)
kubectl exec -it twenty-crm-db-0 -- su postgres -c 'pg_dump default > /tmp/backup.sql'
kubectl cp twenty-crm-db-0:/tmp/backup.sql ./backup.sql
```

## Troubleshooting

### PostgreSQL Cluster Not Starting

```bash
# Check operator logs
kubectl logs -n default -l name=postgres-operator

# Check PostgreSQL pod events
kubectl describe pod twenty-crm-db-0
```

### Twenty CRM Can't Connect to Database

```bash
# Verify secret exists
kubectl get secret postgres.twenty-crm-db.credentials.postgresql.acid.zalan.do

# Check server environment variables
kubectl exec -it deployment/twenty-crm-server -- env | grep PG_DATABASE_URL

# Test database connectivity from server pod
kubectl exec -it deployment/twenty-crm-server -- curl -v telnet://twenty-crm-db:5432
```

### Connection Pooler Issues

```bash
# Check pooler deployment
kubectl get deployment twenty-crm-db-pooler

# Check pooler logs
kubectl logs -l application=db-connection-pooler
```

## Upgrade Guide

### Upgrade Twenty CRM

```bash
# Update the chart
helm upgrade twenty-crm . -f my-values.yaml

# Check rollout status
kubectl rollout status deployment/twenty-crm-server
kubectl rollout status deployment/twenty-crm-worker
```

### Upgrade PostgreSQL Version

Edit your values and change the version:

```yaml
zalandoPostgresql:
  version: "17"  # Upgrade from 16 to 17
```

Apply the upgrade:

```bash
helm upgrade twenty-crm . -f my-values.yaml
```

The operator will perform a rolling update of PostgreSQL instances.

## Production Checklist

- [ ] Zalando PostgreSQL Operator installed and configured
- [ ] At least 2 PostgreSQL instances for HA
- [ ] Connection pooler enabled
- [ ] Persistent volumes configured with appropriate storage class
- [ ] Resource limits set based on workload
- [ ] Backup strategy configured in operator
- [ ] Monitoring set up (Prometheus/Grafana)
- [ ] TLS enabled for ingress
- [ ] Secrets managed securely (not in values files)
- [ ] Network policies applied
- [ ] Resource quotas and limits configured

## Additional Resources

- [Zalando PostgreSQL Operator Documentation](https://postgres-operator.readthedocs.io/)
- [Zalando Operator GitHub](https://github.com/zalando/postgres-operator)
- [Twenty CRM Documentation](https://twenty.com/developers)
- [Helm Chart Repository](https://github.com/0xmemorygrinder/twenty-crm-helm)
