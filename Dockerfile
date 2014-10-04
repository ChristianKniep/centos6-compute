###### Supervisord image
FROM centos:centos6
MAINTAINER "Christian Kniep <christian@qnib.org>"


ADD etc/yum.repos.d/qnib.repo /etc/yum.repos.d/qnib.repo
RUN yum clean all

## supervisord
RUN yum install -y python-meld3 python-setuptools python-supervisor
ADD etc/supervisord.conf /etc/supervisord.conf
RUN mkdir -p /var/log/supervisor
RUN sed -i -e 's/nodaemon=false/nodaemon=true/' /etc/supervisord.conf
ADD usr/local/bin/supervisor_daemonize.sh /usr/local/bin/supervisor_daemonize.sh

# misc
RUN yum install -y bind-utils vim

##### USER
# Set (very simple) password for root
RUN echo "root:root"|chpasswd
ADD root/bashrc /root/.bashrc
ADD root/bash_profile /root/.bash_profile

### SSHD
RUN yum install -y openssh-server openssh-clients initscripts
RUN mkdir -p /var/run/sshd
RUN sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
RUN sed -i -e 's/GSSAPIAuthentication.*/GSSAPIAuthentication no/' /etc/ssh/sshd_config
ADD etc/supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini

# We do not care about the known_hosts-file and all the security
####### Highly unsecure... !1!! ###########
RUN echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN echo "        AddressFamily inet" >> /etc/ssh/ssh_config


# etcd+skydns
ADD usr/local/bin/etcdctl /usr/local/bin/etcdctl
RUN yum install -y skydns etcd

### compute-stuff
# Install dependencies
RUN yum install -y openmpi
# Application libs
RUN yum install -y gsl libgomp

# python-dependency
RUN yum install -y python-docopt PyYAML
RUN yum install -y nc

# IB
RUN yum install -y infiniband-diags perftest 

ADD pub_keys /tmp/pub_keys/
RUN mkdir -p /root/.ssh;chmod 700 /root/.ssh
RUN cat /tmp/pub_keys/*.pub >> /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys 

RUN yum install -y libmlx5 libmthca librdmacm-utils
RUN yum install -y dapl dapl-devel dapl-devel-static dapl-utils ibacm libibcm libibcm-devel libibverbs libibverbs-devel libibverbs-devel-static libibverbs-utils libmlx4 libmlx5 libmlx5-devel librdmacm librdmacm-devel librdmacm-utils srptools

RUN yum install -y make automake gcc-c++ openmpi-devel opensm

### DON't USE THIS AT HOME (NOR IN PRODUCTION)
RUN echo ">>> DON't USE THIS AT HOME (NOR IN PRODUCTION)"
ADD etc/ssh /etc/ssh

# SLURM
RUN yum install -y slurm
## autostart 
RUN sed -i -e 's/autostart=.*/autostart=true/' /etc/supervisord.d/munged.ini
RUN sed -i -e 's/autostart=.*/autostart=true/' /etc/supervisord.d/slurmd.ini

# MPI
RUN echo "2014-09-25.2";yum clean --disablerepo=* --enablerepo=qnib-common all
RUN yum install -y qnib-openmpi1541 qnib-openmpi154 qnib-openmpi165 qnib-openmpi175 qnib-openmpi182

# SETUP env
RUN useradd -u 5000 -d /usr/local/etc/ -M slurm
RUN mkdir -p /var/lib/slurm/; mkdir -p /var/log/slurm/; mkdir -p /var/run/slurm/; mkdir -p /var/spool/slurmd
RUN chmod 755 /var/lib/slurm/ /var/log/slurm/ /var/run/slurm/ /var/spool/slurmd
RUN chown slurm /var/lib/slurm/ /var/log/slurm/ /var/run/slurm/ /var/spool/slurmd

CMD /usr/bin/supervisord -c /etc/supervisord.conf
