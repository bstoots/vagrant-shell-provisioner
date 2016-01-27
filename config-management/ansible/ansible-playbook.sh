#!/bin/bash -e
# $1 - Ansible working directory on the guest
# $2 - One of more Ansible playbooks relative to $1 ($ansible_working_dir) (space delimited)
# $3 - Extra vars file, path is relative to $1 ($ansible_working_dir)
# $4 - Additional options (freeform)
if [ -d "$1" ]; then
  ansible_working_dir="$1"
else
  echo 'Argument $1 must be Ansible working directory on the guest'
  exit 1
fi
# inventory must be located at $ansible_working_dir/localhost.ini
# temporary inventory will be written to ~/tmp/ansible_local/localhost.ini for portability
if [ -f "$ansible_working_dir/localhost.ini" ]; then
  ansible_inventory="$ansible_working_dir/localhost.ini"
  mkdir -p ~/tmp/ansible_local/
  ansible_inventory_tmp=~/tmp/ansible_local/localhost.ini
  cp $ansible_inventory $ansible_inventory_tmp && chmod -x $ansible_inventory_tmp
  if [ ! -f "$ansible_inventory_tmp" ]; then
    echo "Temporary inventory was not written to: $ansible_inventory_tmp"
    exit 1
  fi
else
  echo "Inventory file not found at: $ansible_working_dir/localhost.ini"
  exit 1
fi

if [ -n "$2" ]; then
  ansible_playbooks="$2"
else
  echo 'Argument $2 must be one or more Ansible playbooks: '"$ansible_working_dir/localhost.ini"
  exit 1
fi

# Explode more than one playbook out into many on whitespace and prepend ansible_working_dir
playbooks=( $ansible_playbooks )
ansible_playbooks=""
for playbook in "${playbooks[@]}"; do
  ansible_playbooks+="$ansible_working_dir/$playbook "
done

# Add extra_vars file if specified
if [ -f "$ansible_working_dir/$3" ]; then
  ansible_extra_vars_file="--extra-vars @$ansible_working_dir/$3"
else
  ansible_extra_vars_file=""
fi

# Add extra ansible-playbook options is specified
if [ -n "$4" ]; then
  ansible_options="$4"
else
  ansible_options=""
fi

# stream output
export PYTHONUNBUFFERED=1
# show ANSI-colored output
export ANSIBLE_FORCE_COLOR=true
echo "Running Ansible as $USER:"
# Have to use the inventory tmpfile here because we can't remove executable bit on Windows
echo "ansible-playbook $ansible_playbooks --inventory-file=$ansible_inventory_tmp --connection=local ${ansible_extra_vars_file} ${ansible_options}"
ansible-playbook ${ansible_playbooks} --inventory-file="$ansible_inventory_tmp" --connection=local ${ansible_extra_vars_file} ${ansible_options}
