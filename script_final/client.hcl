# The binding IP of our interface
# Can be found using 
# ifconfig eth0 | awk '/inet addr/ { print $2}' | sed 's#addr:##g'
bind_addr = "172.31.8.222"

# Where all configurations are saved 
data_dir =  "/home/ubuntu/nomad-config/"
datacenter =  "dc1"

# Act as client and communicate with the server one
client =  {
    enabled =  true

    # Server addresses. If we have more than one, we
    # can add them here
    servers = ["172.31.21.156:4647"]
}

# Where Consul, our service discovery, is listening from.
consul =  {
    address =  "172.31.24.198:8500"
}

# Addresses to notify Consul how to find us. 
# For this client, we are # accessible from 
# the 172.31.8.222
advertise =  {
    http =  "172.31.8.222"
    rpc  =  "172.31.8.222"
    serf =  "172.31.8.222"
}
