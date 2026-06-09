# W9 Lab: GitOps-ify + bolt-on

## Mục tiêu
- GitOps-ify W8 platform + bolt-on observability + canary
- Cluster W8 đã có giờ GitOps-managed (ArgoCD sync)
- Có observability stack đo SLO + burn rate alert
- Deploy nào ra cũng canary auto-abort khi metric tệ. Không apply manifest tay nữa.
