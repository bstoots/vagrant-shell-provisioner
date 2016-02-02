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
if [ -n "$2" ]; then
  ansible_playbooks="$2"
else
  echo 'Argument $2 must be one or more Ansible playbooks'
  exit 1
fi
# temporary inventory will be written to ~/.localhost.ini only if it doesn't already exist to avoid
# accidental overwrites
if [ ! -f ~/.localhost.ini ]; then
  ansible_inventory_tmp=~/.localhost.ini
  # le sigh ... https://github.com/ansible/ansible/issues/11695
  echo "localhost              ansible_connection=local" > $ansible_inventory_tmp
  if [ ! -f "$ansible_inventory_tmp" ]; then
    echo "Temporary inventory was not written to: $ansible_inventory_tmp"
    exit 1
  fi
else
  echo "Inventory file already exists at: ~/.localhost.ini"
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
ansible-playbook ${ansible_playbooks} --inventory-file="$ansible_inventory_tmp" --connection=local ${ansible_extra_vars_file} ${ansible_options} || true
# Trash the temp inventory afterwards
rm $ansible_inventory_tmp
