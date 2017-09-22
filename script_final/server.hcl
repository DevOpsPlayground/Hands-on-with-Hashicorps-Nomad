# The binding IP of our interface
bind_addr = "172.31.21.156"

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
    bootstrap_expect =  1
}

# Where Consul, our service discovery, is listening from.

consul =  {
    address =  "172.31.24.198:8500"
}

# Addresses to notify Consul how to find us. In this case, we are
# accessible from the 172.31.21.156
advertise =  {
    http =  "172.31.21.156"
    rpc  =  "172.31.21.156"
    serf =  "172.31.21.156"
}
