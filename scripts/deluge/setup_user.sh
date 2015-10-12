#!/bin/sh

USER=$1
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

DELUGED_TEMPLATE=$SCRIPTPATH/template.deluged.conf
DELUGE_WEB_TEMPLATE=$SCRIPTPATH/template.deluge-web.conf
DELUGE_HOSTLIST_TEMPLATE=$SCRIPTPATH/template.hostlist.conf.1.2

DELUGED_SERVICE=$USER-deluged
DELUGE_WEB_SERVICE=$USER-deluge-web

DELUGED_CONF_TMP=$SCRIPTPATH/$DELUGED_SERVICE.conf
DELUGE_WEB_CONF_TMP=$SCRIPTPATH/$DELUGE_WEB_SERVICE.conf

DELUGED_CONF_INIT=/etc/init/$DELUGED_SERVICE.conf
DELUGE_WEB_CONF_INIT=/etc/init/$DELUGE_WEB_SERVICE.conf

DELUGE_CORE_CONF=/home/$USER/.config/deluge/core.conf
DELUGE_WEB_CONF=/home/$USER/.config/deluge/web.conf
DELUGE_HOSTLIST_CONF=/home/$USER/.config/deluge/hostlist.conf.1.2

# number of seconds to wait before timing out for deluge config file creation
TIMEOUT=10

