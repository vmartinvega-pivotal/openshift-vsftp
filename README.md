# FTP Server: vsftpd

This Docker container implements a vsftpd server, with the following features:

 * Centos 7 base image.
 * vsftpd 3.0
 * Virtual users
 * Passive mode

## Build the image
Clone the repo and run the following command

```
docker build -t registry.global.ccc.srvb.can.paas.cloudcenter.corp/c3alm-sgt/vsftpd .
```

## Push the image
Push the docker image once it is built

```
docker push registry.global.ccc.srvb.can.paas.cloudcenter.corp/c3alm-sgt/vsftpd
```

## Run in Openshift

### Create a serviceaccount to run the container
* Login to openshift
```
oc login -n myproject
```
* Create a serviceaccount in the openshift project
```
oc create serviceaccount mysvcacct
```
* Grant permissions to the serviceaccount (the user logged needs admin permissions)
```
oc adm policy add-scc-to-user anyuid system:serviceaccount:myproject:mysvcacct
```

## Deploy

./deploy-vsftpd.sh --endpoint https://api.ocp.ccc.srvb.cn2.paas.cloudcenter.corp:8443 --namespace global-alm-test-pre


The serviceaccount created will be used when deploying the service (param --serviceaccount)


Environment variables
----

This image uses environment variables to allow the configuration of some parameters at run time:

* Variable name: `FTP_USER`
* Default value: admin
* Accepted values: Any string. Avoid whitespaces and special chars.
* Description: Username for the default FTP account. If you don't specify it through the `FTP_USER` environment variable at run time, `admin` will be used by default.

----

* Variable name: `FTP_PASS`
* Default value: Random string.
* Accepted values: Any string.
* Description: If you don't specify a password for the default FTP account through `FTP_PASS`, a 16 character random string will be automatically generated. You can obtain this value through the [container logs](https://docs.docker.com/engine/reference/commandline/container_logs/).

----

Exposed ports and volumes
----

The image exposes ports `20`, `21`, `21100`, `21101` and `21102`. Also, exports one volumes: `/home/vsftpd`, which contains users home directories.

Use cases
----

1) Create a **production container** with a custom user account, binding a data directory and enabling both active and passive mode:

```bash
docker run -d -v /my/data/directory:/home/vsftpd \
-p 20:20 -p 21:21 -p 21100-21102:21100-21100 \
-e FTP_USER=myuser -e FTP_PASS=mypass \
--name vsftpd --restart=always registry.global.ccc.srvb.can.paas.cloudcenter.corp/c3alm-sgt/vsftpd
```

4) Manually add a new FTP user to an existing container:
```bash
docker exec -i -t vsftpd bash
mkdir /home/vsftpd/myuser
echo -e "myuser\nmypass" >> /etc/vsftpd/virtual_users.txt
/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db
exit
docker restart vsftpd
```
