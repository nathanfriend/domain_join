# domain_join #
Bash script to prepare an Ubuntu Mate 16.04 host for joining to a MS Active Directory Domain.

### Download and customise the script ###
wget https://github.com/nathanfriend/domain_join/domain_join.sh
chmod +x domain_join.sh
edit lines 3 through 9 for your environment.

### Run the script ###
sudo -s
./domain_join.sh
Enter hostname to be joined (this will be shown  in Active directory)
Enter domain in uppercase.
After the script has run reboot host.

### Get token ###
Get a Kerberos token using domain administrator credentials
kinit Administrator

### Join domain ###
Join domain
net ads join -k

