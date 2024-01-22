#! /bin/zsh
FILE_EXISTS=$(multipass list)
if [ "$FILE_EXISTS" = "No instances found." ]; then
    echo "None to destroy"
    exit 0
fi
multipass stop --all
multipass delete --all
multipass purge
echo "All gone"
exit 0