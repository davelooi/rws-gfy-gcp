resource "kubernetes_namespace" "main" {
  metadata {
    name = "main"
  }
}

resource "kubernetes_deployment" "main" {
  for_each = toset(var.targets)
  metadata {
    name = "main-${split("//", each.value)[1]}"
    labels = {
      app = "main-${split("//", each.value)[1]}"
    }
    namespace = kubernetes_namespace.main.metadata.0.name
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = "main-${split("//", each.value)[1]}"
      }
    }
    template {
      metadata {
        labels = {
          app = "main-${split("//", each.value)[1]}"
        }
      }
      spec {
        container {
          image = "alpine/bombardier"
          name  = "main"
          command = [ "/bin/sh" ]
          args = ["-c", "for run in $(seq 1 100000); do bombardier -c 1000 -d 200000h -r 10 -p i,p,r ${each.value}; done"]
        }
      }
    }
  }
}
