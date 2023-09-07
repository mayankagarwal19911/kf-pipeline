# kf-pipeline
Run ```./deploy.sh``` to setup the pipeline on your kubernetes cluster. Preferred platform is GKE.</br>
There are some issues while running inference ok AKS. Issue has been created for same - https://github.com/kserve/kserve/issues/3111

- Kubeflow: 2.1.3
- Katib: v0.15.0
- Knative serving: v1.10.1
- Knative istio: v1.10.0  
- Kserve: v0.11.0

# Train model with Katib
1. Take kubeflow & jupyter notebook endpoints(after you run deploy.sh)
   

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-19.32.18.png)


2. In jupyter notebook, upload the notebook present in /examples/mnist_kfpv2.ipynb
    a. Update KFP_URL in the notebook

    Create PVC in your cluster for TFJob launcher workers

    ```
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
    name: mnist-model-volume-01
    namespace: kubeflow
    spec:
    accessModes:
        - ReadWriteOnce
    resources:
        requests:
        storage: 10Gi
    storageClassName: standard-rwo
    ```

3. Run the notebook and check the pipelin run in kubeflow.


![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-13.26.53-2.png)

4. To validate the katib tuning, open Katib url and check the best trial after multiple runs

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-19.04.01.png)

5. After pipeline is successful, check the inference service and determine ingress IP & ports to perform inference

```
kubectl get isvc -n kubeflow
```

```
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
```

# Test Inference
6. Prepare input data for inference, run examples/kserve_inference.ipynb in jupyter notebook and download the 'input.json'

8. Run below command to test the inference, [Update the inference name & namespace accordingly]

```
SERVICE_HOSTNAME=$(kubectl get inferenceservice mnist-model-v2  -n kubeflow -o jsonpath='{.status.url}' | cut -d "/" -f 3)
```

```
curl -v -H "Host: ${SERVICE_HOSTNAME}" http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/mnist-model-v2:predict -d @./mnist-input.json
```

You should see the similar output

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-19.15.25.png)

# Test Early stop
1. Run /example/median-early-stop.yaml 
2. Validate the early stopping in katib UI

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-07-at-13.12.36.png)