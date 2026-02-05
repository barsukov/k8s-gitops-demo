# K8s GitOps Demo

A hands-on learning project for **ArgoCD** and **Kubernetes** GitOps workflows.

---

## What This Project Teaches

This project demonstrates a complete GitOps workflow from local development to production deployment:

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   Code      │────▶│   GitHub     │────▶│   ArgoCD    │────▶│  Kubernetes  │
│   Push      │     │   Actions    │     │   Sync      │     │   Cluster    │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   ghcr.io    │
                    │   Registry   │
                    └──────────────┘
```

### Core Concepts Covered

| Concept | Description |
|---------|-------------|
| **GitOps** | Git as single source of truth for deployments |
| **ArgoCD** | Kubernetes-native continuous deployment |
| **Kustomize** | Template-free Kubernetes configuration |
| **Multi-env** | Dev (auto-sync) vs Prod (manual approval) |
| **CI/CD** | GitHub Actions for build & push |
| **Feature Branches** | Protected main, PRs required |

---

## Architecture

### Applications

```
┌─────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                        │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    local namespace                        │    │
│  │   (ArgoCD watches local git repo - no push needed)       │    │
│  │   ┌─────────────┐              ┌──────────────┐          │    │
│  │   │  Frontend   │─────────────▶│     API      │          │    │
│  │   │  (nginx)    │    /api      │  (express)   │          │    │
│  │   └─────────────┘              └──────────────┘          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                     dev namespace                         │    │
│  │   (ArgoCD auto-syncs from GitHub main branch)            │    │
│  │   ┌─────────────┐              ┌──────────────┐          │    │
│  │   │  Frontend   │─────────────▶│     API      │          │    │
│  │   │  (1 replica)│              │  (1 replica) │          │    │
│  │   └─────────────┘              └──────────────┘          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 production namespace                      │    │
│  │   (ArgoCD requires manual sync - approval gate)          │    │
│  │   ┌─────────────┐              ┌──────────────┐          │    │
│  │   │  Frontend   │─────────────▶│     API      │          │    │
│  │   │ (2 replicas)│              │ (2 replicas) │          │    │
│  │   └─────────────┘              └──────────────┘          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Complete Development Workflow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  1. LOCAL DEVELOPMENT (No Git Required)                                       │
│                                                                               │
│  Make changes ──▶ ./scripts/local-deploy.sh ──▶ Test at localhost:8081      │
│                                                                               │
│  Use this for: Quick iteration, testing K8s manifests                        │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ works?
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  2. LOCAL ARGOCD TESTING (Commit Only, No Push)                              │
│                                                                               │
│  git add . && git commit ──▶ ArgoCD syncs 'local' namespace                 │
│                                                                               │
│  Use this for: Testing ArgoCD sync behavior, health checks                   │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ ArgoCD works?
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  3. FEATURE BRANCH (Push to GitHub, CI Only)                                 │
│                                                                               │
│  git checkout -b feature/xyz                                                 │
│  git push -u origin feature/xyz                                              │
│                                                                               │
│  GitHub Actions: ✓ Build  ✓ Test  ✗ No deploy                               │
│                                                                               │
│  Create Pull Request ──▶ Code Review ──▶ Merge to main                      │
│                                                                               │
│  Use this for: Team collaboration, code review                               │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ PR merged
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  4. DEV DEPLOYMENT (Automatic)                                               │
│                                                                               │
│  Merge to main ──▶ GitHub Actions ──▶ Build image ──▶ Push to ghcr.io      │
│                          │                                                    │
│                          ▼                                                    │
│                    Update kustomization.yaml (image tag)                     │
│                          │                                                    │
│                          ▼                                                    │
│                    ArgoCD detects change ──▶ Auto-sync to dev namespace     │
│                                                                               │
│  Use this for: Integration testing, team dev environment                     │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ ready for prod?
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  5. PRODUCTION RELEASE (Manual Approval)                                     │
│                                                                               │
│  Create GitHub Release (v1.0.0) ──▶ GitHub Actions ──▶ Build image          │
│                                            │                                  │
│                                            ▼                                  │
│                                      Push to ghcr.io                         │
│                                            │                                  │
│                                            ▼                                  │
│                                 Update prod kustomization.yaml               │
│                                            │                                  │
│                                            ▼                                  │
│                    ┌─────────────────────────────────────────┐               │
│                    │  ArgoCD UI shows "OutOfSync"            │               │
│                    │                                         │               │
│                    │  [Sync] ◀── Click to deploy            │               │
│                    └─────────────────────────────────────────┘               │
│                                                                               │
│  Use this for: Production deployments with manual approval gate              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Prerequisites

