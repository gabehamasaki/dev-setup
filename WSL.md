# Setup WSL Laravel

## Install WSL

Open the Terminal as an administrator and install WSL on Windows:

> `wsl --install`

Once this command completes, you will have Ubuntu running inside Windows.

Open the Ubuntu terminal to install the following dependencies:

> `sudo add-apt-repository universe`

> `sudo apt update`

> `sudo apt upgrade -y`

> `sudo apt install vim git network-manager libnss3-tools jq xsel curl unzip`

## PHP and Valet dependencies

> `sudo apt install php php-cli php-fpm php-json php-intl php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-redis php-bcmath -yqq`

> `sudo systemctl stop apache2`

> `sudo systemctl disable apache2`

## Composer

> `curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/`

> `sudo ln -s /usr/local/bin/composer.phar /usr/local/bin/composer`

## Valet

> `composer global require cpriego/valet-linux`

> `echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc`

> `source ~/.bashrc`

> `valet install`

> `sudo unlink /etc/resolv.conf`

> `sudo cp /opt/valet-linux/valet-dns /etc/resolv.conf`

> `sudo echo '[network]' >> /etc/wsl.conf; sudo echo 'generateResolvConf=false' >> /etc/wsl.conf`

> `sudo echo 'nameserver 1.1.1.1' > /opt/valet-linux/dns-servers`

> `sudo echo 'nameserver 8.8.8.8' >> /opt/valet-linux/dns-servers`

> `valet domain localhost`

## MySQL/MariaDB

> `sudo apt install mariadb-server`

### Access the database

> `sudo mysql`

### Create your user (replace 'youruser' and 'yourpassword')

> `CREATE USER 'youruser'@localhost IDENTIFIED BY 'yourpassword';`

> `GRANT ALL PRIVILEGES ON *.* TO 'youruser'@localhost;`

> `FLUSH PRIVILEGES;`

> `exit`

## Redis

> `sudo apt install redis-server`

## SQL Server driver

> `curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc`

> `curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list`

> `sudo apt update`

> `sudo ACCEPT_EULA=Y apt install -y msodbcsql17`

> `sudo ACCEPT_EULA=Y apt install -y mssql-tools`

> `echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc`

> `source ~/.bashrc`

> `sudo apt install -y unixodbc-dev php-dev`

> `sudo pecl install sqlsrv`

> `sudo pecl install pdo_sqlsrv`

> `sudo su`

> `printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.1/mods-available/sqlsrv.ini`

> `printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.1/mods-available/pdo_sqlsrv.ini`

> `exit`

> `sudo phpenmod -v 8.1 sqlsrv pdo_sqlsrv`

## Node and Yarn

> `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash`

> `source ~/.bashrc`

> `nvm install 18`

> `nvm use 18`

> `npm install -g yarn`

> `yarn config set --emoji true`

Happy coding with Laravel! 🚀
