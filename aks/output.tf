
# Output the AKS cluster name
output "aks_cluster_name" {
  description = "The name of the AKS Cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}