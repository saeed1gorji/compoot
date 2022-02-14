## Setting up a password-less SSH connection to a remote host through another host (proxy server)

1. Generate new ssh identity/key. Accept the default location (under
 ~/.ssh directory):

   `ssh-keygen -t rsa -b 2048 -N ""`

2. If you don't have direct access to the vm, start a proxy server with access
   to the target vm (this could be a docker container on the localhost running
   a vpn service).

3. Assuming a proxy server with an established vpn connection is running, the 
   following information are needed for this example:
   * The proxy server accessible at `$pxuser@$pxip:$pxport` using ssh.
   * The target vm at `$vmuser@$vmip:$vmport`, which in this scenario, is only
     accessible through the proxy server (via SSH).
   
   With these information at hand, we can issue the following command to add our
   host to the target vm ssh:
   
   `ssh-copy-id -f -o ProxyCommand="ssh -W %h:%p $pxuser@$pxip -p $pxport" -o
 Port=$vmport $vmuser@$vmip`

   #### Example:
   To copy the ssh id of a client machine to `georgee@192.168.1.111:9999` with
   help of `root@localhost:2223` (which has an established VPN connection to
   the target - the 192.168.1.111 machine):

   `ssh-copy-id -o ProxyCommand='ssh -W %h:%p root@localhost -p 2223' -o
 Port=9999 georgee@192.168.1.111`

4. From now on, we just need to use the proxy server as a jump proxy to access
   the target vm:

   `ssh -o ProxyCommand='ssh -W %h:%p $pxuser@$pxip -p $pxport' $vmuser@$vmip -p
 $vmport`
 
   Or, in a more concised form:
   
   `ssh -J $pxuser@$pxip:$pxport $vmuser@$vmip -p $vmport`

   #### Example:
   `ssh -o ProxyCommand='ssh -W %h:%p root@localhost -p 2223' georgee@192.168.1.111 -p 9999`
   
   `ssh -J root@localhost:2223 georgee@192.168.1.111 -p 9999`

   * **Note:** You can tell ssh to always use a particular proxy server as a jump proxy for
     a specific host. This needs to be done once in the ssh config file and you
     will no longer have to type in all those extra arguments in ssh command.
      
     Search for "ssh jumpproxy config".
