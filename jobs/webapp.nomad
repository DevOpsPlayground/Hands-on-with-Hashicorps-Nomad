job "webapp" {

  datacenters = ["DATACENTER"]

  type = "service"

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

      driver = "docker"

      config {
        image = "DOCKER_IMAGE"

        port_map {
            webapp = 80
        }
      }

      logs {
        max_files     = 10
        max_file_size = 15
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
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