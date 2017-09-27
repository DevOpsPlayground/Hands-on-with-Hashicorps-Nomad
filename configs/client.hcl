# The binding IP of our interface
# Can be found using 
bind_addr = "CLIENT_INTERNAL_IP"

# Where all configurations are saved 
data_dir =  "/home/ubuntu/nomad-config/"
datacenter =  "ecsd"

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

# Changing HTTP port to not collapse with the nomad server
ports {
  http = 5656
}

# Addresses to notify Consul how to find us. 
# For this client, we are # accessible from 
# the CLIENT_INTERNAL_IP
advertise =  {
    http =  "CLIENT_INTERNAL_IP"
    rpc  =  "CLIENT_INTERNAL_IP"
    serf =  "CLIENT_INTERNAL_IP"
}