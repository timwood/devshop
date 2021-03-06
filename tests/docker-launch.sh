#!/usr/bin/env bash
DEVSHOP_VERSION='1.x'
DISTRIBUTION='ubuntu'
VERSION='14.04'
INIT='/sbin/init'
CONTAINER_NAME='devshop_server'
RUN_OPTS="--name=$CONTAINER_NAME"
SCRIPT_OPTS='--server-webserver=nginx'
CONTAINER_HOSTNAME=devshop.docker

# Don't stop supervisor until we want to run tests.
# SUPERVISOR_STOP='service supervisor stop'
HOST_PORT=8000
TRAVIS=true

# Do NOT let this script run as root.
if [[ ! $EUID -ne 0 ]]; then
   echo "This script must NOT be run as root. Run it as the same user you edit your files with."
   echo "This user must also be able to run the 'docker' command."
   echo "If it cannot, try adding it to the docker group: "
   echo "  $ sudo usermod -aG docker yourusername  "
   exit 1
fi

echo "Running 'vagrant-prepare-host.sh' to get source code..."
cd ..
bash vagrant-prepare-host.sh $PWD $DEVSHOP_VERSION
cd tests

# Create an inventory file so we can set some variables
echo "$CONTAINER_HOSTNAME aegir_user_uid=$UID aegir_user_gid=$UID" > ../inventory

# Pull the specified OS disto and version.
docker pull $DISTRIBUTION:$VERSION

# Build an image using our Dockerfiles
docker build --rm=true --file=Dockerfile.$DISTRIBUTION-$VERSION --tag=$DISTRIBUTION-$VERSION:devmaster .

# Run the image with volumes mapped to our source code.
docker run --detach -p $HOST_PORT:80 $RUN_OPTS \
    --volume=$PWD/..:/usr/share/devshop:rw \
    --volume=$PWD/../source/devmaster-$DEVSHOP_VERSION:/var/aegir/devmaster-$DEVSHOP_VERSION \
    --volume=$PWD/../source/drush:/var/aegir/.drush/commands:rw \
    -h $CONTAINER_HOSTNAME $DISTRIBUTION-$VERSION:devmaster $INIT

# Run install.sh
docker exec --tty $CONTAINER_NAME env TERM=xterm sudo su -c "/usr/share/devshop/install.sh $SCRIPT_OPTS --hostname=$CONTAINER_HOSTNAME"

# Don't stop queue until the user runs tests.
# docker exec $CONTAINER_NAME $SUPERVISOR_STOP
# docker exec $CONTAINER_NAME env sudo su - aegir -c "drush @hostmaster dis hosting_queued -y -v"
# bash docker-test-devshop.sh


echo ""
echo "NEXT: Please add '127.0.0.1 devshop.docker' to your /etc/hosts file."
echo " You must access the site at http://devshop.docker:$HOST_PORT "
echo " To get into the server, run: "
echo "    $ docker exec -ti devshop_server su - aegir "
echo " Then to get into the front end, run:"
echo "    $ devshop login "
echo " You will get a URL like http://devshop.docker/user/login/13abc.  you will have to add the port manually to make the link look like http://devshop.docker:8000/user/login/13abc."
echo ""
echo " Good luck! We hope to improve on this soon.  Please post issues at https://github.com/opendevshop/devshop/issues "
echo " "
echo " To run tests, run the 'docker-test.sh' script."
echo " To destroy the devshop container, run the 'docker-destroy.sh' script."
