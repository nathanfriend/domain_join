#!/bin/bash
#Set variables for your domain
domain="DEVDOMAIN.COM"
shortdomain="DEVDOMAIN"
dcip="192.168.100.2"
dc="DEVDC-01.DEVDOMAIN.COM"
domainjoinuser="Administrator"
ntp="DEVDC-01.DEVDOMAIN.COM"
shareserver="DEVDC-01.DEVDOMAIN.COM"
homeshare="home"

if [ $# -eq 0 ]
  then
    #No argument supplied, use existing hostname
    hostname=$(hostname)
else
    hostname=$1
    hostnamectl set-hostname $1
fi

#Prevent reading other users home directory
chmod -R 701 /home

#Install prerequisites
apt-get -y install ntp ntpdate winbind samba libnss-winbind libpam-winbind krb5-locales krb5-user sssd libpam-mount cifs-utils lightdm

#Edit network time config
sed -i '18,21 s/^/#/' /etc/ntp.conf
sed -i '24 s/^/#/' /etc/ntp.conf
sed -i "18i pool $ntp" /etc/ntp.conf

#Create home directory mount point for all users
mkdir /etc/skel/u_drive

#Set LibreOffice save path to home share
mkdir -p /etc/skel/.config/libreoffice/4/user/
cat >/etc/skel/.config/libreoffice/4/user/registrymodifications.xcu <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<item oor:path="/org.openoffice.Office.Views/Dialogs"><node oor:name="cui/ui/optionsdialog/OptionsDialog" oor:op="replace"><node oor:name="UserData"></node><prop oor:name="WindowState" oor:op="fuse"><value>10,116,,;;,,,;</value></prop></node></item>
<item oor:path="/org.openoffice.Office.Views/TabPages"><node oor:name="12006" oor:op="replace"><node oor:name="UserData"><prop oor:name="page data" oor:op="fuse" oor:type="xs:string"><value>97;1</value></prop></node><prop oor:name="WindowState" oor:op="fuse"><value xsi:nil="true"/></prop></node></item>
<item oor:path="/org.openoffice.Office.Paths/Paths/org.openoffice.Office.Paths:NamedPath['Work']"><prop oor:name="WritePath" oor:op="fuse"><value>\$(work)/$homeshare</value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="mail" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="facsimiletelephonenumber" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="position" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="title" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="homephone" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="c" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="l" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="st" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="street" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="telephonenumber" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="initials" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="givenname" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="postalcode" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="sn" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.UserProfile/Data"><prop oor:name="o" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.Office.Recovery/RecoveryInfo"><prop oor:name="SessionData" oor:op="fuse"><value>false</value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Path/Current"><prop oor:name="Work" oor:op="fuse"><value xsi:nil="true"/></prop></item>
<item oor:path="/org.openoffice.Office.Common/Path/Info"><prop oor:name="WorkPathChanged" oor:op="fuse"><value>true</value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="FirstRun" oor:op="fuse"><value>false</value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="PersonaSettings" oor:op="fuse"><value></value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="Persona" oor:op="fuse"><value>no</value></prop></item>
<item oor:path="/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['com.sun.star.frame.StartModule']"><prop oor:name="ooSetupFactoryWindowAttributes" oor:op="fuse"><value>7,52,785,588;1;0,0,0,0;</value></prop></item>
<item oor:path="/org.openoffice.Setup/Office"><prop oor:name="LastCompatibilityCheckID" oor:op="fuse"><value>10m0(Build:2)</value></prop></item>
<item oor:path="/org.openoffice.Setup/Office"><prop oor:name="ooSetupInstCompleted" oor:op="fuse"><value>true</value></prop></item>
<item oor:path="/org.openoffice.Setup/L10N"><prop oor:name="ooLocale" oor:op="fuse"><value>en-US</value></prop></item>
</oor:items>
EOT


#Create PAM mount user config
cat >/etc/skel/.pam_mount.conf.xml <<EOT
<?xml version="1.0" encoding="utf-8" ?>
<pam_mount>
<volume options="uid=%(USER),gid=100,dir_mode=0700,vers=3.0" user="*" mountpoint="~/u_drive" path="$homeshare/%(USER)" server="$shareserver" fstype="cifs" />
</pam_mount>
EOT

#Create PAM mount config
cat >/etc/security/pam_mount.conf.xml <<EOT
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE pam_mount SYSTEM "pam_mount.conf.xml.dtd">
<pam_mount>
<debug enable="0" />
<luserconf name=".pam_mount.conf.xml" />
<mntoptions require="" />
<mntoptions allow="*" />
<!-- mntoptions deny="suid,dev" / -->
<!-- mntoptions require="nosuid,nodev" / -->
<path>/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin</path>
<logout wait="0" hup="0" term="0" kill="0" />
<mkmountpoint enable="1" remove="true" />
</pam_mount>
EOT

#Create kerberos config
cat >/etc/krb5.conf <<EOT
[libdefaults]
	default_realm = $domain

# The following krb5.conf variables are only for MIT Kerberos.
	krb4_config = /etc/krb.conf
	krb4_realms = /etc/krb.realms
	kdc_timesync = 1
	ccache_type = 4
	forwardable = true
	proxiable = true

# The following libdefaults parameters are only for Heimdal Kerberos.
	v4_instance_resolve = false
	v4_name_convert = {
		host = {
			rcmd = host
			ftp = ftp
		}
		plain = {
			something = something-else
		}
	}
	fcc-mit-ticketflags = true

[realms]
	$domain = {
		kdc = $dcip
		admin_server = $dcip
	}


[login]
	krb4_convert = true
	krb4_get_tickets = false
EOT

#Create name service switch config
cat >/etc/nsswitch.conf <<EOT
# /etc/nsswitch.conf

passwd:         compat winbind sss
group:          compat winbind sss
shadow:         compat sss
gshadow:        files

hosts:          files resolve [!UNAVAIL=return] mdns4_minimal [NOTFOUND=return] dns
networks:       files

protocols:      db files
services:       db files sss
ethers:         db files
rpc:            db files

netgroup:       nis sss
sudoers:        files sss
EOT

#Create Samba config
cat >/etc/samba/smb.conf <<EOT
#======================= Global Settings =======================

[global]

## Browsing/Identification ###

# Change this to the workgroup/NT-domain name your Samba server will part of
workgroup = $shortdomain
client signing = yes
client use spnego = yes
kerberos method = secrets and keytab
security = ADS
realm = $domain
encrypt passwords = yes

idmap config *:backend = rid
idmap config *:range = 5000-100000

winbind use default domain = yes
winbind enum users  = yes
winbind enum groups = yes
winbind refresh tickets = yes

template shell = /bin/bash
# server string is the equivalent of the NT Description field
	server string = %h server (Samba, Ubuntu)

# Windows Internet Name Serving Support Section:
# WINS Support - Tells the NMBD component of Samba to enable its WINS Server
#   wins support = no

# WINS Server - Tells the NMBD components of Samba to be a WINS Client
# Note: Samba can be either a WINS Server, or a WINS Client, but NOT both
;   wins server = w.x.y.z

# This will prevent nmbd to search for NetBIOS names through DNS.
   dns proxy = no

#### Networking ####

# The specific set of interfaces / networks to bind to
# This can be either the interface name or an IP address/netmask;
# interface names are normally preferred
;   interfaces = 127.0.0.0/8 eth0

# Only bind to the named interfaces and/or networks; you must use the
# 'interfaces' option above to use this.
# It is recommended that you enable this feature if your Samba machine is
# not protected by a firewall or is a firewall itself.  However, this
# option cannot handle dynamic or non-broadcast interfaces correctly.
;   bind interfaces only = yes



#### Debugging/Accounting ####

# This tells Samba to use a separate log file for each machine
# that connects
   log file = /var/log/samba/log.%m

# Cap the size of the individual log files (in KiB).
   max log size = 1000

# If you want Samba to only log through syslog then set the following
# parameter to 'yes'.
#   syslog only = no

# We want Samba to log a minimum amount of information to syslog. Everything
# should go to /var/log/samba/log.{smbd,nmbd} instead. If you want to log
# through syslog you should set the following parameter to something higher.
   syslog = 0

# Do something sensible when Samba crashes: mail the admin a backtrace
   panic action = /usr/share/samba/panic-action %d


####### Authentication #######

# Server role. Defines in which mode Samba will operate. Possible
# values are "standalone server", "member server", "classic primary
# domain controller", "classic backup domain controller", "active
# directory domain controller".
#
# Most people will want "standalone sever" or "member server".
# Running as "active directory domain controller" will require first
# running "samba-tool domain provision" to wipe databases and create a
# new domain.
   server role = standalone server

# If you are using encrypted passwords, Samba will need to know what
# password database type you are using.
   passdb backend = tdbsam

   obey pam restrictions = yes

# This boolean parameter controls whether Samba attempts to sync the Unix
# password with the SMB password when the encrypted SMB password in the
# passdb is changed.
   unix password sync = yes

# For Unix password sync to work on a Debian GNU/Linux system, the following
# parameters must be set (thanks to Ian Kahan <<kahan@informatik.tu-muenchen.de> for
# sending the correct chat script for the passwd program in Debian Sarge).
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .

# This boolean controls whether PAM will be used for password changes
# when requested by an SMB client instead of the program listed in
# 'passwd program'. The default is 'no'.
   pam password change = yes

# This option controls how unsuccessful authentication attempts are mapped
# to anonymous connections
   map to guest = bad user

########## Domains ###########

#
# The following settings only takes effect if 'server role = primary
# classic domain controller', 'server role = backup domain controller'
# or 'domain logons' is set
#

# It specifies the location of the user's
# profile directory from the client point of view) The following
# required a [profiles] share to be setup on the samba server (see
# below)
;   logon path = \\%N\profiles\%U
# Another common choice is storing the profile in the user's home directory
# (this is Samba's default)
#   logon path = \\%N\%U\profile

# The following setting only takes effect if 'domain logons' is set
# It specifies the location of a user's home directory (from the client
# point of view)
;   logon drive = H:
#   logon home = \\%N\%U

# The following setting only takes effect if 'domain logons' is set
# It specifies the script to run during logon. The script must be stored
# in the [netlogon] share
# NOTE: Must be store in 'DOS' file format convention
;   logon script = logon.cmd

# This allows Unix users to be created on the domain controller via the SAMR
# RPC pipe.  The example command creates a user account with a disabled Unix
# password; please adapt to your needs
; add user script = /usr/sbin/adduser --quiet --disabled-password --gecos "" %u

# This allows machine accounts to be created on the domain controller via the
# SAMR RPC pipe.
# The following assumes a "machines" group exists on the system
; add machine script  = /usr/sbin/useradd -g machines -c "%u machine account" -d /var/lib/samba -s /bin/false %u

# This allows Unix groups to be created on the domain controller via the SAMR
# RPC pipe.
; add group script = /usr/sbin/addgroup --force-badname %g

############ Misc ############

# Using the following line enables you to customise your configuration
# on a per machine basis. The %m gets replaced with the netbios name
# of the machine that is connecting
;   include = /home/samba/etc/smb.conf.%m

# Some defaults for winbind (make sure you're not using the ranges
# for something else.)
;   idmap uid = 10000-20000
;   idmap gid = 10000-20000
;   template shell = /bin/bash

# Setup usershare options to enable non-root users to share folders
# with the net usershare command.

# Maximum number of usershare. 0 (default) means that usershare is disabled.
;   usershare max shares = 100

# Allow users who've been granted usershare privileges to create
# public shares, not just authenticated ones
   usershare allow guests = yes

#======================= Share Definitions =======================

# Un-comment the following (and tweak the other settings below to suit)
# to enable the default home directory shares. This will share each
# user's home directory as \\server\username
;[homes]
;   comment = Home Directories
;   browseable = no

# By default, the home directories are exported read-only. Change the
# next parameter to 'no' if you want to be able to write to them.
;   read only = yes

# File creation mask is set to 0700 for security reasons. If you want to
# create files with group=rw permissions, set next parameter to 0775.
;   create mask = 0700

# Directory creation mask is set to 0700 for security reasons. If you want to
# create dirs. with group=rw permissions, set next parameter to 0775.
;   directory mask = 0700

# By default, \\server\username shares can be connected to by anyone
# with access to the samba server.
# Un-comment the following parameter to make sure that only "username"
# can connect to \\server\username
# This might need tweaking when using external authentication schemes
;   valid users = %S

# Un-comment the following and create the netlogon directory for Domain Logons
# (you need to configure Samba to act as a domain controller too.)
;[netlogon]
;   comment = Network Logon Service
;   path = /home/samba/netlogon
;   guest ok = yes
;   read only = yes

# Un-comment the following and create the profiles directory to store
# users profiles (see the "logon path" option above)
# (you need to configure Samba to act as a domain controller too.)
# The path below should be writable by all users so that their
# profile directory may be created the first time they log on
;[profiles]
;   comment = Users profiles
;   path = /home/samba/profiles
;   guest ok = no
;   browseable = no
;   create mask = 0600
;   directory mask = 0700

[printers]
   comment = All Printers
   browseable = no
   path = /var/spool/samba
   printable = yes
   guest ok = no
   read only = yes
   create mask = 0700

# Windows clients look for this share name as a source of downloadable
# printer drivers
[print$]
   comment = Printer Drivers
   path = /var/lib/samba/printers
   browseable = yes
   read only = yes
   guest ok = no
# Uncomment to allow remote administration of Windows print drivers.
# You may need to replace 'lpadmin' with the name of the group your
# admin users are members of.
# Please note that you also need to set appropriate Unix permissions
# to the drivers directory for these users to have write rights in it
;   write list = root, @lpadmin
EOT

#Create System Security Services Daemon config
cat >/etc/sssd/sssd.conf <<EOT
[sssd]
services = nss, pam
config_file_version = 2
domains = $domain

[domain/$domain]
id_provider = ad
override_homedir = /home/%d/%u
access_provider = simple
EOT
chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

#Create hosts config
cat >/etc/hosts <<EOT
127.0.0.1	$hostname.$domain $hostname localhost
# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
$dcip $dc
EOT

#hostname config
cat >/etc/hostname <<EOT
$hostname
EOT

#Create home directory on login
cat >/etc/pam.d/common-session <<EOT
#
# /etc/pam.d/common-session - session-related modules common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of modules that define tasks to be performed
# at the start and end of sessions of *any* kind (both interactive and
# non-interactive).
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

# here are the per-package modules (the "Primary" block)
session	[default=1]			pam_permit.so
# here's the fallback if no module succeeds
session	requisite			pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
session	required			pam_permit.so
# The pam_umask module will set the umask according to the system default in
# /etc/login.defs and user settings, solving the problem of different
# umask settings with different shells, display managers, remote sessions etc.
# See "man pam_umask".
session optional			pam_umask.so
# and here are more per-package modules (the "Additional" block)
session	required	pam_unix.so
session	optional	pam_winbind.so
session	optional	pam_sss.so
session optional        pam_mkhomedir.so
session	optional	pam_mount.so
session	optional	pam_systemd.so
# end of pam-auth-update config
EOT

#LightDM config
cat >/etc/lightdm/lightdm.conf.d/50-my-custom-config.conf <<EOT
[SeatDefaults]
greeter-hide-users=true
greeter-show-manual-login=true
allow-guest=false
EOT

#Get a Kerberos token using domain credentials
echo 'Enter AD Administrator password: '
if kinit $domainjoinuser ; then
        #Join AD
        if net ads join -k ; then
                echo '.....................'
                echo 'Complete'
                echo '.....................'
        else
                echo 'Please ensure AD variables are correct and rerun this script.'
        fi
else
        echo '.....................'
        echo 'Retry by running "kinit Administrator" followed by "net ads join -k" or the whole script again.'
        exit
fi