```bash
# macOS
brew install kubectl minikube pnpm docker

# Verify installations
kubectl version --client
minikube version
pnpm --version
docker --version
```

### Option 1: Full GitOps Setup (Recommended)

```bash
# 1. Clone the repo (or init if local)
git clone https://github.com/barsukov/k8s-gitops-demo.git
cd k8s-gitops-demo

# 2. Run complete setup (takes ~5 minutes)
./scripts/00-run-all.sh

# 3. Access services
open http://localhost:8080  # ArgoCD UI
open http://localhost:8081  # Frontend app
```

### Option 2: Quick Local Test (No ArgoCD)

```bash
# Deploys directly to Kubernetes, bypassing ArgoCD
./scripts/local-deploy.sh
```

### Option 3: Local Development (No Kubernetes)

```bash
# Terminal 1: Start API
cd apps/api && pnpm install && pnpm dev

# Terminal 2: Start Frontend
cd apps/frontend && pnpm install && pnpm dev

# Open http://localhost:5173
```

---

## Project Structure

```
k8s-gitops-demo/
│
├── apps/
│   ├── frontend/                 # React + Vite + TypeScript
│   │   ├── src/                  # Application source
│   │   ├── k8s/                  # Kubernetes manifests
│   │   │   ├── base/             # Base configuration
│   │   │   └── overlays/         # Environment overrides
│   │   │       ├── dev/          #   Dev environment
│   │   │       └── production/   #   Production environment
│   │   ├── Dockerfile
│   │   └── nginx.conf            # Proxy /api to API service
│   │
│   └── api/                      # Express + TypeScript
│       ├── src/
│       ├── k8s/
│       │   ├── base/
│       │   └── overlays/
│       │       ├── dev/
│       │       └── production/
│       └── Dockerfile
│
├── argocd/
│   ├── projects/                 # ArgoCD project definitions
│   │   ├── dev-project.yaml      #   Dev permissions
│   │   ├── prod-project.yaml     #   Prod permissions (restricted)
│   │   └── local-project.yaml    #   Local testing permissions
│   └── applications/             # ArgoCD application definitions
│       ├── dev/                  #   Dev apps (auto-sync)
│       ├── prod/                 #   Prod apps (manual sync)
│       └── local/                #   Local apps (file:// repo)
│
├── scripts/
│   ├── 00-run-all.sh             # Full setup orchestration
│   ├── 01-setup-cluster.sh       # Start Minikube
│   ├── 02-install-argocd.sh      # Install ArgoCD
│   ├── 03-configure-argocd.sh    # Configure reconciliation
│   ├── 04-build-images.sh        # Build & load images
│   ├── 05-deploy-apps.sh         # Deploy ArgoCD apps
│   ├── local-deploy.sh           # Quick local testing (no ArgoCD)
│   ├── setup-local-argocd.sh     # Configure local ArgoCD testing
│   └── 99-cleanup-all.sh         # Delete cluster
│
├── local-dev/
│   ├── minikube-start.sh         # Minikube configuration
│   └── port-forwards.sh          # Port forwarding setup
│
├── .github/workflows/
│   ├── ci.yml                    # Build & test (all branches)
│   ├── dev-deploy.yml            # Deploy to dev (main only)
│   └── prod-release.yml          # Deploy to prod (tags only)
│
├── .gitignore
├── LICENSE                       # Apache 2.0
└── README.md
```

---

## Environments

| Environment | Namespace | Trigger | Sync Mode | Replicas |
|-------------|-----------|---------|-----------|----------|
| **local** | `local` | `git commit` (no push) | Auto | 1 |
| **dev** | `dev` | Merge to `main` | Auto | 1 |
| **production** | `production` | Git tag `v*` | Manual | 2 |

### Why Three Environments?

1. **Local**: Test ArgoCD behavior without pushing to GitHub
2. **Dev**: Shared team environment, always up-to-date with main
3. **Production**: Stable releases with manual approval gate

---

## Development Workflow

### Quick Reference

| What I Want | Command |
|-------------|---------|
| Test K8s manifests quickly | `./scripts/local-deploy.sh` |
| Test with ArgoCD locally | `git commit` → ArgoCD syncs local namespace |
| Push for team review | `git push origin feature/xyz` → Create PR |
| Deploy to dev | Merge PR to main |
| Deploy to production | Create GitHub release (v1.0.0) → Sync in ArgoCD |

