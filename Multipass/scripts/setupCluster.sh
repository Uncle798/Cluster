#! /bin/zsh

echo "Hostname prefix:"
read HOSTNAME_PREFIX
echo "How many Proxies?"
typeset -i NUM_PROXIES NUM_CONTROL NUM_AGENTS
read NUM_PROXIES
echo "How many k3s control servers?"
read NUM_CONTROL
echo "How many k3s agents?"
read NUM_AGENTS
NUM_INSTANCES="$(($NUM_PROXIES+$NUM_CONTROL+$NUM_AGENTS))"
echo "Setting up $NUM_INSTANCES virtual machines"
if test -f "~/Documents/Cluster/Multipass/inventory.yaml"; then
    rm ~/Documents/Cluster/Multipass/inventory.yaml
fi
if [ $NUM_PROXIES-gt0 ]; then
    echo "proxyCluster:\n  hosts:" > ~/Documents/Cluster/Multipass/inventory.yaml
    for x in {1..$NUM_PROXIES}; do
        INSTANCE_NUMBER=$x
        if [ $x -lt 10 ]; then
            INSTANCE_NUMBER=0$x
        fi
        multipass launch -n $HOSTNAME_PREFIX$INSTANCE_NUMBER --cloud-init ~/documents/cluster/multipass/cloud-init.yaml -c 2 -m 2G -d 4G
        IP=$(multipass info $HOSTNAME_PREFIX$INSTANCE_NUMBER | grep IPv4 | awk '{print $2}')
        echo "    $HOSTNAME_PREFIX$INSTANCE_NUMBER:\n      ansible_host: $IP" >> ~/Documents/Cluster/Multipass/inventory.yaml 
    done
fi
if [ $NUM_CONTROL-gt0 ]; then
    echo "k3sControlCluster:\n  hosts:\n    " > ~/Documents/Cluster/Multipass/inventory.yaml
    for ((x=NUM_PROXIES+1; x<=NUM_PROXIES+NUM_CONTROL; x++)); do
    INSTANCE_NUMBER=$x
    if [ $x -lt 10 ]; then
        INSTANCE_NUMBER=0$x
    fi
    multipass launch -n $HOSTNAME_PREFIX$INSTANCE_NUMBER --cloud-init ~/documents/cluster/multipass/cloud-init.yaml -c 2 -m 2G -d 4G
    IP=$(multipass info $HOSTNAME_PREFIX$INSTANCE_NUMBER | grep IPv4 | awk '{print $2}')
    echo "    $HOSTNAME_PREFIX$INSTANCE_NUMBER:\n      ansible_host: $IP" >> ~/Documents/Cluster/Multipass/inventory.yaml 
    done
fi
if [ $NUM_AGENTS\-gt0 ]; then
    echo "k3sAgentCluster:\n\thosts:\n\t\t" > ~/Documents/Cluster/Multipass/inventory.yaml 
    for x in ((x=NUM_PROXIES+NUM_CONTROL+1; x<=NUM_INSTANCES; x++)); do
    INSTANCE_NUMBER=$x
    if [ $x -lt 10 ]; then
        INSTANCE_NUMBER="0$x"
    fi
    multipass launch -n $HOSTNAME_PREFIX$INSTANCE_NUMBER --cloud-init ~/documents/cluster/multipass/cloud-init.yaml -c 2 -m 2G -d 4G
    IP=$(multipass info $HOSTNAME_PREFIX$INSTANCE_NUMBER | grep IPv4 | awk '{print $2}')
    echo "    $HOSTNAME_PREFIX$INSTANCE_NUMBER:\n      ansible_host: $IP" >> ~/Documents/Cluster/Multipass/inventory.yaml 
    done
fi 