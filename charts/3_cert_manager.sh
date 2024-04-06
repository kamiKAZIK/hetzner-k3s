helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
cat <<EOF > cert-manager.yaml
installCRDs: true
EOF
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values cert-manager.yaml \
  --version v1.14.4
rm cert-manager.yaml
