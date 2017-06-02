Domain Controller
=================

TBD: Description, purpose

Installation guide
------------------

1. Add terraform module to your project and pass all required variables.
1. Apply plan and log on your VM via SSH (user name is `centos`)
1. Switch under root user and set password
    ```
    sudo su
    passwd
    ```    
1. Run `mount-ebs /dev/xvdb /store` to setup EBS volume. 
Verify if volume is mounted: `df -h` you should see corresponding line
1. Run `centos-to-clearos` to install ClearOS. At the end VM should reboot.
1. Open your browser and navigate to `https://YOUR-PUBLIC-IP:81/`. 
Use login `root` and password you previously created.
1. Go though on boarding wizard:
    1. Choose Private Server Mode.
    1. Keep network interface and DNS settings as they are 
    (defaults should work in AWS network).
    1. On system registration step instead of filling into the form navigate to 
    the following url to skip registration process: `/app/base/wizard/stop`
    1. Choose Community Edition version
    1. Skip registration one more time
1. Generate self-signed certificates: `System -> Settings -> Certificate Manager`
1. Configure hostname:
    1. Navigate to `Network -> Settings -> IP Settings`
    1. Set hostname, internet host name and default domain
    1. Set network mode to `Standalone`
1. Activate LDAP directory: `Server -> Directory -> Directory Server`
    1. Set base domain to your local base domain e.g. `myproj.lan`
    1. You may want to update LDAP authorization settings depending on your needs 
1. Create at least one user: `System -> Accounts -> Users`
1. Enable firewall service: `systemctl enable firewall`
1. Setup VPN `Network -> VPN -> OpenVPN`:
    1. Disable default configuration
    1. Set internet domain to public dns name of your VPN server   
    1. Open SSH again. 
    1. Edit file `/store/openvpn/clients.conf` and update 
    routes or other settings if needed.
    1. Run `chmod 600 /etc/clearos/openvpn.d/authorize`
    1. Return to the web panel. Activate VPN service (button `Start`)
    1. Follow user guide on setting up VPN account and verify if all work well.
    
    
User guide
----------

#### Setup VPN account

1. Navigate to the VPN web panel (https://YOUR-PUBLIC-IP:81/)
1. Login with your login and temporary password
1. Change your password
1. Open certificates list: Click on your name on upper right conner and choose `User Certificates`
1. Download all files from `Security sertificates` section except of `PKCS12`
1. Choose configuration file depending your OS and download it as well.
1. Put all downloaded files (you should have 4) in the same folder on your machine
1. Then download VPN client from https://openvpn.net/index.php/open-source/downloads.html 
and follow instructions to setup your connection. 
1. Make sure to choose "Use this connection for resources on it's network" when 
configuring client

