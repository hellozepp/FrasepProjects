FROM ses.sas.download/va-125-x64_redhat_linux_7-docker/sas-viya-programming:3.5.13-20210830.1630366147028

RUN yum install --assumeyes --noplugins epel-release && \
    yum clean all && \
    rm -rf /tmp/rpms && \
    rm -rf /root/.cache /var/cache/yum
RUN yum install --assumeyes --noplugins gcc gcc-c++ openssl python34-devel python34-pip && \
    yum clean all && rm -rf /tmp/rpms && \
    rm -rf /root/.cache /var/cache/yum

RUN pip3 --no-cache-dir install notebook saspy sas_kernel \
    swat && \
    jupyter nbextension install --py sas_kernel.showSASLog && \
    jupyter nbextension enable sas_kernel.showSASLog --py && \
    jupyter nbextension install --py sas_kernel.theme && \
    jupyter nbextension enable sas_kernel.theme --py
    # Uncomment the following and add '&& \' to the previous line to disable the Python kernel
    #pip3 uninstall -y terminado && \
    #jupyter kernelspec remove python3 -f

COPY post_deploy.sh /tmp/post_deploy.sh
RUN chmod +x /tmp/post_deploy.sh

COPY jupyter_proxy.conf /etc/httpd/conf.d/jupyter_proxy.conf

