# docker-cifv2

`$ docker pull elasticsearch:1.7`

## build

`$ docker build -t nizq/cifv2:debian .`

## setup

```
$ cd ansible
$ ansible-playbook setup.yml
```

## stop

```
$ cd ansible
$ ansible-playbook stop.yml
```

## start

```
$ cd ansible
$ ansible-playbook start.yml
```
