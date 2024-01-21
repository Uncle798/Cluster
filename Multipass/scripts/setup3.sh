#! /bin/zsh
multipass launch -n test01 --cloud-init ~/documents/cluster/multipass/cloud-init.yaml
multipass launch -n test02 --cloud-init ~/documents/cluster/multipass/cloud-init.yaml
multipass launch -n test03 --cloud-init ~/documents/cluster/multipass/cloud-init.yaml
multipass list