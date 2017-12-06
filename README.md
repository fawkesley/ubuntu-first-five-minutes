# Ubuntu First Five Minutes

This is a simple bootstrapping shell script to run on a fresh Ubuntu 14.04 / 16.04 LTS
server machine.

I made it after realising half of the Ansible code I write is actually
run-once bootstrapping code. This is a simple shell version.

The script configures the machine with slightly-harder defaults, for example:

- disable password-based SSH login
- enable automatic security updates
- install fail2ban

This was inspired by [Bryan Kennedy's blog post](http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers).

## Usage

```
cd $HOME
git --version || apt install git
git clone https://github.com/paulfurley/ubuntu-first-five-minutes.git
cd ubuntu-first-five-minutes
./bootstrap.sh
```

### Fork this repo, adjust to your needs

You'll probably want to fork the repo and use a different username and SSH
`authorized_keys` file :)

In any case you should definitely download and inspect the code as it's going
to be running as root on your machine...

### Copy repo to fresh machine

For example, if you've just created a Digital Ocean machine, you've got a root
user account so you use rsync to copy the repo over:

```
rsync -rtvu ./ubuntu-trusty-first-five-minutes/ root@your-new-server.example.com:/root/first-five-minutes/
```

### Run the script

As root, simples:

```
/root/first-five-minutes/bootstrap.sh
```