### Step-by-Step Development

```bash
# 1. Create feature branch
git checkout -b feature/my-change

# 2. Make changes and test locally
./scripts/local-deploy.sh

# 3. Test with ArgoCD (optional)
./scripts/setup-local-argocd.sh
git add . && git commit -m "test"
# Watch ArgoCD sync: kubectl get applications -n argocd -w

# 4. Push and create PR
git push -u origin feature/my-change
# Open PR on GitHub, request review

# 5. Merge PR
# Dev environment automatically updates

# 6. Release to production
# Create release on GitHub (v1.0.0)
# Open ArgoCD UI, click Sync on prod apps
```

---

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD UI | http://localhost:8080 | admin / (see below) |
| Frontend (dev) | http://localhost:8081 | - |
| API (dev) | http://localhost:8082 | - |

### Get ArgoCD Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## Key ArgoCD Concepts

### Application

Defines **what** to deploy and **where**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend-dev
spec:
  source:
    repoURL: https://github.com/barsukov/k8s-gitops-demo.git
    path: apps/frontend/k8s/overlays/dev
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
```

### Sync Policy

Controls **how** deployments happen:

```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources removed from git
    selfHeal: true   # Revert manual kubectl changes
```

### Project

Controls **permissions** and boundaries:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: prod-project
spec:
  sourceRepos:
    - 'https://github.com/barsukov/k8s-gitops-demo.git'
  destinations:
    - namespace: production
      server: https://kubernetes.default.svc
```

---

## GitHub Actions Workflows

### CI (All Branches)

```
Push to any branch
        │
        ▼
┌───────────────────┐
│  Build Frontend   │
│  Build API        │
│  Validate K8s     │
└───────────────────┘
        │
        ▼
   ✓ or ✗
   (no deploy)
```

### Dev Deploy (main only)

```
Merge to main
        │
        ▼
┌───────────────────┐
│  Build images     │──────▶ ghcr.io/barsukov/frontend:dev-YYYYMMDD-SHA
│                   │──────▶ ghcr.io/barsukov/api:dev-YYYYMMDD-SHA
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  Update           │
│  kustomization    │──────▶ Commit new image tag to repo
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  ArgoCD           │──────▶ Auto-sync to dev namespace
└───────────────────┘
```

### Prod Release (tags only)

```
Create release v1.0.0
        │
        ▼
┌───────────────────┐
│  Build images     │──────▶ ghcr.io/barsukov/frontend:v1.0.0
│                   │──────▶ ghcr.io/barsukov/api:v1.0.0
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  Update           │
│  kustomization    │──────▶ Commit new image tag to repo
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  ArgoCD           │──────▶ Shows "OutOfSync"
│                   │        (manual sync required)
└───────────────────┘
```

---

## Troubleshooting

### ArgoCD Shows "Unknown" Health

```bash
# Check application status
argocd app get frontend-dev

# Check pod logs
kubectl logs -n dev -l app=frontend

# Check events
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Images Not Loading in Minikube

```bash
# Verify image exists in Minikube
minikube -p argocd-demo image ls | grep frontend

# Rebuild if needed
./scripts/04-build-images.sh
```

### Port Forward Not Working

```bash
# Kill existing port-forwards
pkill -f "port-forward"

# Restart
./local-dev/port-forwards.sh
```

### ArgoCD Sync Stuck

```bash
# Force refresh
argocd app get frontend-dev --refresh

# Hard refresh (re-clone repo)
argocd app get frontend-dev --hard-refresh
```

---

## Learning Path

### Beginner

- [ ] Run `./scripts/00-run-all.sh` and explore ArgoCD UI
- [ ] Make a change to `apps/frontend/src/App.tsx`
- [ ] Commit and push, watch ArgoCD sync

### Intermediate

- [ ] Understand Kustomize base/overlay structure
- [ ] Create a production release
- [ ] Practice the PR workflow

### Advanced

- [ ] Add health checks and custom sync hooks
- [ ] Implement Argo Rollouts for canary deployments
- [ ] Add Prometheus/Grafana monitoring
- [ ] Create ApplicationSets for dynamic app generation

---

## Cleanup

```bash
# Delete everything
./scripts/99-cleanup-all.sh

# Start fresh
./scripts/00-run-all.sh
```

---

## License

Apache License 2.0 - see [LICENSE](LICENSE)
