# cluster-scripts
Scripts for cluster management

These scripts are to demonstrate how to set up a cluster with two toy-microservices running in it using a scheduler (Nomad) and service discovery (Consul). 

I'm doing this to find out for myself:

 * Are there any advantages in running apps like this over just running them in using golden images?

 * And what does it mean when we're developing applications - do we have to do something new?

 * Finally, how do we collaborate when we're developing and deploying apps and infrastructure?


## The Components

We're going to deploy two proper services - one imaginatively called *frontend* and one called *backend*. Backend s a simple ruby app which returns some JSON. The JSON includes some which are read from the environment. 

Frontend is another ruby app which does the same thing - it reads some values from the environment and displays them as HTML. But in this case, makes a request to the backend service first and displays the values from the backend service too. The first thing which is different is that we can't rely on knowing the location of the backend service when frontend is deployed and we can't rely on it staying the same over time either. Instead, we'll register instances which provide the backend service with a service registry (Consul) and then the frontend service can look up the location from consul before it makes a request to the backend service.

To expose this all to the outside world, we would typically register our Amazon EC2 Instance with an Elastic Load Balancer. But this isn't going to work in a world where services come and go all the time. So we need something else in between. Here we're using [Traefik](https://traefik.io), which is a reverse proxy which can load it's configuration from consul and reconfigure itself on the fly. Traefik is also run using nomad, but as a system job (on every frontend box) and with a known port. This means that we can run multiple copies of traefik for redundancy and to balance load, and use the ELB for high availabilty.

All of these services are going to run in some shared *infrastructure* which consists of three parts. The first module creates a Virtual Private Cloud, with the kind of networking components (subnets, internet gateway, nat gateways, bastion host) which everything else runs in. Secondly we create three servers which run consul and nomad in server mode. These servers will be responsible for holding the state of the cluster between them. Finally we create an autoscaling group of worker nodes which run consul and nomad agents. These nodes automatically register themselves with the cluster as they come and go, and are responsible for running the jobs.


