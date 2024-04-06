cat <<EOF > /etc/haproxy/haproxy.cfg
global
  daemon
  user  haproxy
  group  haproxy
  log  /dev/log local0
  maxconn  10000
  pidfile  /var/run/haproxy.pid
defaults
  log  global
  mode  tcp
  retries  3
  timeout  http-request 10s
  timeout  queue 1m
  timeout  connect 10s
  timeout  client 1m
  timeout  server 1m
  timeout  check 10s
frontend nodeport80
  bind :80
  default_backend port32080
frontend nodeport443
  bind :443
  default_backend port32443
backend port32080
  balance roundrobin
  server web1 127.0.0.1:32080
backend port32443
  balance roundrobin
  server web1 127.0.0.1:32443
EOF
service haproxy reload
