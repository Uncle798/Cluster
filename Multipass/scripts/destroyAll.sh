#! /bin/zsh
INSTANCE_EXISTS=$(multipass list)
if [ "$INSTANCE_EXISTS" = "No instances found." ]; then
    echo "None to destroy"
    exit 0
fi
multipass stop --all
multipass delete --all
multipass purge
echo "All gone"
exit 0