#!/bin/bash

APP_ACTION=create
JUPYTER_HELM_CHART=jupyterhub
CERT_MANAGER_VERSION=v1.3.0
JUPYTER_NOTEBOOK_NS=jupyter
if [ $APP_ACTION = "create" ]; then

   echo "🚥 Checking if istio is already installed. 😊"
   if [ "$(kubectl get svc istio-ingressgateway -n istio-system 2>/dev/null | wc -l)" -eq "0" ]; then
      echo "🚥 Installing Istio. Grab a 🍕 while we are setting it up for you 😊"
      /bin/bash ./setup-istio.sh
   else
      echo "🚥 Istio is already installed, skipping..."
   fi

   echo "📝 Checking if cert-manager is already installed. 😊"
   if [ "$(kubectl get pods -n cert-manager 2>/dev/null | wc -l)" -eq "0" ]; then
      echo "📝 Installing cert manager"
      kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml
      kubectl wait --for=condition=available --timeout=600s deployment/cert-manager-webhook -n cert-manager
      echo "😀 Successfully installed cert manager!"
   else
      echo "📝 Cert manager is already installed, skipping..."
   fi

   echo "📘 Checking if jupyter notebook is already installed. 😊"
   if [ "$(kubectl get pods -n $JUPYTER_NOTEBOOK_NS 2>/dev/null | wc -l)" -eq "0" ]; then
      echo "📘 Installing jupyter notebook 😊"
      helm install $JUPYTER_HELM_CHART components/jupyter --namespace jupyter --create-namespace
   else
      echo "📘 Jupyer notebook is already installed, skipping..."
   fi

   echo "😊 It's time to setup tools for your MLOps pipeline. It will take a while. Our engineers are working to set things up for you! 👷‍♀️"
   # HACK
   # kserve core & crds doesn't work directly well with kustomize, so Applying them manually.
   kubectl apply -f ./base/kserve/knative-serve/serving-crds.yaml
   kubectl apply -f ./base/kserve/knative-serve/serving-core.yaml
   
   retry=0; while [ $retry -lt 3 ]; do kubectl apply -k . && break; retry=$((retry+1)); echo "Oops, something not right... We are on the way 🏃🏻 to fix it."; sleep 2; done
   # Patch the external domain as the default domain svc.cluster.local is not exposed on ingress.
   kubectl patch cm config-domain --patch '{"data":{"example.com":""}}' -n knative-serving
   kubectl label namespace kubeflow katib.kubeflow.org/metrics-collector-injection=enabled


   KUBEFLOW_EP=$(kubectl get svc/ml-pipeline-ui -n kubeflow | awk 'NR == 2 {print $4}')
   JUPYTER_EP=$(kubectl get svc/proxy-public -n $JUPYTER_NOTEBOOK_NS | awk 'NR == 2 {print $4}')
   KATIB_EP=$(kubectl get svc/katib-ui -n kubeflow | awk 'NR == 2 {print $4}')
   
   echo "You can access the services using below urls"
   echo "
   Kubeflow: $KUBEFLOW_EP
   Jupyter: $JUPYTER_EP
   Katib: $KATIB_EP/katib
   "
else

   read -p "Do you want to delete the resources ? We will delete only tools for you, but won't delete the core components like cert-manager, jupyter notebook or istio 🔴. (yes/no) " yn

   case $yn in 
      yes ) echo " 😊 Ok";;
      no ) echo "Aborting delete...";
         exit;;
      * ) echo "Invalid response";
         exit 1;;
   esac

   kubectl delete -k .
   kubectl delete -f ./base/kserve/knative-serve/serving-crds.yaml
   kubectl delete -f ./base/kserve/knative-serve/serving-core.yaml
   # To completely destroy ns knative-serving
   
fi

# kubectl create ns kubeflow
# kubectl kustomize --enable-helm > kubeflow-pipeline.yaml
# kubectl $KUBECTL_ACTION -f kubeflow-pipeline.yaml
