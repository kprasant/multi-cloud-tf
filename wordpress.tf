resource "kubernetes_service" "svc" {
  metadata {
    name = "wp-svc"
    labels = {
        app = "wp"
    }
  }
  spec {
    selector = {
      app = "wp"
    }
    type  = "LoadBalancer"
    port {
      port        = "80"
    }
  }
  depends_on = [ google_container_node_pool.primary_nodes ]
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name = "wp-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  depends_on = [ google_container_node_pool.primary_nodes ]
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name = "wp-deploy"
    labels = {
      app = "wp"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "wp"
      }
    }

    template {
      metadata {
        labels = {
          app = "wp"
        }
      }

      spec {
        container {
          image = "wordpress"
          name  = "wordpress"
          port   {
              name = "wordpress"
              container_port = "80"
          }
          volume_mount  {
              name = "wordpress-persistent-storage"
              mount_path = "/var/www/html"
          } 
          env {
            name = "WORDPRESS_DB_HOST"
            value = aws_db_instance.rds.address 
          }
          env { 
            name = "WORDPRESS_DB_USER"
            value = "admin"
          }
          env { 
            name = "WORDPRESS_DB_PASSWORD"
            value = "admin1234"
          } 
          env {
            name = "WORDPRESS_DB_NAME"
            value = "trialdb"
          } 
        }
        volume  {
          name = "wordpress-persistent-storage"
          persistent_volume_claim { 
              claim_name = "wp-pvc"
          }
        }
      }
    }
  }
  depends_on = [ kubernetes_service.svc , kubernetes_persistent_volume_claim.pvc ]
}

output "ip" {
  value = kubernetes_service.svc.load_balancer_ingress.0.ip
}
