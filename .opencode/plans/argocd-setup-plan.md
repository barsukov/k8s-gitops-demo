# ArgoCD GitOps Setup - Implementation Plan

> **Status**: DRAFT - Pending Review  
> **Location**: `/Users/wowa/work/test-argocd/`  
> **Source**: `argocd.md`

---

## Overview

Create a complete local Kubernetes GitOps environment with ArgoCD for multi-environment deployments and feature branch previews.

### Configuration Decisions

| Setting | Value |
|---------|-------|
| GitHub Username | `barsukov` |
| Git Repo URL | `https://github.com/barsukov/k8s-gitops-demo.git` |
| Initial Scope | Dev apps only (3 individual Applications) |
| ApplicationSet | Include in repo, apply manually later |
| Git Init | Deferred to user |

---

## File Structure (35 files)

```
/Users/wowa/work/test-argocd/
│
├── apps/
│   ├── app1-frontend/
│   │   ├── base/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── configmap.yaml
│   │   │   └── kustomization.yaml
│   │   └── overlays/
│   │       ├── dev/
│   │       │   └── kustomization.yaml
│   │       ├── staging/
│   │       │   └── kustomization.yaml
│   │       └── production/
│   │           ├── kustomization.yaml
│   │           ├── hpa.yaml
│   │           └── pdb.yaml
│   │
│   ├── app2-api/
│   │   ├── base/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── configmap.yaml
│   │   │   └── kustomization.yaml
│   │   └── overlays/
│   │       ├── dev/
│   │       │   └── kustomization.yaml
│   │       ├── staging/
│   │       │   └── kustomization.yaml
│   │       └── production/
│   │           └── kustomization.yaml
│   │
│   └── app3-worker/
│       ├── base/
│       │   ├── deployment.yaml
│       │   ├── configmap.yaml
│       │   └── kustomization.yaml
│       └── overlays/
│           ├── dev/
│           │   └── kustomization.yaml
│           ├── staging/
│           │   └── kustomization.yaml
│           └── production/
│               └── kustomization.yaml
│
├── argocd/
│   ├── projects/
│   │   ├── dev-project.yaml
│   │   ├── staging-project.yaml
│   │   └── prod-project.yaml
│   ├── applications/
│   │   └── dev/
│   │       ├── app1-dev.yaml
│   │       ├── app2-dev.yaml
│   │       └── app3-dev.yaml
│   └── applicationsets/
│       └── apps-matrix.yaml
│
├── scripts/
│   ├── 00-run-all.sh
│   ├── 01-setup-cluster.sh
│   ├── 02-install-argocd.sh
│   ├── 03-configure-argocd.sh
│   ├── 04-deploy-apps.sh
│   ├── 05-create-preview.sh
│   ├── 06-cleanup-preview.sh
│   └── 99-cleanup-all.sh
│
├── local-dev/
│   ├── kind-config.yaml
│   └── port-forwards.sh
│
├── .gitignore
└── README.md
```

---

## File Count by Category

| Category | Files | Description |
|----------|-------|-------------|
| app1-frontend | 8 | Base (4) + Overlays (4 including HPA, PDB) |
| app2-api | 7 | Base (4) + Overlays (3) |
| app3-worker | 6 | Base (3) + Overlays (3) |
| argocd | 7 | Projects (3) + Apps (3) + ApplicationSet (1) |
| scripts | 8 | Setup, install, deploy, preview, cleanup |
| local-dev | 2 | Kind config + port-forwards |
| root | 2 | .gitignore + README.md |
| **Total** | **35** | |

---

## Fixes to Apply

### 1. Placeholder Replacement

| File | Change |
|------|--------|
| `argocd/applications/dev/app1-dev.yaml` | `YOUR-USERNAME` → `barsukov` |
| `argocd/applications/dev/app2-dev.yaml` | `YOUR-USERNAME` → `barsukov` |
| `argocd/applications/dev/app3-dev.yaml` | `YOUR-USERNAME` → `barsukov` |
| `argocd/applicationsets/apps-matrix.yaml` | `YOUR-USERNAME` → `barsukov` |

### 2. Bash Syntax Fix

| File | Line | Issue | Fix |
|------|------|-------|-----|
| `scripts/99-cleanup-all.sh` | ~15 | `[[$REPLY` | `[[ $REPLY` |

### 3. Kustomize Deprecation Fix

