#!/bin/zsh/
GET_HOSTNAME () {
    LINES_IN_NAMES=$(wc -l /Users/ericbranson/Documents/Cluster/Multipass/scripts/serverNames.txt | awk '{print $1}')
    RAND_LINE="$(jot -r 1 1 $LINES_IN_NAMES)"
    HOSTNAME_PREFIX="$(head -$RAND_LINE ~/documents/cluster/multipass/scripts/serverNames.txt | TAIL -1 | tr "[A-Z]" "[a-z]")"
    gsed -i "$RAND_LINE"d /Users/ericbranson/Documents/Cluster/Multipass/scripts/serverNames.txt
    echo "$HOSTNAME_PREFIX was chosen would you like to choose another? [y/n]"
    read GOOD_HOSTNAME
    if [ $GOOD_HOSTNAME = 'y' ]; then
        GET_HOSTNAME
    fi
}
GET_HOSTNAME
INSTANCE_EXISTS=$(multipass list)
if [ "$INSTANCE_EXISTS" != "No instances found." ]; then
    echo "There is currently a cluster running, destroy it? [y/n]"
    read ANSWER 
fi
if [ "$ANSWER" = "n" ]; then
    echo exiting
    exit 0
fi
if [[ ("$INSTACE_EXISTS" != "No instances found.") &&  ("$ANSWER" == "y") ]]; then
    multipass stop --all
    multipass delete --all
    multipass purge
fi
echo "Debug ansible?[y/n]"
read LOOKING_AT_THINGS
if [ "$LOOKING_AT_THINGS" = "y" ]; then
    LOOKING_AT_THINGS="-v"
else
    LOOKING_AT_THINGS=""
fi
echo "How many Proxies?"
typeset -i NUM_PROXIES NUM_CONTROL NUM_AGENTS
read NUM_PROXIES
echo "How many k3s control servers?"
read NUM_CONTROL
if [[ $NUM_CONTROL -gt 0 ]]; then
    echo "How many k3s agents?"
    read NUM_AGENTS
fi
echo "Run initialConfig playbook?[y/n]"
read INITIALIZE
NUM_INSTANCES="$(($NUM_PROXIES+$NUM_CONTROL+$NUM_AGENTS))"
echo "Setting up $NUM_INSTANCES virtual machines"
if test -f "~/Documents/Cluster/Multipass/inventory.yaml"; then
    rm ~/Documents/Cluster/Multipass/inventory.yaml
fi
if [[ $NUM_PROXIES -gt 0 ]]; then
    echo "proxyCluster:\n  hosts:" > ~/Documents/Cluster/Multipass/inventory.yaml
    for x in {1..$NUM_PROXIES}; do
        INSTANCE_NUMBER=$x
        if [ $x -lt 10 ]; then
            INSTANCE_NUMBER="0$x"
        fi
        multipass launch -n $HOSTNAME_PREFIX$INSTANCE_NUMBER --cloud-init ~/documents/cluster/multipass/cloud-init.yaml -c 2 -m 2G -d 4G
        IP=$(multipass info $HOSTNAME_PREFIX$INSTANCE_NUMBER | grep IPv4 | awk '{print $2}')
        echo "    $HOSTNAME_PREFIX$INSTANCE_NUMBER:\n      ansible_host: $IP" >> ~/Documents/Cluster/Multipass/inventory.yaml
        ssh-keyscan $IP >> ~/.ssh/known_hosts
    done
fi
if [[ $NUM_CONTROL -gt 0 ]]; then
    echo "k3sControlCluster:\n  hosts:" >> ~/Documents/Cluster/Multipass/inventory.yaml
    for ((x=NUM_PROXIES+1; x<=NUM_PROXIES+NUM_CONTROL; x++)); do
        INSTANCE_NUMBER=$x
        if [ $x -lt 10 ]; then
            INSTANCE_NUMBER="0$x"
        fi
        multipass launch -n $HOSTNAME_PREFIX$INSTANCE_NUMBER --cloud-init ~/documents/cluster/multipass/cloud-init.yaml -c 2 -m 2G -d 4G
        IP=$(multipass info $HOSTNAME_PREFIX$INSTANCE_NUMBER | grep IPv4 | awk '{print $2}')
        echo "    $HOSTNAME_PREFIX$INSTANCE_NUMBER:\n      ansible_host: $IP" >> ~/Documents/Cluster/Multipass/inventory.yaml 
        ssh-keyscan $IP >> ~/.ssh/known_hosts
    done
fi
if [[ $NUM_AGENTS -gt 0 ]]; then
    echo "k3sAgentCluster:\n  hosts:" >> ~/Documents/Cluster/Multipass/inventory.yaml 
    for ((x=NUM_PROXIES+NUM_CONTROL+1; x<=NUM_INSTANCES; x++)); do
        INSTANCE_NUMBER=$x
        if [ $x -lt 10 ]; then
            INSTANCE_NUMBER="0$x"
        fi
        multipass launch -n $HOSTNAME_PREFIX$INSTANCE_NUMBER --cloud-init ~/documents/cluster/multipass/cloud-init.yaml -c 2 -m 2G -d 4G
        IP=$(multipass info $HOSTNAME_PREFIX$INSTANCE_NUMBER | grep IPv4 | awk '{print $2}')
        echo "    $HOSTNAME_PREFIX$INSTANCE_NUMBER:\n      ansible_host: $IP" >> ~/Documents/Cluster/Multipass/inventory.yaml 
        ssh-keyscan $IP >> ~/.ssh/known_hosts
    done
fi
multipass list
if [ $INITIALIZE = 'y' ]; then
    ansible-playbook /Users/ericbranson/Documents/Cluster/Multipass/playbooks/initializeChromebox.yaml\
     --vault-password-file ~/Documents/Cluster/Multipass/secrets/ansibleVaultKey\
      --inventory ~/Documents/Cluster/Multipass/inventory.yaml\
      $LOOKING_AT_THINGS
fi
if [ $NUM_PROXIES -gt 0 ] && [ $INITIALIZE = 'y' ]; then
    ansible-playbook /Users/ericbranson/Documents/Cluster/Multipass/playbooks/installProxy.yaml\
     --vault-password-file ~/Documents/Cluster/Multipass/secrets/ansibleVaultKey\
      --inventory ~/Documents/Cluster/Multipass/inventory.yaml\
      $LOOKING_AT_THINGS
fi