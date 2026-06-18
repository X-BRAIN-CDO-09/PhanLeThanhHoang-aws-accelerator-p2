# W10 Morning Lab — RBAC + Admission Policy (OPA Gatekeeper)

Mọi thứ chạy qua **GitOps** — không `kubectl apply` tay.
Repo này được ArgoCD root app `argocd/root.yaml` tracking.

## Cấu trúc lab mới thêm (W10 sáng)

```
rbac/
├── roles.yaml          # 3 role: developer / sre / viewer
└── rolebindings.yaml   # gắn alice / bob / carol

gatekeeper/
├── templates/          # 5 ConstraintTemplate (Rego)
│   ├── k8sdisallowedtags.yaml
│   ├── k8srequiredlimits.yaml
│   ├── k8sdisallowroot.yaml
│   ├── k8sdisallowhostnetwork.yaml
│   └── k8srequiredlabels.yaml         # Lab 1.3 custom
└── constraints/        # 5 Constraint (instance)
    ├── 01-disallow-latest-tag.yaml
    ├── 02-require-limits.yaml
    ├── 03-disallow-root.yaml
    ├── 04-disallow-host-network.yaml
    └── 05-require-owner-label.yaml    # Lab 1.3 custom

argocd/apps/
├── rbac.yaml                          # wave -1
├── gatekeeper.yaml                    # wave -2 (Helm chart)
├── gatekeeper-templates.yaml          # wave  1
└── gatekeeper-constraints.yaml        # wave  2

lab/test-violations/    # manifest dùng để nghiệm thu (apply tay)
├── bad-latest-tag.yaml
├── bad-no-limits.yaml
├── bad-run-as-root.yaml
├── bad-host-network.yaml
├── bad-no-owner-label.yaml
└── good-pod.yaml
```

## Sync wave timeline

| Wave | App                       | Lý do                                                  |
|-----:|---------------------------|--------------------------------------------------------|
|  -2  | `gatekeeper`              | Cài controller trước mọi thứ                           |
|  -1  | `common`, `rbac`          | Namespace `demo` + RBAC                                |
|   0  | `k8s-prometheus`, `k8s-rollout` | Hạ tầng monitoring + rollout controller           |
|   1  | `gatekeeper-templates`, `app-analysis`, `app-alert` | ConstraintTemplate + analysis |
|   2  | `gatekeeper-constraints`, `api` | Constraint enforce + workload                     |

> Constraint phải vào **sau** ConstraintTemplate (CRD chưa có thì apply sẽ lỗi).

## Lab 1.1 — Nghiệm thu RBAC

Sau khi ArgoCD sync xong `rbac` app:

```bash
# Alice tạo deploy trong demo -> yes
kubectl auth can-i create deploy -n demo --as alice            # yes

# Alice tạo deploy trong kube-system -> no
kubectl auth can-i create deploy -n kube-system --as alice     # no

# Bob xem pods toàn cụm -> yes
kubectl auth can-i get pods -A --as bob                        # yes

# Carol xóa node -> no
kubectl auth can-i delete nodes --as carol                     # no
```

Cả 4 lệnh trả đúng → đạt.

## Lab 1.2 — Nghiệm thu Gatekeeper (4 luật)

Manifest mẫu nằm trong `lab/test-violations/`. **Apply tay** (không commit) để test:

```bash
kubectl apply -f lab/test-violations/bad-latest-tag.yaml    # reject
kubectl apply -f lab/test-violations/bad-no-limits.yaml     # reject
kubectl apply -f lab/test-violations/bad-run-as-root.yaml   # reject
kubectl apply -f lab/test-violations/bad-host-network.yaml  # reject
kubectl apply -f lab/test-violations/good-pod.yaml          # pass
```

Mọi `bad-*` đều trả `admission webhook "validation.gatekeeper.sh" denied the request`,
`good-pod` apply thành công.

### Mẹo audit trước khi enforce

Trước khi bật `enforcementAction: deny`, đổi tạm sang `warn` rồi xem ai vi phạm:

```bash
kubectl get k8srequiredlimits -o yaml         # status.totalViolations
kubectl get constraint --all-namespaces
```

## Lab 1.3 — Custom ConstraintTemplate

Chọn: **mọi workload phải có label `owner`** (truy vết khi alert).

- Template: `gatekeeper/templates/k8srequiredlabels.yaml` (Rego)
- Constraint: `gatekeeper/constraints/05-require-owner-label.yaml`
- Test reject: `lab/test-violations/bad-no-owner-label.yaml`
- Test pass: chính `app-api/rollout.yaml` đã có `owner: team-platform`

```bash
kubectl apply -f lab/test-violations/bad-no-owner-label.yaml
# admission webhook denied: Thiếu label bắt buộc: {"owner"}
```

## Thay đổi đã làm trên platform để hợp lệ với policy

`app-api/rollout.yaml`:
- thêm `metadata.labels.owner: team-platform` (cho cả Rollout & podTemplate)
- thêm `securityContext.runAsNonRoot: true`, `runAsUser: 10001` (tránh dính K8sDisallowRoot)
- thêm `resources.requests` (chỉ là good-practice, không bắt buộc)

Image đã ở dạng `ghcr.io/Vuong-Bach/w10-api:0.0.1` → đã pin version, không dính `latest`.

## Rollback nhanh nếu enforce sập platform

```bash
# Đổi nhanh constraint sang audit
kubectl patch k8srequiredlimits require-resource-limits \
  --type merge -p '{"spec":{"enforcementAction":"warn"}}'
```

(Hoặc sửa file YAML rồi commit/push để ArgoCD sync.)
