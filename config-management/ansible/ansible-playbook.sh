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

  # if [ -z "$2" ]; then
  #   echo "Not enough arguments, expecting: hostname, SSH port"
  #   exit 1
  # fi
  # ansible_working_dir="/vagrant"
  # ansible_inventory_dir="$ansible_working_dir/inventory"
  # ansible_inventory_tmpdir="~/tmp/$ansible_inventory_dir"
  # # ansible_playbook_dir="$ansible_working_dir/playbook"

  # ansible_hostname="$1"
  # ansible_ssh_port="$2"
  # # ansible_extra_vars="$3"

# ansible_inventory_file="$ansible_inventory_dir/vagrant_$ansible_hostname.ini"
# ansible_inventory_tmpfile="$ansible_inventory_tmpdir/vagrant_$ansible_hostname.ini"
# ansible_playbook_file="$ansible_working_dir/master.yml"
# ansible_extra_vars_file="$ansible_working_dir/ansible_config.yml"

# if [ ! -f "$ansible_playbook_file" ]; then
#   echo "Ansible master playbook was not found: $ansible_playbook_file"
#   exit 2
# fi

# # Create the inventory tmpdir if it doesn't exist yet
# if [ ! -d "$ansible_inventory_tmpdir" ]; then
#   mkdir -p "$ansible_inventory_tmpdir"
# fi

# # Generate a dynamic inventory file for this host
# echo "$ansible_hostname  ansible_ssh_host=127.0.0.1  ansible_ssh_port=$ansible_ssh_port" > "$ansible_inventory_file"
# cp "$ansible_inventory_file" "$ansible_inventory_tmpfile"
# chmod -x "$ansible_inventory_tmpfile"

# if [ ! -f "$ansible_inventory_file" ]; then
#   echo "Generated Ansible inventory was not found: $ansible_inventory_file"
#   exit 3
# fi
# if [ ! -f "$ansible_inventory_tmpfile" ]; then
#   echo "Generated Ansible temporary inventory was not found: $ansible_inventory_tmpfile"
#   exit 4
# fi

# # Copy ansible.cfg for $ansible_user
# if [ ! -f "/home/$ansible_user/.ansible.cfg" ]; then
#   cp "$ansible_working_dir/ansible.cfg" "/home/$ansible_user/.ansible.cfg"
# fi

# # stream output
# export PYTHONUNBUFFERED=1
# # show ANSI-colored output
# export ANSIBLE_FORCE_COLOR=true
# echo "Running Ansible as $ansible_user:"
# # Have to use the inventory tmpfile here because we can't remove executable bit on Windows
# ansible-playbook "$ansible_playbook_file" --inventory-file="$ansible_inventory_tmpfile" --connection=local --extra-vars "@$ansible_extra_vars_file"
