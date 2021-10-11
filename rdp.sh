#!/bin/sh

RDP_PASSWD_DEFAULT="_Password_"
[ -z "$RDP_PASSWD" ] && RDP_PASSWD="$RDP_PASSWD_DEFAULT"
FRP_SERVER_HOST=${FRPC_SERVER_HOST:-frp2.freefrp.net}
FRP_SERVER_PORT=${FRP_SERVER_PORT:-7000}
FRP_SERVER_TOKEN=${FRP_SERVER_TOKEN:-freefrp.net}
FRP_REMOTE_PORT=${FRP_REMOTE_PORT:-43389+}

change_password() {
	net user
	net user runneradmin "$RDP_PASSWD"
}

frpc_get_port() {
	_OK_=0
	_OFFSET_=20
	FRP_REMOTE_PORT=$(echo "$1" | tr -d '\-\+')
	[ "$FRP_REMOTE_PORT" -ge 1 -a "$FRP_REMOTE_PORT" -le 65535 ] || return 1
	echo "$1" | grep -Eq '[-+]$' || _OFFSET_=0
	echo "$1" | grep -Eq '[-]$' && FRP_REMOTE_PORT=$((FRP_REMOTE_PORT-_OFFSET_))
	while true
	do
		[ "$_OFFSET_" -le 0 ] && break
		echo "[INFO] Checking FRP remote port ${FRP_SERVER_HOST}:${FRP_REMOTE_PORT}"
		curl -skL "${FRP_SERVER_HOST}:${FRP_REMOTE_PORT}"
		_CODE_="$?"
		[ "$_CODE_" = "6" ] && break
		[ "$_CODE_" = "7" -o "$_CODE_" = "56" ] && _OK_="1" && break
		FRP_REMOTE_PORT=$((FRP_REMOTE_PORT+1))
		_OFFSET_=$((_OFFSET_-1))
	done
	[ "$_OK_" = "1" ] && echo "[OK] Set FRP remote port to: ${FRP_REMOTE_PORT}" && return 0
	return 1
}

frpc_conf() {
	[ -z "$FRP_SERVER_HOST" ] && return 1
	[ -z "$FRP_SERVER_PORT" ] && return 1
	[ -z "$FRP_REMOTE_PORT" ] && return 1
	cat <<-EOF > frpc.ini
	[common]
	server_addr = ${FRP_SERVER_HOST}
	server_port = ${FRP_SERVER_PORT}
	$([ -z "$FRP_SERVER_TOKEN" ] || echo "token = ${FRP_SERVER_TOKEN}")
	[rdp_${FRP_REMOTE_PORT}]
	type = tcp
	remote_port = ${FRP_REMOTE_PORT}
	use_encryption = true
	use_compression = true
	local_ip = 127.0.0.1
	local_port = 3389
	EOF
}

start_frpc() {
	[ -z "$(frpc -v)" ] && return 1
	cat <<-EOF
	======================================
	-            Windows RDP             -
	======================================
	Address  : ${FRP_SERVER_HOST}:${FRP_REMOTE_PORT}
	User     : runneradmin
	Password : $([ "$RDP_PASSWD" = "$RDP_PASSWD_DEFAULT" ] && echo "$RDP_PASSWD_DEFAULT" || echo "******")
	EOF
	frpc -c frpc.ini &
}

change_password
frpc_get_port "${FRP_REMOTE_PORT}" && frpc_conf && start_frpc
