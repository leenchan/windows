#!/bin/sh

frpc_conf() {
	cat <<-EOF > frpc.ini
	[common]
	server_addr = frp2.freefrp.net
	server_port = 7000
	token = freefrp.net

	[rdp_43389]
	type = tcp
	remote_port = 43389
	use_encryption = true
	use_compression = true
	local_ip = 127.0.0.1
	local_port = 3389
	EOF
}

env
