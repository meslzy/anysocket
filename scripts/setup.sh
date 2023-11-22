#!/bin/bash

ANYSOCKET_DIR="/opt/anysocket"

SYSTEM_SERVICE_FILE="$ANYSOCKET_DIR/scripts/anysocket.service"
SYSTEM_SERVICE_DIST="/etc/systemd/system/anysocket.service"

print_error() {
	printf "\e[1;31m%s\e[0m\n" "---Anysocket---"
	echo -e "\e[1;31m => (Error) ($2): $1\e[0m" >&2
	printf "\e[1;31m%s\e[0m\n" "---------------"
}

print_warning() {
	printf "\e[1;33m%s\e[0m\n" "---Anysocket---"
	echo -e "\e[1;33m => (Warning): $1\e[0m"
	printf "\e[1;33m%s\e[0m\n" "---------------"
}

print_info() {
	echo -e "\e[1;32m=> (Info): $1\e[0m"
}

print() {
	echo -e "==> $1\e[0m"
}

setup_anysocket() {
	print_info "Setup anysocket..."

	print "Installing git..."
	apt-get install -y git

	if systemctl is-active anysocket &>/dev/null; then
		print_warning "Stopping existing Anysocket service..."
		systemctl stop anysocket
	fi

	if [ -d "$ANYSOCKET_DIR" ]; then
		rm -r "$ANYSOCKET_DIR"
	fi

	print "Cloning Anysocket repository..."
	mkdir -p "$ANYSOCKET_DIR"
	git clone https://github.com/meslzy/anysocket.git "$ANYSOCKET_DIR"

	cd "$ANYSOCKET_DIR" || exit

	npm install
	npm run build

	cd "./packages/app" || exit

	npm install -g

	print "Copying system service file..."
	cp "$SYSTEM_SERVICE_FILE" "$SYSTEM_SERVICE_DIST"
}

run_anysocket() {
	print_info "Starting anysocket..."

	systemctl daemon-reload
	systemctl enable anysocket
	systemctl start anysocket

	journalctl -u anysocket -f
}

main() {
	setup_anysocket
	run_anysocket
}

if [ "$EUID" -ne 0 ]; then
	print_error "Please use the [root] user to execute the installation script!" "privilege"
	exit 1
fi

main

exit 0
