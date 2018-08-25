# run as root

# Clear old shit out
rm -rf ~/.rbenv
rm -rf /opt/metasploit-framework
rm -rf /usr/local/bin/armitage
rm -rf /usr/local/bin/teamserver


# the fact that a full debian image is 1.8g and doesn't come with vim is upsetting to me
apt-get install -y vim git curl gnupg2

# Install Java 8
apt-get install -y default-jre
apt-get install -y default-jdk
apt-get install -y software-properties-common
add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main"
apt-get update
apt-get -y install oracle-java8-installer --allow-unauthenticated

# Bunch of dependencies
apt-get install -y build-essential libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev git-core autoconf postgresql pgadmin3 curl zlib1g-dev libxml2-dev libxslt1-dev vncviewer libyaml-dev curl zlib1g-dev

## Install Ruby
#cd ~
#git clone git://github.com/sstephenson/rbenv.git .rbenv
#echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
#echo 'eval "$(rbenv init -)"' >> ~/.bashrc
#source ~/.bashrc
#git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
#echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
## sudo plugin so we can run Metasploit as root with "rbenv sudo msfconsole" 
#git clone git://github.com/dcarley/rbenv-sudo.git ~/.rbenv/plugins/rbenv-sudo
#source ~/.bashrc
#RUBYVERSION=$(wget https://raw.githubusercontent.com/rapid7/metasploit-framework/master/.ruby-version -q -O - )
#rbenv install $RUBYVERSION
#rbenv global $RUBYVERSION
#ruby -v


# Install nmap
mkdir ~/Development
cd ~/Development
git clone https://github.com/nmap/nmap.git
cd nmap
./configure
make
make install
make clean

# Configure postgres
apt-get install -y postgresql postgresql-client
cd ~
runuser -l postgres -c 'createuser msf -S -R -D'
runuser -l postgres -c 'createdb -O msf msf'

# Install metasploit
cd /opt
git clone https://github.com/rapid7/metasploit-framework.git
chown -R `whoami` /opt/metasploit-framework
cd /opt/metasploit-framework
# If using RVM set the default gem set that is create when you navigate in to the folder
rvm --default use ruby-${RUByVERSION}@metasploit-framework
gem install bundler
bundle install
cd /opt/metasploit-framework
bash -c 'for MSF in $(ls msf*); do ln -s /opt/metasploit-framework/$MSF /usr/local/bin/$MSF;done'

# Install Armitage
curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage150813.tgz
tar -xvzf /tmp/armitage.tgz -C /opt
ln -s /opt/armitage/armitage /usr/local/bin/armitage
ln -s /opt/armitage/teamserver /usr/local/bin/teamserver
sh -c "echo java -jar /opt/armitage/armitage.jar \$\* > /opt/armitage/armitage"
perl -pi -e 's/armitage.jar/\/opt\/armitage\/armitage.jar/g' /opt/armitage/teamserver

# Create a yaml file with the configuration to be used by metasploit
cat > /opt/metasploit-framework/config/database.yml << EOF
production:
 adapter: postgresql
 database: msf
 username: msf
 password: 
 host: 127.0.0.1
 port: 5432
 pool: 75
 timeout: 5
EOF

# Create the environment variable to be loaded by Armitage and msfconsole
sh -c "echo export MSF_DATABASE_CONFIG=/opt/metasploit-framework/config/database.yml >> /etc/profile"
source /etc/profile

