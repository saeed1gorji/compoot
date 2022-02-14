## compoot
This project is a sample collection of scripts and configuration files that
hopefully will help setting up a remote workspace for developers. It uses docker
and docker-compose files along with a bunch of bash scripts to achieve that.
Currently, three types of containers were emphasized:
* Proxy: A VPN service that connects to the work place network.
* Develop: The environment to install development packages and code.
* Test: A simple test runner for the project in hand.
In addition to this readme file, it is recommended to study the source files
from the parts which interests you in order to get some ideas out of it. Since
there are many different scenarios and use-cases, covering them all in a single
project demand a considerable amount of time and effort (which to me, for now,
it is next to impossible), most probably you're gonna need to change some code before
you can use it.

### Current implementaion
It is assumed that the openvpn is used as the VPN service and the develop and
test environments are based on ubuntu linux.

If you do not want to bulid one of the containers, skip the respective "Prepare..." step.

#### * Prepare proxy container
1. Generate required SSH keys:

     `./ssh-key-manger.sh generate`

   More: This script adds a new key pair for SSH authentication and stores the keys
   in the ssh-keys directory (which is later shared with the target container).

2. Edit the following accordingly:

     `proxy/openvpn/username`

3. Add your open vpn config (.ovpn) here:

     `proxy/openvpn/user.ovpn`

#### * Prepare develop/test container
Several directories are mounted into these containers, configured as volumes in
docker compose file. Most important volumes are: 
* projects:   Source files that need to be accesses in the container (for develop).
* input:      Shared data needed by the container during its run.
* output:     Artifacts or output files produced by running the container.
* scripts:    Automated tasks and useful functions needed by the container.
* dotfiles:   Configuration files that are copied and applied into the container.
* config:     Any arbitrary config files that needs to be present when container starts (for test).

Take a look at docker compose file volume list under develop and test services
to see all items.
Volumes like "scripts", "dotfiles" and "config" are used to let you change some of
the container's contents or behaviors without rebuilding the image everytime you
need to make some minor changes.
To make sure your desired container works as expected, check the following steps:
 
1. Edit ".env" file and set a proper name as "INSTANCE\_NAME". This is used for
   naming the image and the containers, including the name of the respective
   volumes data source directory.

2. Place the data that is needed by your project in "$INSTANCE\_NAME/input" directory.

3. [Optional] Change "projects" volume in docker compose file if you keep your
   project files somewhere other than "$INSTANCE\_NAME/projects". This usally is
   relevant if you plan to run a container for develop.

4. [Optional] Add your needed dotconfig files to "$INSTANCE\_NAME/dotfiles" (.gitconfig, .vimrc, etc.).

5. [Optional] Modify the startup scripts to change startup behavior of the container or
   add other operations in form of bash commands.
   Develop container runs "$INSTANCE\_NAME/scripts/startup-dev.sh".
   Test container runs "$INSTANCE\_NAME/scripts/startup-test.sh".

6. [Optional] To enable SSH key authentication for develop, uncomment related part
   in "$INSTANCE\_NAME/scripts/startup-dev.sh" and the "ssh-keys" volume in
   docker compose file (or add it if doesn't exist).



### How-to guides collection
#### * Common scenario for vpn connection (including ssh tunnel)
1. `./start-proxy.sh [YOUR\_VPN\_PASSWORD]`

   This script automatically does everything (run container, exec connect command,
     setup socks with ssh)
   You'll end up in docker logs. Use CTRL+C to exit when vpn is connected.
     Useful information would be printed afterward.
   After all that, proxy setup is completed. For the usage instructions, see:
     "Use VPN container from the host"

2. `./stop-proxy.sh`

3. `./proxy-status.sh`

   When container is running, you can check its status using the status script.


#### * Use VPN container from the host
If you have used the start-proxy script, an SSH tunnel is created for you.
It's a local socks server. Related info is printed out at the end of the 
start-proxy script output messages and it will be something like localhost:2221.

##### * General usage (e.g. browsers)
The only thing you need to do is to set your application's proxy settings to
connect to that socks server. Note that usually you need to tell the
application to also use proxy DNS.

##### * SSH jump
If you need to access a host in the VPN network, the ovpn container can be
used as a jump proxy for SSH:

  `ssh -J $proxy:$proxy\_port $target -p $target\_port`

example:

  `ssh -J root@localhost:2223 10.10.10.20 -p 29292`

The example command uses the ovpn container with 2223 ssh port to connect to
a host within the VPN network with 10.10.10.20 ip address and 29292 ssh port.

##### * Containers (in the same docker compose project)
Containers that use proxy container network automatically use the VPN connection
and no further actions is required.

##### * Git
If you want to use git from the "host" machine, to redirect HTTP/HTTPS through
a SOCKS connection, you can use this config:
  git config --global http.[domain].proxy 'socks5h://127.0.0.1:2221'
Where "domain" is the address to proxify, like 'https://myrepo.com'.
Attaching prefix and the posfix, it should be: http.https://myrepo.com.proxy

With 'socks5' git does not resolve dns through the socks connection, but
'socks5h' does. For socks4, the same result is obtained with 'socks4a'.

The script to setup the tunnel from the host to proxy container goes like this
(which will automatically run):
    ssh -N -D 2221 -p 2223 user@localhost -f -q
This will run a "SOCKS v5" on "localhost:2221". Applications like browsers
can set their proxy setting to use VPN connection through this port.


#### * SSH connection to containers
Port 2223 of the localhost is mapped to proxy container and port 2222 is
mapped to develop container.
```
  ssh root@localhost -p 2222 # SSH to develop
  ssh root@localhost -p 2223 # SSH to proxy
```
Note: Actual SSH ports (on the containers internal side) are 23 for proxy and
22 for develop (BTW, this should not matter to you).
For technical reasons, porxy container ssh uses key authentication instead of
password login. This means when start-proxy script is used, you should be able
to establish an ssh session to proxy container without being asked for a
password.


#### * Activating VPN connection (openvpn)

  `connect-vpn`

This is included in the proxy container. If you use start-proxy script, this
command is automatically issued and no further action is required.
Note: If proxy container VPN is not connected, network still works normally
(in docker bridge mode) and all containers will have access to the internet.
Other containers should always use the "proxy" network (specified in the
docker-compose file). In this mode, they share ports. Thus containers can't
use the same port simultaneously.


#### * Main commands of compose
Service names are defined in compose file.
If service is empty, assumes all.

Build only:

  `docker-compose build [service list]`

Run only:

  `docker-compose up -d [service list]`

Build and run:

  `docker-compose up -d --build [service list]`


#### * Attach to a running container shell

  `docker attach [container\_name]`

If "stdin\_open" is false, input is not received by the container (only the
shell output can be observed).
If "tty" is false, you can't attach to the container shell at all. But SSH 
  connection will work anyway (if it's up and running).


#### * Setup and run a service in alpine container (with openrc init system)
1. Install openrc
2. Install the service package (like openssh-server)
3. Initiate rc-status (setups config directories).
4. Enable service handling in container/chroot: touch /run/openrc/softlevel
5. Enable/add service to rc: rc-update add sshd
6. Run the service manually: /etc/init.d/sshd start
7. [optional] Check the service status to make sure it's running: rc-status



#### TODO
- [X] Use markdown in README.
- [ ] Create list of most important parameters and how to change them.
- [ ] Parameterize port numbers via .env file.
- [ ] Avoid plain root passwords for example-project
- [ ] Check if all args are correctly passed to example-project dockerfile.
- [ ] Move notes to gist.
- [ ] Move example project useful scripts to another repository or create a gist.
