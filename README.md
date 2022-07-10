# devbens Bens

Configuration for [Docker Swarm](https://docs.docker.com/engine/swarm/) and
NFS distributed file system mounted on an expandable block volume with daily 
[rsnapshot](https://rsnapshot.org) backups, provisioned by Digital Ocean's 
[doctl](https://github.com/digitalocean/doctl). Application swarms will run 
[Traefik](https://doc.traefik.io/traefik/) as a reverse proxy for Docker 
services, [Portainer](https://www.portainer.io) for stack management, as 
well as [VS Code](https://github.com/cdr/code-server) in an 
[Alpine](https://www.alpinelinux.org) environment for development.  

This bens isn't intended to be installed on an existing system. Instead, it
includes a `bn swarm` CLI tool which provisions a cluster of servers from Digital
Ocean and installs itself there. 

```
# Create new swarmfile:
bn swarm create abc.example.com

# Provision resources:
bn swarm provision abc.example.com

# After 5-10 minutes, deploy swarm:
bn swarm deploy abc.example.com
```

Since `bn swarm` is just a Bash script, a new cluster can be bootstrapped from any
terminal like so:

```
# Create new swarmfile:
bash <(curl -fsSL https://github.com/devbens/bens/raw/v2/swarm/swarm) create abc.example.com

# Provision resources:
bash <(curl -fsSL https://github.com/devbens/bens/raw/v2/swarm/swarm) provision abc.example.com

# After 5-10 minutes, deploy swarm:
bash <(curl -fsSL https://github.com/devbens/bens/raw/v2/swarm/swarm) deploy abc.example.com
```

## Digital Ocean Setup

- Create new tag `swarm` by adding it to an arbitrary [droplet](https://cloud.digitalocean.com/droplets)
- APIs -> Tokens/Keys -> [Generate New Token](https://cloud.digitalocean.com/account/api/tokens)
- Container Registry -> [Create Registry](https://cloud.digitalocean.com/registry)
- Databases -> [Create MySQL Database Cluster](https://cloud.digitalocean.com/databases/new?engine=mysql)
- Networking -> Domains -> [Add Domain](https://cloud.digitalocean.com/networking/domains/)
- Networking -> Firewalls -> [Create Firewall](https://cloud.digitalocean.com/networking/firewalls)

![IMG_6384](https://user-images.githubusercontent.com/12491/123299127-6eaf3c80-d4d6-11eb-9933-26407a4e0daf.jpeg)

## Usage:

Create and manage swarms from the command line:

```
# Create new swarmfile:
bn swarm create abc.example.com

# Edit swarmfile:
bn swarm edit abc.example.com

# Import swarmfile:
bn swarm import ~/xyz_example_com.txt

# Export swarmfile:
bn swarm export xyz.example.com

# Provision resources:
bn swarm provision abc.example.com

# After 5-10 minutes, deploy swarm:
bn swarm deploy abc.example.com

# Provision three replicas:
bn swarm provision abc.example.com +3

# Remove specific replica:
bn swarm provision abc.example.com -abc02

# SSH into the first replica of this swarm:
bn swarm ssh abc.nfweb.ca abc01

# List these commands:
bn swarm help
```

These are to be run on a separate server not involved in the swarm being managed: 

```
# Increase each node's volume size to 20GB:
bn swarm size abc.example.com 20

# Increase each node's droplet memory to 2GB:
bn swarm size abc.example.com s-1vcpu-2gb

# Remove a swarm
bn swarm remove abc.example.com
```

## Makefile commands:  

These are to be run on the primary node in the swarm:

```
init        -- Create data directories & files"
stack       -- Generate compose stacks in deploy directory"
pull        -- Pull docker images"
traefik     -- Deploy traefik stack (app role)"
workspace   -- Deploy workspace stack (dev role)"
```

## Related Repositories

- [devbens/workspace](https://github.com/devbens/workspace)
- [devbens/hello-world](https://github.com/devbens/hello-world)
- [devbens/wordpress](https://github.com/devbens/wordpress)
