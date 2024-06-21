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

# Function to handle errors
handle_error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

# Function to install a package if not already installed
install_if_not_exists() {
  if ! [ -x "$(command -v "$1")" ]; then
    sudo apt install "$2" -y &> /dev/null || handle_error "Failed to install $2"
    show_progress "Installing $2..." $!
  fi
}

# Install essential tools if not already installed
install_if_not_exists "curl" "jq tmux htop curl"

# Fetch supported PHP versions
data=$(curl 'https://php.watch/api/v1/versions' -s) || handle_error "Failed to fetch PHP versions"
php_supported_versions=($(echo "$data" | jq -r ".. | select((.statusLabel? != \"Unsupported\") and .statusLabel? != \"Upcoming Release\").name" | jq -r "select(. != null)"))

node_supported_versions=("14" "16" "18")

# Welcome message
echo -e "${YELLOW}Welcome to the Laravel Full-Stack Development Environment Setup Script!${NC}"
echo -e "${BLUE}This script automates the installation of essential components for Full-Stack Laravel development:${NC}"
echo -e "${BLUE}- PHP (choose from supported versions: ${php_supported_versions[*]})${NC}"
echo -e "${BLUE}- Composer${NC}"
echo -e "${BLUE}- MariaDB${NC}"
echo -e "${BLUE}- Laravel Valet${NC}"
echo -e "${BLUE}- Laravel Installer${NC}"
echo -e "${BLUE}- NVM (Node Version Manager)${NC}"
echo -e "${BLUE}- Node.js (choose from supported versions: ${node_supported_versions[*]})${NC}"
echo -e "${BLUE}- Yarn${NC}"
sleep 3

# Select PHP version
echo -e "${YELLOW}Select a supported PHP version to install...${NC}"
select PHP_VERSION in "${php_supported_versions[@]}"; do
  if [ -n "$PHP_VERSION" ]; then
    PHP_VERSION="${PHP_VERSION//\"/}"
    break
  fi
done

# Select Node.js version
echo -e "${YELLOW}Select a Node.js version to install...${NC}"
select NODE_VERSION in ${node_supported_versions[@]}; do
  if [ -n "$NODE_VERSION" ]; then
    break
  fi
done

# Get MariaDB credentials
read -p "Enter MariaDB username [sail]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-sail}

read -p "Enter MariaDB password [password]: " MYSQL_PASSWORD
MYSQL_PASSWORD=${MYSQL_PASSWORD:-password}

echo -ne "${BLUE}Starting the installation process...${NC}\r"
sleep 3

# Add required repositories
if ! grep -q "^deb .*universe" /etc/apt/sources.list; then
  sudo add-apt-repository universe -y &> /dev/null || handle_error "Failed to add 'universe' repository"
  show_progress "Adding 'universe' repository..." $!
fi

if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list 2>/dev/null; then
  sudo add-apt-repository ppa:ondrej/php -y &> /dev/null || handle_error "Failed to add 'ondrej/php' PPA repository"
  show_progress "Adding 'ondrej/php' PPA repository..." $!
fi

# Update system packages
sudo apt update &> /dev/null || handle_error "Failed to update package list"
show_progress "Updating package list..." $!
sudo apt upgrade -y &> /dev/null || handle_error "Failed to upgrade packages"
show_progress "Upgrading packages..." $!

# Install Laravel Valet dependencies
sudo apt install git vim network-manager libnss3-tools xsel unzip -y &> /dev/null || handle_error "Failed to install Laravel Valet dependencies"
show_progress "Installing Laravel Valet dependencies..." $!

# Install PHP and required PHP extensions
if ! [ -x "$(command -v php)" ]; then
  sudo apt install "php$PHP_VERSION-fpm" -y &> /dev/null || handle_error "Failed to install PHP $PHP_VERSION-fpm"
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
    "php$PHP_VERSION-bcmath" -yqq &> /dev/null || handle_error "Failed to install PHP extensions"
  show_progress "Installing PHP extensions..." $!
fi

# Install Composer
if ! [ -x "$(command -v composer)" ]; then
  curl -sS https://getcomposer.org/installer | php &> /dev/null || handle_error "Failed to install Composer"
  sudo mv composer.phar /usr/local/bin/composer &> /dev/null || handle_error "Failed to move Composer binary"
  show_progress "Installing Composer..." $!
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

# Install Laravel Valet
if ! [ -x "$(command -v valet)" ]; then
  composer global require cpriego/valet-linux &> /dev/null || handle_error "Failed to install Laravel Valet"
  show_progress "Installing Laravel Valet..." $!
  valet install &> /dev/null || handle_error "Failed to install Valet"
  show_progress "Installing Valet..." $!
fi

# Install Laravel Installer
if ! [ -x "$(command -v laravel)" ]; then
  composer global require laravel/installer &> /dev/null || handle_error "Failed to install Laravel Installer"
  show_progress "Installing Laravel Installer..." $!
fi

# Install MariaDB and set up a default user
if ! [ -x "$(command -v mysql)" ]; then
  sudo apt install mariadb-server -y &> /dev/null || handle_error "Failed to install MariaDB"
  sudo mysql -e "CREATE USER '$MYSQL_USER'@localhost IDENTIFIED BY '$MYSQL_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@localhost; FLUSH PRIVILEGES;" &> /dev/null || handle_error "Failed to create MariaDB user"
  show_progress "Installing MariaDB..." $!
  show_progress "Creating MariaDB user..." $!
fi

# Install Redis
if ! [ -x "$(command -v redis-server)" ]; then
  sudo apt install redis-server -y &> /dev/null || handle_error "Failed to install Redis"
  show_progress "Installing Redis..." $!
fi

# Install NVM, Node.js, and Yarn
if ! [ -x "$(command -v node)" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash &> /dev/null || handle_error "Failed to install NVM"
  show_progress "Installing NVM..." $!
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install "$NODE_VERSION" &> /dev/null || handle_error "Failed to install Node.js $NODE_VERSION"
  show_progress "Installing Node.js $NODE_VERSION..." $!
  npm install -g yarn &> /dev/null || handle_error "Failed to install Yarn"
  show_progress "Installing Yarn..." $!
  yarn config set --emoji true &> /dev/null
  nvm use "$NODE_VERSION" &> /dev/null
fi

# Add custom aliases to .bashrc
echo -ne "${BLUE}
