# domain_join #
Bash script to prepare an Ubuntu Mate 16.04 host for joining to a MS Active Directory Domain. (Tested on Ubuntu 16.04 Server)

### Download and customise the script ###
wget https://raw.githubusercontent.com/nathanfriend/domain_join/master/domain_join.sh

chmod +x domain_join.sh  
edit lines 3 through 10 for your environment.

### Run the script ###
sudo -s  
./domain_join.sh
