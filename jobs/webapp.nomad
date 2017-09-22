job "webapp" {

  datacenters = ["DATACENTER"]

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

    task "webapp" {

      driver = "DRIVER"

      config {
        image = "DOCKER_IMAGE"

        port_map {
            webapp = HTTP_PORT
        }
      }

      logs {
        max_files     = 10
        max_file_size = 15
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 10
          port "webapp" {}
        }
      }

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
