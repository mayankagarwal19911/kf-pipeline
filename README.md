# kf-pipeline
Run `./deploy.sh` to setup the pipeline on your kubernetes cluster

# Train model with Katib
1. Take kubeflow & jupyter notebook endpoints(after you run deploy.sh)
   

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-19.32.18.png)


2. In jupyter notebook, upload the notebook present in /examples/mnist_kfpv2.ipynb
    a. Update KFP_URL in the notebook
3. Run the notebook and check the pipelin run in kubeflow.


![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-13.26.53-2.png)

4. To validate the katib tuning, open Katib url and check the best trial after multiple runs

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-19.04.01.png)

5. After pipeline is successful, check the inference service and determine ingress IP & ports to perform inference

`kubectl get isvc -n kubeflow`

`export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')`

`export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')`

# Test Inference
6. Prepare inout data for inference.
    a. Run examples/kserve_inference.ipynb in jupyter notebook and download the 'input.json'

7. Run below command to test the inference, [Update the inference name & namespace accordingly]

`SERVICE_HOSTNAME=$(kubectl get inferenceservice mnist-model-v2  -n kubeflow -o jsonpath='{.status.url}' | cut -d "/" -f 3)`

`curl -v -H "Host: ${SERVICE_HOSTNAME}" http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/mnist-model-v2:predict -d @./mnist-input.json`

You should see the similar output

![My Remote Image](http://letslearnsomething.today/wp-content/uploads/2023/09/Screenshot-2023-09-06-at-19.15.25.png)
