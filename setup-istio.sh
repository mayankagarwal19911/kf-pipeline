export ISTIO_VERSION=1.17.2

curl -L https://istio.io/downloadIstio | sh -
cd istio-${ISTIO_VERSION}

# Create istio-system namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    istio-injection: disabled
EOF

cat << EOF > ./istio-minimal-operator.yaml
apiVersion: install.istio.io/v1beta1
kind: IstioOperator
spec:
  values:
    global:
      proxy:
        autoInject: disabled
      useMCP: false

  meshConfig:
    accessLogFile: /dev/stdout

  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          podAnnotations:
            cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
    pilot:
      enabled: true
      k8s:
        resources:
          requests:
            cpu: 200m
            memory: 200Mi
        podAnnotations:
          cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
        env:
        - name: PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING
          value: "false"
EOF

bin/istioctl manifest apply -f istio-minimal-operator.yaml -y;

echo "😀 Successfully installed Istio"
cd ..
# Clean up
rm -rf istio-${ISTIO_VERSION}