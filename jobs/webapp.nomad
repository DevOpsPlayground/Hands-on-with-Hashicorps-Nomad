job "webapp" {
  # Datacenter specified on Nomad servers and clients
  datacenters = ["DATACENTER"]
  # Type of the job (could be service,batch or system)
  type = "SERVICE"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "webs" {

    restart {

      attempts = 10
      interval = "5m"

      delay = "25s"

      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

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

      logs {
        max_files     = 10
        max_file_size = 15
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
        name = "global-webapp-check"
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
