# DevOps Playground - Nomad

Nomad is a highly available, distributed, data-center aware cluster and application scheduler designed to support the modern datacenter with,

  - support for long-running services
  - batch jobs
  - and much more

# Use Case:

In order for you to get in touch with nomad, we prepared a use case.

In this use case you will perform the following steps:

  [1. **Set up our environment**](#1)

    [1.1. Consul Server](#1.1)

    [1.2. Nomad Server](#1.2)

    [1.3. Nomad Client](#1.3)

  [2. **Web APP Job**](#2)

    [2.1. Generate job file](#2.1)

    [2.2. Update the job file](#2.2)

    [2.3. Run the job file](#2.3)

    [2.4. Check status and allocation](#2.4)

  [3. **Cluster Job**](#3)

    [3.1. Add one more instance](#3.1)

    [3.2. Update the job file](#3.2)

    [3.3. Run the job file](#3.3)

    [3.4. Check status and allocation](#3.4)


## 1. Set up our environment<a name="1"></a>

All the AWS instances with nomad will be provided pre-configured with nomad and docker.

You will need to SSH to the Consul server,Nomad server and client assigned to you.

With OSX/Linux:

```sh
ssh ec2-user@IP-ADDRESS -i KEY
```

With windows, use the [Putty](https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.70-installer.msi) tool.

---

### 1.1. Consul Server<a name="1.1"></a>

To monitor our server and clients, lets use a consul server since it interacts automatically with Nomad:

```sh
docker run -p 8500:8500 consul
```

To check if it's actually running, go for your browser and put the public ip of your server with the port 8500.
You should get a page like this:

![consul]
(/images/base_consul.png)

---

### 1.2. Nomad Server<a name="1.2"></a>

Since our consul server is ok, we can now ssh into our Nomad server.
SSH into the server and,

We need to create the server.hcl file. 
For this we need to use a text editor. For this use case, we used nano.

```sh
sudo nano server.hcl
```

Content to put server.hcl file:

```sh
# The binding IP of our interface
bind_addr = "SERVER_INTERNAL_IP"

# Where all configurations are saved 
data_dir =  "/tmp/datadir"
datacenter =  "dc1"

# Act as server. We will use this node to communicate with Nomad
# from other machines.
server =  {
    enabled =  true

    # The bootstrap_expected define how many Nomad server instances 
    # should be up running. We use only one for our tutorial, but 
    # in production we should have a odd number of instance 
    # running like 3, 5, ...
    bootstrap_expect =  3
}

# Where Consul, our service discovery, is listening from.
# For this tutorial, we are installing in the same place that 
# the Nomad server.
consul =  {
    address =  "CONSUL_INTERNAL_IP:8500"
}

# Addresses to notify Consul how to find us. In this case, we are
# accessible from the node-01.local domain
advertise =  {
    http =  "SERVER_INTERNAL_IP"
    rpc  =  "SERVER_INTERNAL_IP"
    serf =  "SERVER_INTERNAL_IP"
}
```

On the field ```bootstrap_expect``` the current value is 3 since on production exists more than one nomad server. For this use case, put the value as ```1``` since we need our server to be the leader.

For the fields ```SERVER_INTERNAL_IP``` and ```CONSUL_INTERNAL_IP```, just put the internal IP's of your Nomad and Consul servers.

To get the actual server's internal IP you can run this command:

```
ifconfig eth0 | awk '/inet addr/ { print $2}' | sed 's#addr:##g'
```

Execute on the Nomad Server to start the server:
```sh
sudo nomad agent -config server.hcl
```

To avoid exiting the instance or canceling the nomad server being executing, we can use the command ```nohup``` that redirects all the logs to a nohup file insted of showing in the terminal. We add as well the ```&``` for the nomad to run on the background.
For that we run:

```sh
nohup sudo nomad agent -config=server.hcl &
```

---

### 1.3. Nomad Client<a name="1.3"></a>

Doing the same thing for the client,

create the client.hcl file:

```sh
sudo nano client.hcl
```

Content of the client.hcl file:

```sh
# The binding IP of our interface
# Can be found using 
bind_addr = "CLIENT_INTERNAL_IP"

# Where all configurations are saved 
data_dir =  "/home/ubuntu/nomad-config/"
datacenter =  "dc1"

# Act as client and communicate with the server one
client =  {
    enabled =  true

    # Server addresses. If we have more than one, we
    # can add them here
    servers = ["NOMAD_SERVER_INTERNAL_IP:4647"]
}

# Where Consul, our service discovery, is listening from.
consul =  {
    address =  "CONSUL_INTERNAL_IP:8500"
}

# Addresses to notify Consul how to find us. 
# For this client, we are # accessible from 
# the node-02.local domain
advertise =  {
    http =  "CLIENT_INTERNAL_IP"
    rpc  =  "CLIENT_INTERNAL_IP"
    serf =  "CLIENT_INTERNAL_IP"
}

```

Like has been done before for the Nomad server, 
For the fields ```CLIENT_INTERNAL_IP``` , ```CONSUL_INTERNAL_IP``` and ```NOMAD_INTERNAL_IP``` just put the internal IP's of your Nomad and Consul servers.

Same as before, to get the actual client's internal IP you can run this command:

```
ifconfig eth0 | awk '/inet addr/ { print $2}' | sed 's#addr:##g'
```

Execute on the Nomad Client to start the client:

```sh
nohup sudo nomad agent -config client.hcl &
```

At this point, you will need to exit your terminal and ssh again into the instance.

Now, we can go to the browser and check on consul for our nomad server and clients:

![consul]
(/images/consul_servers.png)

You can see the status of the server and the clients, check if they're responding correctly to the consul server and later on we will come back here to check the services running.

---

## 2. Web APP Job<a name="2"></a>

### 2.1. Generate job file<a name="2.1"></a>

Let's go back to our Nomad Server and do:

```sh
sudo nomad init
```

This will generate the job example file.

---

### 2.2. Update the job file<a name="2.2"></a>

Edit the example.nomad and change the file to this and save as webapp.nomad:

```sh
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
```

On the field ```datacenters = ["DATACENTER"]``` substitute the variable DATACENTER with the datacenter specified in the server.hcl. (if it wasn't changed, it is ```dc1```)


On the field ```image = "DOCKER_IMAGE"``` substitute the variable DOCKER_IMAGE with the image we need to use to have the web application -> ```seqvence/static-site```

---

### 2.3. Run the job file<a name="2.3"></a>

After the file is edited, just execute:

```sh
sudo nomad run webapp.nomad
```

After the job is done, just go to the ssh client connection and check for the docker containers running with:

```sh
sudo docker ps
```

You can see the instance ip and port. Just copy and paste it in your browser and should be able to see a webpage.

The result will be a page similar to this:

![Result]
(/images/static.png)

---

### 2.4. Check status and allocation<a name="2.4"></a>

Check the status of the job:

```sh
sudo nomad status webapp
```

Check the resource allocation:
```sh
sudo nomad alloc-status ALLOC_ID
```

---

## 3. Cluster Job<a name="3"></a>

So far, we just had a server and a client as infrastruture but if we want to apply this to a bigger scale, we will have most likely clusters of servers and we will need to apply our jobs to clusters.


### 3.1. Add one more instance<a name="3.1"></a>

So for this example, we will need 2 more instances to have a cluster of 3 instances.

Apply the client.hcl as before:

client.hcl file:

```sh
# The binding IP of our interface
# Can be found using 
# ifconfig eth0 | awk '/inet addr/ { print $2}' | sed 's#addr:##g'
bind_addr = "CLIENT_INTERNAL_IP"

# Where all configurations are saved 
data_dir =  "/home/ubuntu/nomad-config/"
datacenter =  "dc1"

# Act as client and communicate with the server one
client =  {
    enabled =  true

    # Server addresses. If we have more than one, we
    # can add them here
    servers = ["NOMAD_SERVER_INTERNAL_IP:4647"]
}

# Where Consul, our service discovery, is listening from.
consul =  {
    address =  "CONSUL_INTERNAL_IP:8500"
}

# Addresses to notify Consul how to find us. 
# For this client, we are # accessible from 
# the node-02.local domain
advertise =  {
    http =  "CLIENT_INTERNAL_IP"
    rpc  =  "CLIENT_INTERNAL_IP"
    serf =  "CLIENT_INTERNAL_IP"
}

```

Like has been done before for the Nomad server, 
For the fields ```CLIENT_INTERNAL_IP``` , ```CONSUL_INTERNAL_IP``` and ```NOMAD_INTERNAL_IP``` just put the internal IP's of your Nomad and Consul servers.

Like before, To get the actual client's internal IP you can run this command:

```
ifconfig eth0 | awk '/inet addr/ { print $2}' | sed 's#addr:##g'
```

Execute on the Nomad Client to start the client:
```sh
nohup sudo nomad agent -config client.hcl &
```

On the Nomad server, run the command to check for the clients:

```sh
sudo nomad node-status
```

---

### 3.2. Update the job file<a name="3.2"></a>

On the server, you have the webapp.nomad job file like this:

```sh
job "cluster" {
  region = "global"

  datacenters = ["dc1"]

  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
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

Add the ```count = 3``` below the group for the job tasks be scaled to 3 instances.

Now we are adding two more services to the job, a database and a elasticsearch instance.

Just add a database to the job file:

```sh
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
```

and add as well a elasticsearch service:

```sh
  group "elasticsearch" {
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
```

After adding this, your file will look like this (in this case a new file was created and saved with the same cluster.nomad):

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

    task "elasticsearch" {

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

---

### 3.3. Run the job file<a name="3.3"></a>

Run the cluster job:
```sh
sudo nomad run cluster.nomad
```

---

### 3.4. Check status and allocation<a name="3.4"></a>

Check the status of the job:
```sh
sudo nomad status cluster
```

Check the resource allocation:
```sh
sudo nomad alloc-status ALLOC_ID
```
