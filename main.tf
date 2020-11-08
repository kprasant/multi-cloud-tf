provider "google" {
 project     = "<project name>"
}
provider "aws" {
  region = "ca-central-1"
}
provider "kubernetes" {
  load_config_file = "false"

  host = "https://${google_container_cluster.primary.endpoint}"
  username = "admin"
  password = "15 chars length"
  client_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].client_certificate,
  )
  client_key = base64decode(
    google_container_cluster.primary.master_auth[0].client_key,
  )
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}
