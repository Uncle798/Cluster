#! /bin/zsh
INSTANCE_EXISTS=$(multipass list)
if [ "$INSTANCE_EXISTS" != "No instances found." ]; then
    echo "There is currently a cluster running, destroy it? [y/n]"
    read ANSWER 
fi
if [ "$ANSWER" = "n" ]; then
    exit 0
fi
if [[ ("$INSTACE_EXISTS" != "No instances found.") &&  ("$ANSWER" == "y") ]]; then
    multipass stop --all
    multipass delete --all
    multipass purge
fi
echo "Hostname prefix:"
read HOSTNAME_PREFIX
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
ansible-playbook /Users/ericbranson/Documents/Cluster/Multipass/playbooks/initializeChromebox.yaml --vault-password-file ~/Documents/Cluster/Multipass/secrets/ansibleVaultKey -i ~/Documents/Cluster/Multipass/inventory.yaml
fi