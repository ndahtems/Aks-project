### Origen.ai - Cloud DevOps Engineer Technical Test 

---

### **Project Overview**
This project aims to deploy a web application with frontend, backend, and MongoDB components in an Azure Kubernetes Service (AKS) cluster. Terraform is used to set up the infrastructure, and Helm charts are utilized for deploying the components. The deployment process ensures scalability, security, and easy access to the application.

---

### **Prerequisites**

1. **Azure Free Account**: [Sign Up for Free Azure Account](https://azure.microsoft.com/free/)
   - Sign up for an Azure free account to access the Azure Kubernetes Service (AKS) and other necessary Azure resources.
   - Ensure that you have sufficient credits (Azure provides $200 credit for free tier users).

2. **Terraform**: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
   - Install Terraform CLI (at least version 1.0) for infrastructure provisioning.
   - Terraform will be used to create the AKS cluster and manage its resources.

3. **Kubectl**: [Install Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
   - Install `kubectl` CLI to interact with the AKS cluster for Kubernetes operations.

4. **Helm**:  [Install Helm](https://helm.sh/docs/intro/install/)
   - Install Helm to manage Kubernetes applications.

5. **ArgoCD**:  [ArgoCD Installation Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)
   - ArgoCD will be used to manage the continuous deployment of Kubernetes applications. Install ArgoCD on the AKS cluster after it is set up.

---
## ARCHITECTURE DEPLOYMENT
---
### Setup Instructions for Deploying the Application on AKS
- Clone the Repository to your local
```sh
git clone https://github.com/ndahtems/Aks-project.git
```

#### **Step 1: Login to Azure**
- First, login to your Azure account via the command line.

```sh
az login
```
- Select the Subscription_id from the Azure account:

```sh
az account set --subscription "subscription-id"
```

#### **Step 2: Create and Setup the Terraform Directory**
- navigate into the aks directory.

```sh
cd aks
```

#### **Step 3: Initialize Terraform and Create AKS Cluster**
- Initialize Terraform in your project directory:

```sh
terraform init
```

- Plan the infrastructure changes to see what will be created:

```sh
terraform plan
```

- Apply the configuration to create the AKS cluster:

```sh
terraform apply -auto-approve
```

- The cluster creation will take a few minutes. Once complete, retrieve the configuration.

#### **Step 4: Connect to AKS Cluster**
- Once the cluster is up and running, configure `kubectl` to securely access the cluster:

```sh
az aks get-credentials --resource-group my-aks-resource-group --name aks-cluster
```

- Verify that your Kubernetes cluster is running:

```sh
kubectl get nodes
```

---
## APPLICATIONS DEPLOYMENT
---
#### **Step 5: Install ArgoCD**
- Deploy ArgoCD into your Kubernetes cluster:

```sh
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm -n argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
- Create the argocd helm charts and configure the argocd applications
```sh
helm create argcd
helm install argocd argo/argo-cd -f values.yaml -n argocd
```
- Change the argocd-server service type to LoadBalancer inorder to access it externally

```sh
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```
- Get the ArgoCD initial admin password:

```sh
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
```
- Access ArgoCD via the LoadBalancer service:

```sh
kubectl get svc argocd-server -n argocd
```
- Connect the argocd server using the Loadbalancer External_IP ans use 'admin' and the default username and the password

#### **Step 6: Deploy Application Components Using ArgoCD and Helm**
- In the helm directory, create three helm charts for the 3 tires
```sh
helm create backend
helm create frontend
helm create mongo
```

- The Applications can be deployed using argocd helm charts:
- On the ArgoCD server, create the Repository and add the ssh keys to authenticate
```sh
helm install argocd argo/argo-cd -f values.yaml -n argocd
```

- The Applications can also be deployed manually with helm commands
```sh
az aks get-credentials --resource-group aks-resource-group --name aks-cluster
kubectl get nodes
```
```sh
cd helm/backend
helm upgrade --install backend ./backend -f values.yaml -n azure
```
```sh
cd helm/frontend
helm upgrade --install frontend ./frontend -f values.yaml -n azure

```
---
## APPLICATION LOGGING
---
- If Mongo is running
```sh
k logs -f <mongodb_pod>
```
- If frontend is running
```sh
k logs -f <frontend_pod>
```
- If backend is running
```sh
k logs -f <backend_pod>
```
- To check if Backend can connect to MongoDB run the command
```sh
kubectl exec -it $(kubectl get pod -l app=backend -n azure -o jsonpath="{.items[0].metadata.name}") -n azure -- env | grep MONGO
```
---
# **SETUP CONSIDERATIONS:**

#### **1. Data Management:**
- **MongoDB Storage:**
  - MongoDB is deployed using a StatefulSet with Persistent Volume Claims (PVC) ensuring data is stored persistently across pod restarts or failures.

**Lapses:**
  - **Sensitive Data in Plain Text:** The MongoDB credentials are stored directly in the Helm chart configuration files, which exposes the application to security risks.
  
**Improvement:**
  - **Azure Key Vault Integration:** Storing MongoDB credentials in Azure Key Vault would enhance security by keeping secrets outside the cluster. The secrets could be dynamically accessed by the Kubernetes pods, eliminating the need for hardcoded credentials.

---

#### **2. Security Considerations:**
- **Access Control:**
  - The backend and MongoDB services are running as **ClusterIP**, which limits their access to within the cluster, ensuring that these components are not exposed to external networks.

- **Internal Communication:**
  - The services communicate internally within the Kubernetes cluster using **DNS service names**, which simplifies service discovery and adds a layer of isolation.

- **Frontend Load Balancer:**
  - The frontend service uses a **LoadBalancer** type in Kubernetes, which exposes the service to external traffic, allowing users to access it over the internet.
  
**Lapses:**
  - **No TLS for Internal Communication:** Communication between backend and MongoDB is currently unencrypted, leaving the application vulnerable to potential internal threats.
  
**Improvement:**
  - **mTLS (Mutual TLS):** Enable mTLS between services to ensure encrypted communication within the cluster. This would prevent internal man-in-the-middle attacks.

---

#### **3. Sensitive Data Management:**
- **Plain Text Credentials:**
  - MongoDB credentials are stored as plaintext in the configuration files, which poses a significant security risk.

**Lapses:**
  - **Hardcoded Secrets:** Storing secrets in the Helm charts exposes them in source control, making it easier for an attacker to gain access.

**Improvement:**
  - **Azure Key Vault for Secrets:** Integrate Azure Key Vault to securely store and manage sensitive information like MongoDB credentials. This removes the need to store secrets directly in configuration files.
  - **Secret Management with Kubernetes Secrets:** Kubernetes secrets could be used instead, with better management of who has access to these secrets within the cluster.

---

### **4. Deployment Strategy and Scalability:**

1. **Backend Deployment:**
   - The backend is deployed as a Deployment object. This allows for easy scaling of replicas.
   - **Scaling Strategy:** Use Horizontal Pod Autoscaler (HPA) to scale backend pods based on CPU or memory usage.
   
2. **Frontend Deployment:**
   - The frontend service is deployed using a Deployment object with a **LoadBalancer** service type. The LoadBalancer allows external access to the service and distributes traffic across multiple frontend instances.
   - **Scaling Strategy:** Enable HPA for the frontend to scale based on incoming traffic, ensuring availability during high load.

3. **MongoDB Deployment:**
   - MongoDB is deployed as a StatefulSet to maintain persistent storage for each replica.
   - **Scaling Strategy:** MongoDB can be scaled by increasing the number of replicas in the StatefulSet, ensuring data replication and failover.

---

#### **5. ArgoCD Integration:**
- **Continuous Deployment:**
  - ArgoCD is used to manage the continuous deployment of the application. It ensures that the application's desired state (as defined in the Git repository) is always reflected in the Kubernetes cluster.
  
**Advantages:**
  - **Version Control:** ArgoCD integrates with Git, making it easy to track changes and revert to previous versions if needed.
  - **Sync Monitoring:** ArgoCD continuously monitors the cluster and can automatically apply changes if the cluster state drifts from the desired state.
  
**Improvements:**
  - Implement role-based access control (RBAC) in ArgoCD to ensure that only authorized users can deploy or make changes to the cluster.

---

| **Category**             | **Lapse**                                  | **Improvement**                                                                                                 |
|--------------------------|--------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| Data Management           | Credentials in plain text                 | Use Azure Key Vault or Kubernetes Secrets with encryption                                                       |
| Security                  | No mTLS between services                  | Implement mTLS and use Network Policies                                                                         |
| High Availability         | Single replicas for backend and MongoDB   | Increase replicas, use Pod Disruption Budgets for resilience                                                    |
| Scalability               | No autoscaling                            | Implement Horizontal Pod Autoscaling (HPA)                                                                      |
| Sensitive Data Management | Plain text credentials                    | Move credentials to Azure Key Vault or encrypted Kubernetes Secrets                                             | 
