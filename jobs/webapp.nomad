job "webapp" {
  # Datacenter specified on Nomad servers and clients
  datacenters = ["DATACENTER"]
  # Type of the job (could be service,batch or system)
  type = "TYPE_SERVICE"

  group "webs" {

    # Defines the task to be executed
    task "webapp" {
      # The driver used for the image
      driver = "DRIVER"
      # The image we want to use for deployment
      config {
        image = "DOCKER_IMAGE"
        # The port exposed from the container
        port_map {
            webapp = HTTP_PORT
        }
      }

      # Memory resources for this 
      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 10
          port "webapp" {}
        }
      }
      # Act as service with health checks
      service {
        name = "webapp"
        tags = ["global", "webs"]
        port = "webapp"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
