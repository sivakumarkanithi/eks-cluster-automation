# EKS Terraform Automation — Siva

Terraform project for a fresh EKS cluster in **us-east-1**, with EBS CSI storage, Prometheus/Grafana monitoring, and Argo CD GitOps.

## Architecture

- VPC with public and private subnets across 3 AZs; one NAT Gateway to reduce cost.
- EKS managed node group in private subnets.
- Dedicated IRSA role for the AWS EBS CSI managed add-on.
- EBS gp3 StorageClass (created by the EKS add-on; verify before installing workloads).
- Separate Terraform root in `addons/` for Helm releases. The cluster must exist before Kubernetes/Helm providers can connect.

## Security and cost notes

- Never commit Terraform state, plan files, credentials, private keys, or real `.tfvars`.
- Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in a valid us-east-1 Ubuntu AMI ID, existing EC2 key pair, and your public IP as `x.x.x.x/32`.
- Do not expose SSH to `0.0.0.0/0`.
- Billable resources include EKS control plane, EC2 nodes, NAT Gateway, EBS volumes, and public Network Load Balancers. Destroy lab resources when finished.
- Example uses two `t3.large` nodes. Confirm availability and cost in your account before applying.
- Public Grafana and Argo CD NLBs are internet-facing. For production, use an authenticated ingress/WAF or restrict access. Change default credentials immediately.

## Prerequisites

Terraform >= 1.5, AWS CLI, kubectl, and AWS credentials with permissions to create VPC, EC2, EKS, IAM/OIDC, EKS add-ons, and ELB resources.

## Stage 1 — Create infrastructure

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: AMI ID, key pair, and SSH CIDR are mandatory.
terraform init
terraform fmt -recursive
terraform validate
terraform plan
# Review the plan carefully, then:
terraform apply
```

Do not use `-auto-approve` on the first deployment. EKS creation may take 15–25 minutes.

## Stage 2 — Configure kubectl and verify EBS CSI

```bash
aws eks update-kubeconfig --region us-east-1 --name siva-cluster-1
kubectl get nodes
aws eks describe-addon --cluster-name siva-cluster-1 --addon-name aws-ebs-csi-driver --region us-east-1
kubectl get pods -n kube-system | grep ebs-csi
kubectl get storageclass
```

Confirm the EBS CSI controller is healthy and a gp3 StorageClass exists. If gp3 is absent, create it:

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
YAML
```

## Stage 3 — Install Prometheus, Grafana, and Argo CD

`addons/` is a separate Terraform root with its own state:

```bash
cd addons
terraform init
terraform fmt -recursive
terraform validate
terraform plan
# Review, then:
terraform apply
```

The kube-prometheus-stack chart installs Prometheus, Alertmanager, Grafana, and cluster monitoring components. Prometheus and Alertmanager use gp3 PVCs. Grafana and Argo CD receive internet-facing AWS Network Load Balancers.

```bash
kubectl get svc -n monitoring
kubectl get svc -n argocd
terraform output
```

Retrieve initial passwords securely:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

Username is `admin` for both. Change passwords after first login. Never commit or share passwords.

## Cleanup

Destroy add-ons first, then infrastructure:

```bash
cd addons && terraform destroy
cd ..
terraform destroy
```

Check AWS for leftover EBS volumes, load balancers, NAT gateways, and snapshots.

## Notes

- Verify the selected Kubernetes version and EC2 instance type are currently supported/available in us-east-1 before deployment.
- The add-ons state assumes the root stack and EBS CSI add-on are already deployed.
- This is a learning/lab baseline, not a production-hardened platform.
