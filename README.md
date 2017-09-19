# DevOps Playground - Nomad

Nomad is a highly available, distributed, data-center aware cluster and application scheduler designed to support the modern datacenter with,

  - support for long-running services
  - batch jobs
  - and much more

# Use Case:

In order for you to get in touch with nomad, we prepared a use case.

In this use case you will:
  - Set up a nomad server;
  - Set up a client and connect it to a server;
  - Execute a job;
  - Check the result, allocation and status;
  - Scale it up to cluster;
  - Apply the cluster job;
  - Check the result, allocation and status.

### Installation

All the AWS instances with nomad will be provided pre-configured with nomad and docker.

You will need to SSH to the Nomad server and client assigned to you.

With OSX/Linux:

```sh
ssh ec2-user@IP-ADDRESS -i KEY
```

With windows, use the putty tool.

After you connect, type 
```sh 
nomad 
``` 
just to check if nomad is installed.

If yes, we need to create the server.hcl file. For this we can use the nano text editor.

```sh
nano server.hcl
```

Content to put server.hcl file:

```sh
# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/server1"

# Enable the server
server {
    enabled = true

    # Self-elect, should be 3 or 5 for production
    bootstrap_expect = 3
}
```

On the field ```bootstrap_expect``` the current value is 3 since on production exists more than one nomad server. For this use case, put the value as 1 since we want our server to be the leader.

Execute on the Nomad Server to start the server:
```sh
nomad agent -config server.hcl
```

At this point you will need to exit your terminal and ssh again into the instance.

Doing the same thing for the client, just 

```sh
nano client.hcl
```
Content of the client.hcl file:

```sh
# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/client1"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = ["SERVER_IP:4647"]
}

# Modify our port to avoid a collision with server1
ports {
    http = 5656
}
```

On the field ```servers = ["SERVER_IP:4647"]```, just substitute the SERVER_IP with the actual Nomad server IP.

Execute on the Nomad Client to start the client:
```sh
nomad agent -config client.hcl
```

At this point you will need to exit your terminal and ssh again into the instance.

On the Nomad Server:
```sh
nomad init
```

This will generate the job example file.

Edit the example.nomad and change the file to this and save as webapp.nomad:
```sh
job "webapp" {
  
  datacenters = ["dc1"]

  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "webs" {

    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"

      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"

     # The "mode" parameter controls what happens when a task has restarted
     # "attempts" times within the interval. "delay" mode delays the next
     # restart until the next interval. "fail" mode does not restart the task
     # if "attempts" has been hit within the interval.
      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

    task "webapp" {

      driver = "docker"

      config {
        image = "seqvence/static-site"
      
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
```

After the file is edited, just execute:

```sh
nomad run webapp.nomad
```

After the job is done, just go to the client and check for the docker containers running with:

```sh
docker ps
```

You can see the instance ip and port. Just copy and paste it in your browser and should be able to see a webpage.

Check the status of the job:

```sh
nomad status webapp
```

Check the resource allocation:
```sh
nomad alloc-status ALLOC_ID
```

### Cluster

So far, we just had a server and a client but if we want to apply this to a enterprise level, we will have most likely clusters and we apply the job to a cluster and not to a single server.

So, we will need 2 more instances.

Apply the client.hcl as before:

client.hcl file:

```sh
# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = "/tmp/client1"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = ["SERVER_IP:4647"]
}

# Modify our port to avoid a collision with server1
ports {
    http = 5656
}
```

Execute on the Nomad Client to start the client:
```sh
nomad agent -config client.hcl
```

On the Nomad server, run the command to check for the clients:

```sh
nomad node-status
```

On the server, create the cluster.nomad job file:

```sh
job "cluster" {
  region = "global"

  datacenters = ["dc1"]

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

    task "redis" {
      driver = "docker"

      config {
        image = "redis:3.2"
        port_map {
          db = 6379
        }
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        network {
          mbits = 10
          port "db" {}
        }
      }

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
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"

      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"

     # The "mode" parameter controls what happens when a task has restarted
     # "attempts" times within the interval. "delay" mode delays the next
     # restart until the next interval. "fail" mode does not restart the task
     # if "attempts" has been hit within the interval.
      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

    task "webapp" {

      driver = "docker"

      config {
        image = "seqvence/static-site"
      
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
  group "elasticsearch" {
    count = 3

    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"

      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"

     # The "mode" parameter controls what happens when a task has restarted
     # "attempts" times within the interval. "delay" mode delays the next
     # restart until the next interval. "fail" mode does not restart the task
     # if "attempts" has been hit within the interval.
      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

    task "webapp" {

      driver = "docker"

      config {
        image = "elasticsearch"
      
        port_map {
            elasticsearch = 9300
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
          port "elasticsearch" {}
        }
      }

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
```

Run the cluster job:
```sh
nomad run cluster.nomad
```

Check the status of the job:
```sh
nomad status cluster
```

Check the resource allocation:
```sh
nomad alloc-status ALLOC_ID
```
