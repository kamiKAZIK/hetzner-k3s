helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx
cat <<EOF > ingress-nginx.yaml
controller:
  service:
    type: NodePort
    nodePorts:
      http: 32080
      https: 32443
      tcp:
        1883: 30083
        8883: 30883
tcp:
  8883: "default/mosquitto:8883"
  1883: "default/mosquitto:1883"
EOF
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values ingress-nginx.yaml \
  --version 4.10.0
rm ingress-nginx.yaml
