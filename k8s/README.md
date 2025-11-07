# Kubernetes Deployment for Claude Skills MCP Backend

This directory contains Kubernetes manifests for deploying the Claude Skills MCP Backend.

## Files

- `deployment.yaml` - Complete Kubernetes deployment including:
  - ConfigMap for backend configuration
  - Secret for sensitive data (GitHub token)
  - Deployment for the backend pods
  - Service to expose the backend
  - Optional PersistentVolumeClaim for local skills (commented out)
- `route.yaml` - OpenShift Route for external access (OpenShift only)

## Prerequisites

1. A Kubernetes cluster (1.20+)
2. Container image built and available in your registry
3. kubectl configured to access your cluster

## Quick Start

### 1. Build and Push Container Image

First, build and push your container image to a registry accessible by your cluster:

```bash
# Build the image
docker build -f Containerfile -t your-registry/claude-skills-mcp-backend:latest .

# Push to registry
docker push your-registry/claude-skills-mcp-backend:latest
```

### 2. Update Image Reference

Edit `deployment.yaml` and update the image reference in the Deployment:

```yaml
containers:
- name: backend
  image: your-registry/claude-skills-mcp-backend:latest  # Update this
```

### 3. Customize Configuration

Edit the ConfigMap in `deployment.yaml` to customize:
- Skill sources (GitHub repos, local paths)
- Embedding model
- Content limits
- Auto-update settings

### 4. Optional: Add GitHub Token

If you want higher GitHub API rate limits (5000 req/hr vs 60 req/hr):

1. Create a GitHub Personal Access Token
2. Uncomment the `github-token` field in the Secret
3. Set the token value
4. Uncomment the `GITHUB_API_TOKEN` env var in the Deployment

### 5. Deploy

```bash
# Apply all resources
kubectl apply -f deployment.yaml

# Check deployment status
kubectl get deployment claude-skills-mcp-backend

# Check pods
kubectl get pods -l app=claude-skills-mcp-backend

# View logs
kubectl logs -l app=claude-skills-mcp-backend -f

# Check service
kubectl get service claude-skills-mcp-backend

# For OpenShift: Apply the route for external access
kubectl apply -f route.yaml
kubectl get route claude-skills-mcp-backend
```

## Configuration

### Resource Limits

The deployment includes resource requests and limits:
- **Requests**: 512Mi memory, 250m CPU
- **Limits**: 2Gi memory, 2000m CPU

Adjust these based on your cluster capacity and expected load.

### Health Checks

- **Liveness Probe**: Checks `/health` every 30s, starts after 90s
- **Readiness Probe**: Checks `/health` every 10s, starts after 30s

The longer initial delay accounts for:
- Container startup time
- Model download on first run (~60-180s)
- Initial skill loading

### Storage

The `local_skills` directory uses an `emptyDir` volume (ephemeral). For persistent storage of local skills:

1. Uncomment the PersistentVolumeClaim section in `deployment.yaml`
2. Update the `local-skills` volume mount to use the PVC
3. Adjust storage size as needed

## Accessing the Backend

### Within Cluster

The Service exposes the backend at:
```
http://claude-skills-mcp-backend:8765
```

### External Access

For external access, you can:

1. **Use OpenShift Route** (OpenShift only, recommended):
```bash
# Apply the route
kubectl apply -f route.yaml

# Get the route URL
kubectl get route claude-skills-mcp-backend
```

The route will automatically generate a hostname. To use a custom hostname, edit `route.yaml` and add:
```yaml
spec:
  host: your-custom-hostname.example.com
```

For TLS termination, uncomment and configure the `tls` section in `route.yaml`.

2. **Use NodePort** (change Service type):
```yaml
spec:
  type: NodePort
```

3. **Use LoadBalancer** (if supported):
```yaml
spec:
  type: LoadBalancer
```

4. **Use Ingress** (create your own Ingress resource):
   - Create an Ingress resource that points to the `claude-skills-mcp-backend` service on port 8765
   - Configure TLS and routing based on your ingress controller

## Monitoring

### Check Health

```bash
# Port forward to access health endpoint
kubectl port-forward svc/claude-skills-mcp-backend 8765:8765

# In another terminal
curl http://localhost:8765/health
```

### View Logs

```bash
# Follow logs
kubectl logs -f deployment/claude-skills-mcp-backend

# View logs from specific pod
kubectl logs <pod-name>
```

### Check Resource Usage

```bash
# View resource usage
kubectl top pod -l app=claude-skills-mcp-backend
```

## Troubleshooting

### Pod Not Starting

1. Check pod status:
```bash
kubectl describe pod -l app=claude-skills-mcp-backend
```

2. Check logs:
```bash
kubectl logs -l app=claude-skills-mcp-backend
```

3. Verify image is accessible:
```bash
kubectl describe pod <pod-name> | grep -i image
```

### Health Check Failing

- Initial startup can take 60-180 seconds (model download)
- Increase `initialDelaySeconds` if needed
- Check logs for errors

### Out of Memory

- Increase memory limits in Deployment
- Consider reducing `max_skill_content_chars` in config
- Reduce number of skill sources

### GitHub API Rate Limits

- Add GitHub token to Secret (see "Optional: Add GitHub Token" above)
- Monitor API usage via `/health` endpoint

## Scaling

To scale the deployment:

```bash
# Scale to 3 replicas
kubectl scale deployment claude-skills-mcp-backend --replicas=3
```

**Note**: Each replica will independently:
- Download models (~150-200 MB)
- Load and index skills
- Use memory (~500 MB per replica)

Consider using a single replica for cost efficiency.

## Updates

To update the deployment:

```bash
# Update image
kubectl set image deployment/claude-skills-mcp-backend \
  backend=your-registry/claude-skills-mcp-backend:v1.1.0

# Or apply updated deployment.yaml
kubectl apply -f deployment.yaml

# Watch rollout
kubectl rollout status deployment/claude-skills-mcp-backend
```

## Cleanup

To remove all resources:

```bash
kubectl delete -f deployment.yaml
```

