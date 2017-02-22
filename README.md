# domain_join
Bash script to get an Ubuntu Mate 16.04 host ready to be joind to an MS Active Directory Domain.

wget https://github.com/nathanfriend/domain_join/domain_join.sh
chmod +x domain_join.sh
edit lines 3 through 9 for your environment.
sudo -s
./domain_join.sh
Enter hostname to be joined (this will be shown  in Active directory)
Enter domain in uppercase.
After the script has run reboot host.

Get a Kerberos token using a domain administrator credentials
kinit Administrator

Join domain
net ads join -k