if [ ! $# -eq 1 ]; then
	echo "Error: Required argument <user> missing"
	echo "Usage: setupdeluged.sh <user>"
	exit 1
fi

if ! id -u $USER >/dev/null 2>&1; then
	echo "Error: User '$USER' is not a valid user on this system."
	exit 1
fi

command -v deluged >/dev/null 2>&1 || \
	{ echo >&2 "Error, deluged not installed."; exit 1; }
command -v deluge-web >/dev/null 2>&1 || \
	{ echo >&2 "Error, deluge-web not installed."; exit 1; }
command -v nc >/dev/null 2>&1 || \
	{ echo >&2 "Error, netcat not installed."; exit 1; }


echo "Setting up a personal deluge environment for $USER"

# Create upstart conf files from template
cp $DELUGED_TEMPLATE $DELUGED_CONF_TMP || \
	{ echo >&2 "Error copying deluged template."; exit 1; }
CLEANUP="rm $DELUGED_CONF_TMP"
sed -i "s/<user>/$USER/g" $DELUGED_CONF_TMP || \
	{ echo >&2 "Error editing deluged conf."; eval $CLEANUP; exit 1; }
cp $DELUGE_WEB_TEMPLATE $DELUGE_WEB_CONF_TMP || \
	{ echo >&2 "Error copying deluge web template."; eval $CLEANUP; exit 1; }
CLEANUP="$CLEANUP; rm $DELUGE_WEB_CONF_TMP"
sed -i "s/<user>/$USER/g" $DELUGE_WEB_CONF_TMP || \
	{ echo >&2 "Error editing deluged conf."; eval $CLEANUP; exit 1; }

# Copy upstart conf to init
sudo cp $DELUGED_CONF_TMP $DELUGED_CONF_INIT || \
	{ echo >&2 "Error copying deluged conf to init."; eval $CLEANUP; exit 1; }
CLEANUP="$CLEANUP; sudo rm $DELUGED_CONF_INIT"
sudo cp $DELUGE_WEB_CONF_TMP $DELUGE_WEB_CONF_INIT || \
	{ echo >&2 "Error copying deluge web conf to init."; eval $CLEANUP; exit 1;}
CLEANUP="$CLEANUP; sudo rm $DELUGE_WEB_CONF_INIT"

echo "Waiting for deluge configuration files to be created."
# Start services to generate default deluge configuration files
sudo service $DELUGED_SERVICE start || \
	{ echo >&2 "Error starting deluged."; eval $CLEANUP; exit 1; }
CLEANUP="sudo service $DELUGED_SERVICE stop; $CLEANUP"
sudo service $DELUGE_WEB_SERVICE start || \
	{ echo >&2 "Error starting deluge-web."; eval $CLEANUP; exit 1; }
CLEANUP="sudo service $DELUGE_WEB_SERVICE stop; $CLEANUP"

# Can't kill it immediately or no files will be generated
sleep $TIMEOUT 

# Stop services so it'll write out the config files
sudo service $DELUGE_WEB_SERVICE stop || \
	{ echo >&2 "Error stopping deluge-web."; eval $CLEANUP; exit 1; }
sudo service $DELUGED_SERVICE stop || \
	{ echo >&2 "Error stopping deluged."; eval $CLEANUP; exit 1; }

WAITED=0
while [ ! -e $DELUGE_CORE_CONF -o ! -e $DELUGE_WEB_CONF ]; do
	sleep 1
	WAITED=$((WAITED+1))
	if [ $WAITED -eq $TIMEOUT ]; then
		echo >&2 "Error waiting for deluge config."; eval $CLEANUP; exit 1;
	fi
done
sleep 1

# Edit default deluge configuration files
# generate random ports for deluged and deluge-web to run on
PORT=0
random_port()
{
	PORT_IN_USE=0
	while [ $PORT_IN_USE -eq 0 ]; do
		PORT=$(python -c "import random; print random.randint(10000,65000)")
		# check if port is already being used, exits with 0 if being used, 1 if
		# not used
		nc -z localhost $PORT
		PORT_IN_USE=$?
	done
}
random_port
sudo sed -i "s/\"daemon_port\": .*,/\"daemon_port\": $PORT,/" \
	$DELUGE_CORE_CONF || \
	{ echo >&2 "Error editing deluge daemon port."; eval $CLEANUP; exit 1; }
# let deluge-web know about this daemon
sudo cp $DELUGE_HOSTLIST_TEMPLATE $DELUGE_HOSTLIST_CONF || \
	{ echo >&2 "Error copying deluge hostlist."; eval $CLEANUP; exit 1; }
$CLEANUP="$CLEANUP; rm $DELUGE_HOSTLIST_CONF"
sudo chown ${USER}. $DELUGE_HOSTLIST_CONF || \
	{ echo >&2 "Error chown deluge hostlist."; eval $CLEANUP; exit 1; }
sudo sed -i "s/<name>/$DELUGED_SERVICE/" $DELUGE_HOSTLIST_CONF || \
	{ echo >&2 "Error updating deluge hostlist name."; eval $CLEANUP; exit 1; }
sudo sed -i "s/<port>/$PORT/" $DELUGE_HOSTLIST_CONF || \
	{ echo >&2 "Error updating deluge hostlist port"; eval $CLEANUP; exit 1; }
# tell deluge-web to connect to this daemon by default
sudo sed -i \
	"s/\"default_daemon\": \".*\",/\"default_daemon\": \"$DELUGED_SERVICE\",/" \
	$DELUGE_WEB_CONF || \
	{ echo >&2 "Error editing deluge web conf."; eval $CLEANUP; exit 1; }
random_port
sudo sed -i -r "s/(\"port\": )([0-9]+)(.*)/\1$PORT\3/" $DELUGE_WEB_CONF || \
	{ echo >&2 "Error editing deluge web conf."; eval $CLEANUP; exit 1; }
# configure download directories
sudo sed -i "s|\"download_location\": .*,|\"download_location\": \"/home/$USER/torrents/incomplete\",|" \
	$DELUGE_CORE_CONF || \
	{ echo >&2 "Error editing deluge download path."; eval $CLEANUP; exit 1;}
sudo sed -i "s|\"move_completed_path\": .*,|\"move_completed_path\": \"/home/$USER/torrents/complete\",|" \
	$DELUGE_CORE_CONF || \
	{ echo >&2 "Error editing deluge completed path."; eval $CLEANUP; exit 1;}
sudo sed -i "s/\"move_completed\": false/\"move_completed\": true/" \
	$DELUGE_CORE_CONF || \
	{ echo >&2 "Error editing deluge move completed."; eval $CLEANUP; exit 1;}


# Restart services with the new conf
sudo service $DELUGED_SERVICE start || \
	{ echo >&2 "Error starting deluged after conf."; eval $CLEANUP; exit 1; }
sudo service $DELUGE_WEB_SERVICE start || \
	{ echo >&2 "Error starting deluge-web after conf."; eval $CLEANUP; exit 1; }

echo "Done! You can now access the web client at port $PORT"

# Cleanup tmp files
rm $DELUGED_CONF_TMP
rm $DELUGE_WEB_CONF_TMP
