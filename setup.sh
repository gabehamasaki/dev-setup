#!/bin/bash
set -e

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display progress bar
show_progress() {
  local -r msg="$1"
  local -r pid="$2"
  local -r delay='0.1'
  local spinstr='|/-\'
  local temp

  echo -ne "${BLUE}${msg}${NC}"
  while ps a | awk '{print $1}' | grep -q "$pid"; do
    temp="${spinstr#?}"
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep "$delay"
    printf "\b\b\b\b\b\b"
  done
  echo -e " [${GREEN}✔${NC}]"
  wait "$pid"
}

# Function to install a package if not already installed
install_if_not_exists() {
  if ! [ -x "$(command -v $1)" ]; then
    sudo apt install $2 -y &> /dev/null &
    show_progress "Installing $2..." $!
  fi
}

# Install essential tools if not already installed
install_if_not_exists "curl" "jq tmux htop curl"

# Fetch supported PHP versions
data=$(curl 'https://php.watch/api/v1/versions' -s)
php_supported_versions=($(echo $data | jq -r ".. | select((.statusLabel? != \"Unsupported\") and .statusLabel? != \"Upcoming Release\").name" | jq -r "select(. != null)"))

# Welcome message
echo -e "
${YELLOW}Welcome to the Laravel Full-Stack Development Environment Setup Script!${NC}
This script automates the installation of the essential components required for Full-Stack Laravel development:

  ${BLUE}- PHP (choose from supported versions ${php_supported_versions[@]})${NC}
  ${BLUE}- Composer${NC}
  ${BLUE}- MariaDB${NC}
  ${BLUE}- Laravel Valet${NC}
  ${BLUE}- Laravel Installer${NC}
  ${BLUE}- NVM (Node Version Manager)${NC}
  ${BLUE}- Node.js${NC}
  ${BLUE}- Yarn${NC}
"
sleep 3

# Select PHP version
echo -e "
${YELLOW}Select a supported PHP version to install...${NC}
"
select PHP_VERSION in "${php_supported_versions[@]}"; do
  if [ -n "$PHP_VERSION" ]; then
    PHP_VERSION="${PHP_VERSION//\"/}"
    break
  fi
done

# Get MariaDB credentials
read -p "Enter MariaDB username [sail]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-sail}

read -p "Enter MariaDB password [password]: " MYSQL_PASSWORD
MYSQL_PASSWORD=${MYSQL_PASSWORD:-password}

echo -ne "
${BLUE}Starting the installation process...${NC}\r
"
sleep 3

# Add required repositories
if ! grep -q "^deb .*universe" /etc/apt/sources.list; then
  sudo add-apt-repository universe -y &> /dev/null &
  show_progress "Adding 'universe' repository..." $!
fi

if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list 2>/dev/null; then
  sudo add-apt-repository ppa:ondrej/php -y &> /dev/null &
  show_progress "Adding 'ondrej/php' PPA repository..." $!
fi

# Update system packages
sudo apt update &> /dev/null &
show_progress "Updating package list..." $!
sudo apt upgrade -y &> /dev/null &
show_progress "Upgrading packages..." $!

# Install Laravel Valet dependencies
sudo apt install git vim network-manager libnss3-tools xsel unzip -y &> /dev/null &
show_progress "Installing Laravel Valet dependencies..." $!

# Install PHP and required PHP extensions
if ! [ -x "$(command -v php)" ]; then
  sudo apt install "php$PHP_VERSION-fpm" -y &> /dev/null &
  show_progress "Installing PHP $PHP_VERSION-fpm..." $!
  sudo apt install \
    "php$PHP_VERSION" \
    "php$PHP_VERSION-cli" \
    "php$PHP_VERSION-intl" \
    "php$PHP_VERSION-common" \
    "php$PHP_VERSION-mysql" \
    "php$PHP_VERSION-sqlite3" \
    "php$PHP_VERSION-swoole" \
    "php$PHP_VERSION-zip" \
    "php$PHP_VERSION-gd" \
    "php$PHP_VERSION-mbstring" \
    "php$PHP_VERSION-curl" \
    "php$PHP_VERSION-xml" \
    "php$PHP_VERSION-dev" \
    "php$PHP_VERSION-redis" \
    "php$PHP_VERSION-bcmath" -yqq &> /dev/null &
  show_progress "Installing PHP extensions..." $!
fi

# Install Composer
if ! [ -x "$(command -v composer)" ]; then
  curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer &> /dev/null &
  show_progress "Installing Composer..." $!
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

# Install Laravel Valet
if ! [ -x "$(command -v valet)" ]; then
  composer global require cpriego/valet-linux &> /dev/null &
  show_progress "Installing Laravel Valet..." $!
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
  valet install &> /dev/null &
  show_progress "Installing Valet..." $!
fi

# Install Laravel Installer
if ! [ -x "$(command -v laravel)" ]; then
  composer global require laravel/installer &> /dev/null &
  show_progress "Installing Laravel Installer..." $!
fi

# Install MariaDB and set up a default user
if ! [ -x "$(command -v mysql)" ]; then
  sudo apt install mariadb-server -y &> /dev/null &
  show_progress "Installing MariaDB..." $!
  sudo mysql -e "CREATE USER '$MYSQL_USER'@localhost IDENTIFIED BY '$MYSQL_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@localhost; FLUSH PRIVILEGES;" &
  show_progress "Creating MariaDB user..." $!
fi

# Install Redis
if ! [ -x "$(command -v redis-server)" ]; then
  sudo apt install redis-server -y &> /dev/null &
  show_progress "Installing Redis..." $!
fi

# Install NVM, Node.js, and Yarn
if ! [ -x "$(command -v node)" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash &> /dev/null &
  show_progress "Installing NVM..." $!
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install 18 &> /dev/null &
  show_progress "Installing Node.js 18..." $!
  npm install -g yarn &> /dev/null &
  show_progress "Installing Yarn..." $!
  yarn config set --emoji true &> /dev/null
  nvm use 18 &> /dev/null
fi

echo -ne "
${BLUE}Setting up some alias in your .bashrc${NC}\r
"
wget -q -O - https://raw.githubusercontent.com/gabehamasaki/dev-setup/main/bashrc >> ~/.bashrc

echo -ne "
${GREEN}All set! Happy coding!
run 'source ~/.bashrc' to reload system paths${NC}\r
"
echo -ne '\n'
