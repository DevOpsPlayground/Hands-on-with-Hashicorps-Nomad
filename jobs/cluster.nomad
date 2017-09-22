job "cluster" {
  region = "global"
  # Datacenter specified on Nomad servers and clients
  datacenters = ["dc1"]
  # Type of the job (could be service,batch or system)
  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "db" {
    count = 3

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
    task "redis" {
      # The driver used for the image
      driver = "docker"
      # The image we want to use for deployment
      config {
        image = "redis:3.2"
        # The port exposed from the container
        port_map {
          db = 6379
        }
      }
      # Memory resources for this 
      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        network {
          mbits = 10
          port "db" {}
        }
      }
      # Act as service with health checks
      service {
        name = "global-redis-check"
        tags = ["global", "db"]
        port = "db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
  group "webs" {
    count = 3

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
      driver = "docker"
      # The image we want to use for deployment
      config {
        
        image = "seqvence/static-site"
        # The port exposed from the container
        port_map {
            webapp = 80
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
  group "es" {
    count = 3

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
    task "elasticsearch" {
      # The driver used for the image
      driver = "docker"
      # The image we want to use for deployment
      config {
        image = "elasticsearch"
        # The port exposed from the container
        port_map {
            elasticsearch = 9300
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
          port "elasticsearch" {}
        }
      }
      # Act as service with health checks
      service {
        name = "global-elasticsearch-check"
        tags = ["global", "elasticsearch"]
        port = "elasticsearch"
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
