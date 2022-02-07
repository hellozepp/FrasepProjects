FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y python3-pip \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install numpy pandas sklearn matplotlib seaborn jupyter pyyaml h5py && \
    pip3 install imutils \
    pip3 saspy sas_kernel\
    pip3 install swat \
    pip3 install dlpy \
    pip3 install esppy

RUN ["mkdir", "notebooks"]
COPY conf/.jupyter /root/.jupyter
COPY run_jupyter.sh /

# Jupyter and Tensorboard ports
EXPOSE 8888 6006

# Store notebooks in this mounted directory
VOLUME /notebooks

CMD ["/run_jupyter.sh"]
