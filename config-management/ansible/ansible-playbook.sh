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
# This will work in ansible >= 1.9.3 so let's roll with it
echo "ansible-playbook $ansible_playbooks --connection=local ${ansible_extra_vars_file} ${ansible_options}"
ansible-playbook ${ansible_playbooks} --connection=local ${ansible_extra_vars_file} ${ansible_options}
