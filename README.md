# Implementacion de nodo (MV) Bastion para instalacion de OCP

Nombre     | Sección | Descripcion
---------|-------------|--------------------
Prerequisitos |  | . |
Instalacion de paquetes base |  |
Implementación |  |
Configuracion de subscription-manager |  |

## Prerequisitos

Implementación de Maquina virtual RHEL 7.5 o superior

Realizar la subscripcion a el portal de:
[![RedHat developers](https://developers.redhat.com/)

### Implementación

Nombre del host     | IP | Rol
---------|-------------|--------------------
bastion.redhat.com | <dinamica> | nodo Bastion

#### Configuracion de subscription-manager

```console
consultor@rhmx.org:~$ subscription-manager register --username <username> --password <password>
```

* Posiblemente aqui pedira aceptar terminos y condiciones de la pagina de redhat, en dado caso entrar y aceptar los terminos y condiciones para continuar.

```console
consultor@rhmx.org:~$ subscription-manager list --available --all
```

```console
consultor@rhmx.org:~$ subscription-manager attach --pool=<POOL_ID>
```

```console
consultor@rhmx.org:~$ subscription-manager register
```

```console
consultor@rhmx.org:~$ subscription-manager refresh
```

### Configuración de Bastión (repositorio)

```console
consultor@rhmx.org:~$ subscription-manager repos \
        --enable="rhel-7-server-rpms" \
        --enable="rhel-7-server-extras-rpms" \
        --enable="rhel-7-server-ose-3.11-rpms" \
        --enable="rhel-7-server-ansible-2.6-rpms"
```

#### Instalar paquetes necesarios RHEL

```console
consultor@rhmx.org:~$ yum -y install yum-utils createrepo docker git
```

#### Instalar paquetes necesarios Fedora

```console
consultor@rhmx.org:~$ dnf -y install yum-utils createrepo docker git
```

> Montar disco adicional sin formato (Crearlo en herrmaienta del hypervisor)

#### Crear el directorio donde se almacenarán los repositorios

```console
consultor@rhmx.org:~$ mkdir -p /opt/repos

consultor@rhmx.org:~$ cd /opt/repos
```
#### Sincronizar los paquetes y crear los repositorios locales

```console
consultor@rhmx.org:~$ for repo in \
rhel-7-server-rpms \
rhel-7-server-extras-rpms \
rhel-7-server-ansible-2.6-rpms \
rhel-7-server-ose-3.11-rpms
do
  reposync --gpgcheck -lm --repoid=${repo} --download_path=/opt/repos/
  createrepo -v /opt/repos/${repo} -o /opt/repos/${repo}
done
```

#### Instalar servicio httpd

```console
consultor@rhmx.org:~$ yum install httpd
```

> Editar archivo de configuración de httpd '(/etc/httpd/conf/httpd.conf)' con el siguiente contenido:

```conf
Note that from this point forward you must specifically allow
# particular features to be enabled - so if something's not working as
# you might expect, make sure that you have specifically enabled it
# below.
#

#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
DocumentRoot "/opt/repos"

#
# Relax access to content within /var/www.
#
<Directory "/opt/repos">
   AllowOverride None
   # Allow open access:
   Require all granted
</Directory>

# Further relax access to the default document root:
<Directory "/opt/repos">
   #
   # Possible values for the Options directive are "None", "All",
   # or any combination of:
   #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
   #
   # Note that "MultiViews" must be named *explicitly* --- "Options All"
   # doesn't give it to you.
   #
   # The Options directive is both complicated and important.  Please see
   # http://httpd.apache.org/docs/2.4/mod/core.html#options
   # for more information.
   #
   Options Indexes FollowSymLinks

   #
   # AllowOverride controls what directives may be placed in .htaccess files.
   # It can be "All", "None", or any combination of the keywords:
   #   Options FileInfo AuthConfig Limit
   #
   AllowOverride None

   #
   # Controls who can get stuff from this server.
   #
   Require all granted
</Directory>
```
#### Agregar permisos al directorio y restablecer los contextos

```console
consultor@rhmx.org:~$ chmod -R +r /opt/repos
consultor@rhmx.org:~$ restorecon -vR /opt/repos
```

#### Agregar reglas de firewall

```console
consultor@rhmx.org:~$ sudo firewall-cmd --permanent --add-service=http
consultor@rhmx.org:~$ sudo firewall-cmd --reload
```

#### Habilitar e iniciar el servicio de httpd

```console
consultor@rhmx.org:~$ systemctl enable httpd
consultor@rhmx.org:~$ systemctl start httpd
```

> Clonar la Maquina Virtual y esa maquina sera el nodo de infraestructura adicional.

#### Editar el archivo /etc/yum.repos.d/ose.repo en todos los nodos de la infraestructura con el siguiente contenido:

```config
[rhel-7-server-rpms-rhmx-consult]
name=rhel-7-server-rpms-rhmx-consult
baseurl=http://<ip del nodo bastion>/rhel-7-server-rpms
enabled=1
gpgcheck=0
[rhel-7-server-extras-rpms-rhmx-consult]
name=rhel-7-server-extras-rpms-rhmx-consult
baseurl=http://<ip del nodo bastion>/rhel-7-server-extras-rpms
enabled=1
gpgcheck=0
[rhel-7-server-ansible-2.6-rpms-rhmx-consult]
name=rhel-7-server-ansible-2.6-rpms-rhmx-consult
baseurl=http://<ip del nodo bastion>/rhel-7-server-ansible-2.6-rpms
enabled=1
gpgcheck=0
[rhel-7-server-ose-3.11-rpms-rhmx-consult]
name=rhel-7-server-ose-3.11-rpms-rhmx-consult
baseurl=http://<ip del nodo bastion>/rhel-7-server-ose-3.11-rpms
enabled=1
gpgcheck=0
```
### Configuración de Bastión (Registro Docker)

#### Iniciar Docker en el nodo bastion y hacer login con las credenciales de customer portal

```console
consultor@rhmx.org:~$ systemctl start docker
consultor@rhmx.org:~$ docker login registry.redhat.io
```

#### Descargar las siguientes imágenes con las etiquetas v3.11, y v3.11.135 (reemplazar <tag> con la versión)

```console
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/apb-base:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/apb-tools:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/automation-broker-apb:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/csi-attacher:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/csi-driver-registrar:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/csi-livenessprobe:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/csi-provisioner:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/grafana:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/image-inspector:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/local-storage-provisioner:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/manila-provisioner:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/mariadb-apb:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/mediawiki:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/mediawiki-apb:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/mysql-apb:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-ansible:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-ansible-service-broker:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-cli:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-cluster-autoscaler:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-cluster-capacity:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-cluster-monitoring-operator:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-console:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-configmap-reloader:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-control-plane:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-deployer:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-descheduler:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-docker-builder:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-docker-registry:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-efs-provisioner:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-egress-dns-proxy:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-egress-http-proxy:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-egress-router:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-haproxy-router:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-hyperkube:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-hypershift:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-keepalived-ipfailover:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-kube-rbac-proxy:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-kube-state-metrics:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-metrics-server:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-node:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-node-problem-detector:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-operator-lifecycle-manager:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-ovn-kubernetes:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-pod:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-prometheus-config-reloader:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-prometheus-operator:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-recycler:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-service-catalog:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-template-service-broker:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-tests:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-web-console:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/postgresql-apb:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/registry-console:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/snapshot-controller:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/snapshot-provisioner:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/rhel7/etcd:3.2.22
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-efs-provisioner:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/metrics-cassandra:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/metrics-hawkular-metrics:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/metrics-hawkular-openshift-agent:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/metrics-heapster:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/metrics-schema-installer:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/oauth-proxy:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-logging-curator5:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-logging-elasticsearch5:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-logging-eventrouter:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-logging-fluentd:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/ose-logging-kibana5:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/prometheus:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/prometheus-alert-buffer:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/prometheus-alertmanager:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/openshift3/prometheus-node-exporter:<tag>
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-openshift-postgresql
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-openshift-memcached
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-openshift-app-ui
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-openshift-app
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-openshift-embedded-ansible
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-openshift-httpd
consultor@rhmx.org:~$ docker pull registry.redhat.io/cloudforms46/cfme-httpd-configmap-generator
consultor@rhmx.org:~$ docker pull registry.redhat.io/rhgs3/rhgs-server-rhel7
consultor@rhmx.org:~$ docker pull registry.redhat.io/rhgs3/rhgs-volmanager-rhel7
consultor@rhmx.org:~$ docker pull registry.redhat.io/rhgs3/rhgs-gluster-block-prov-rhel7
consultor@rhmx.org:~$ docker pull registry.redhat.io/rhgs3/rhgs-s3-server-rhel7
```
#### Crear certificado autofirmado

```console
consultor@rhmx.org:~$ mkdir certs

consultor@rhmx.org:~$ openssl req \
 -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
 -x509 -days 365 -out certs/domain.crt
```
#### Crear contenedor registry con el siguiente comando

```console
consultor@rhmx.org:~$ docker run \
  --name registry \
  -v /certs:/certs:Z \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -p 443:443 \
  registry:2
```
####  Editar el archivo /etc/sysconfig/docker en la siguiente línea, para configurar un repositorio inseguro:

> OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry https://bastion.ocp.rhmx.org --insecure-registry bastion.ocp.rhmx.org'

#### Etiquetar las imágenes y subirlas al registry

```console
consultor@rhmx.org:~$ docker tag registry.redhat.io/openshift3/ose-node:<tag>  bastion.ocp.rhmx.org/openshift3/ose-node:<tag>
consultor@rhmx.org:~$ docker push bastion.ocp.rhmx.org/openshift3/ose-node:<tag>
```

#### Instalar paquetes adicionales Docker y Ansible

```console
consultor@rhmx.org:~$ yum install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

consultor@rhmx.org:~$ yum install openshift-ansible

consultor@rhmx.org:~$ yum install docker-1.13.1
```

#### Editar el archivo /etc/sysconfig/docker-storage-setup con el siguiente contenido editar <volumen> como corresponde:

> Reiniciar el equipo

> Agregar otro disco adicional a la maquina virtual 80 GB

```conf
STORAGE_DRIVER=overlay2
DEVS=/dev/<volumen>
CONTAINER_ROOT_LV_NAME=docker-lv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
VG=docker-vg
```

```console
consultor@rhmx.org:~$ yum install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

consultor@rhmx.org:~$ yum install openshift-ansible

consultor@rhmx.org:~$ yum install docker-1.13.1

consultor@rhmx.org:~$ yum update
```
> Reiniciar el equipo

#### Ejecutar el siguiente comando para configurar el almacenamiento de Docker

```console
consultor@rhmx.org:~$ docker-storage-setup
```

#### Habilitar e iniciar Docker

```console
consultor@rhmx.org:~$ systemctl enable docker
consultor@rhmx.org:~$ systemctl start docker
```
