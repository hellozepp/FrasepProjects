FROM ses.sas.download/va-125-x64_redhat_linux_7-docker/sas-viya-programming:3.5.13-20210830.1630366147028

RUN yum install --assumeyes --noplugins epel-release && \
    yum clean all && \
    rm -rf /tmp/rpms && \
    rm -rf /root/.cache /var/cache/yum
RUN yum install --assumeyes --noplugins gcc gcc-c++ openssl python36-devel python36-pip zlib-devel libjpeg-devel && \
    yum clean all && rm -rf /tmp/rpms && \
    rm -rf /root/.cache /var/cache/yum

RUN pip3 --no-cache-dir install notebook matplotlib scikit-learn saspy swat sasctl sas-esppy
RUN pip3 --no-cache-dir install sas_kernel

COPY post_deploy.sh /tmp/post_deploy.sh
RUN chmod +x /tmp/post_deploy.sh

COPY jupyter_proxy.conf /etc/httpd/conf.d/jupyter_proxy.conf
