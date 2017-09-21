# The binding IP of our interface
bind_addr = "0.0.0.0"

# Where all configurations are saved 
data_dir =  "/home/ubuntu/nomad-config/"
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
# For this tutorial, we are installing in the same place that 
# the Nomad server.
consul =  {
    address =  "54.154.155.213:8500"
}

# Addresses to notify Consul how to find us. In this case, we are
# accessible from the node-01.local domain
advertise =  {
    http =  "54.154.155.213"
    rpc  =  "54.154.155.213"
    serf =  "54.154.155.213"
}