| Files | Issue | Fix |
|-------|-------|-----|
| All `overlays/*/kustomization.yaml` | `bases:` deprecated | → `resources:` |

### 4. YAML Structure Reconstruction

The source `argocd.md` has formatting corruption from copy-paste. Reconstruct valid YAML:

| Issue | Example | Fix |
|-------|---------|-----|
| Inline list items | `containers: - name: nginx` | Multi-line YAML list |
| Broken indentation | `selector:` at wrong level | Proper nesting |
| Merged lines | `syncOptions: - CreateNamespace=true` | Proper list format |

---

## Applications Detail

### app1-frontend (nginx)

| Component | Spec |
|-----------|------|
| Image | `nginx:1.25-alpine` |
| Port | 80 |
| Replicas | dev: 1, staging: 2, prod: 3 |
| Resources | 64Mi-128Mi memory, 50m-100m CPU |
| Probes | Liveness + Readiness on `/` |
| Prod extras | HPA (3-10 replicas), PDB (minAvailable: 2) |

### app2-api (httpbin)

| Component | Spec |
|-----------|------|
| Image | `kennethreitz/httpbin:latest` |
| Port | 80 |
| Replicas | dev: 1, staging: 1, prod: 3 |

### app3-worker (busybox)

| Component | Spec |
|-----------|------|
| Image | `busybox:latest` |
| Command | Loop printing "Processing job..." every 30s |
| Replicas | dev: 1, staging: 1, prod: 2 |

---

## ArgoCD Configuration

### Projects

| Project | Namespaces | Auto-sync | Cluster Resources |
|---------|------------|-----------|-------------------|
| dev-project | `dev-*`, `preview-*` | Yes | All |
| staging-project | `staging` | Yes | All |
| prod-project | `production` | No | Limited (Deployment, Service, ConfigMap) |

### Applications (Initial)

| Application | Project | Path | Namespace |
|-------------|---------|------|-----------|
| app1-frontend-dev | dev-project | `apps/app1-frontend/overlays/dev` | dev-app1-frontend |
| app2-api-dev | dev-project | `apps/app2-api/overlays/dev` | dev-app2-api |
| app3-worker-dev | dev-project | `apps/app3-worker/overlays/dev` | dev-app3-worker |

### Sync Policy (Dev Apps)

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
```

---

## Scripts Summary

| Script | Purpose |
|--------|---------|
| `00-run-all.sh` | Orchestrates full setup (calls 01-04) |
| `01-setup-cluster.sh` | Create Kind cluster + namespaces |
| `02-install-argocd.sh` | Install ArgoCD, wait for ready, print credentials |
| `03-configure-argocd.sh` | Patch ArgoCD config (30s reconciliation) |
| `04-deploy-apps.sh` | Apply projects + dev applications |
| `05-create-preview.sh` | Create feature branch preview env |
| `06-cleanup-preview.sh` | Delete preview env |
| `99-cleanup-all.sh` | Delete entire Kind cluster |

---

## Execution Plan

### Phase 1: Create Files

1. Create directory structure (`mkdir -p`)
2. Write all 35 files with fixes applied
3. Make scripts executable (`chmod +x`)

### Phase 2: Manual Steps (User)

1. Review created files
2. `git init && git add . && git commit -m "Initial ArgoCD GitOps setup"`
3. Create GitHub repo: `barsukov/k8s-gitops-demo`
4. Push to GitHub:
   ```bash
   git remote add origin https://github.com/barsukov/k8s-gitops-demo.git
   git push -u origin main
   ```
5. Run setup: `./scripts/00-run-all.sh`

### Phase 3: Verify

1. Access ArgoCD UI: http://localhost:8080
2. Get password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
3. Check apps: `kubectl get applications -n argocd`

---

## Prerequisites

```bash
# macOS
brew install kubectl kind helm kustomize

# Verify
kubectl version --client
kind version
```

---

## Access Points (After Setup)

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD UI | http://localhost:8080 | admin / (generated) |
| App1 Frontend | http://localhost:8081 | - |
| App2 API | http://localhost:8082 | - |

---

## Open Questions

_None currently - plan ready for review._

---

## Change Log

| Date | Change |
|------|--------|
| 2026-02-05 | Initial plan created |

---

## Approval

- [ ] File structure approved
- [ ] Fixes approved
- [ ] Configuration decisions approved
- [ ] Ready to execute
