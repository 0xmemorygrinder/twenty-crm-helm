# Publishing to GitHub Pages

This repository is configured to automatically publish the Helm chart to GitHub Pages using GitHub Actions.

## Setup Instructions

### 1. Enable GitHub Pages

1. Go to your GitHub repository settings: `https://github.com/0xmemorygrinder/twenty-crm-helm/settings/pages`
2. Under "Build and deployment":
   - **Source**: Select "GitHub Actions"
3. Save the settings

### 2. Push the Changes

Push the workflow file to your repository:

```bash
git add .github/workflows/release.yaml .helmignore README.md
git commit -m "Add GitHub Pages workflow for Helm chart repository"
git push origin main
```

(Replace `main` with `master` if that's your default branch)

### 3. Trigger the Workflow

The workflow will automatically run on push to the main/master branch. You can also trigger it manually:

1. Go to the Actions tab: `https://github.com/0xmemorygrinder/twenty-crm-helm/actions`
2. Select "Release Charts" workflow
3. Click "Run workflow"

### 4. Verify Publication

After the workflow completes successfully:

1. Your Helm chart will be available at: `https://0xmemorygrinder.github.io/twenty-crm-helm`
2. The `index.yaml` file will be at: `https://0xmemorygrinder.github.io/twenty-crm-helm/index.yaml`

## Using the Published Chart

### With Helm

```bash
# Add the repository
helm repo add twenty-crm https://0xmemorygrinder.github.io/twenty-crm-helm
helm repo update

# Search for charts
helm search repo twenty-crm

# Install the chart
helm install my-twenty twenty-crm/twenty-crm
```

### With Terraform (using Helm provider)

```hcl
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "twenty_crm" {
  name       = "twenty-crm"
  repository = "https://0xmemorygrinder.github.io/twenty-crm-helm"
  chart      = "twenty-crm"
  version    = "0.1.0"  # Optional: specify version

  namespace        = "twenty-crm"
  create_namespace = true

  # Override values
  values = [
    file("${path.module}/values.yaml")
  ]

  # Or use set blocks
  set {
    name  = "server.env.serverUrl"
    value = "https://crm.example.com:443"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }
}
```

### With Terraform (using local chart)

If you prefer to reference the chart directly from the repository:

```hcl
resource "helm_release" "twenty_crm" {
  name  = "twenty-crm"
  chart = "https://github.com/0xmemorygrinder/twenty-crm-helm/archive/refs/heads/main.tar.gz"

  namespace        = "twenty-crm"
  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]
}
```

## Updating the Chart

When you want to release a new version:

1. Update the version in `Chart.yaml`:
   ```yaml
   version: 0.2.0  # Increment the version
   ```

2. Commit and push the changes:
   ```bash
   git add Chart.yaml
   git commit -m "Bump chart version to 0.2.0"
   git push origin main
   ```

3. The workflow will automatically:
   - Package the new version
   - Update the Helm repository index
   - Publish to GitHub Pages

## Troubleshooting

### Workflow fails with permissions error

Make sure GitHub Actions has the necessary permissions:
1. Go to repository Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Save

### Chart not appearing

1. Check the Actions tab for any failed workflows
2. Verify GitHub Pages is enabled and set to "GitHub Actions" source
3. Wait a few minutes for GitHub Pages to deploy
4. Check `https://0xmemorygrinder.github.io/twenty-crm-helm/index.yaml` to verify the chart is indexed

### Dependencies not resolving

The workflow automatically adds the Bitnami repository and updates dependencies. If you add new dependencies:
1. Make sure they're listed in `Chart.yaml`
2. Update the workflow if using a repository other than Bitnami

## Additional Resources

- [Helm Chart Repository Guide](https://helm.sh/docs/topics/chart_repository/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
