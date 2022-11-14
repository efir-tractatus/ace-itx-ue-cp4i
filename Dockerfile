FROM cp.icr.io/cp/appc/ace-server-prod:12.0.5.0-r2-20220725-153735@sha256:a61d6f4a442811b59c43e2a5af7014ffb66d8b6dd8b084ac998279d3ccf702bf

USER root

# Loading MQ libs
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/mqm/lib64

#ITX Libs injection
RUN mkdir /opt/ibm/itx
COPY itx /opt/ibm/itx
COPY libs/libnsl-2.28.so /lib64/
RUN ln -s /lib64/libnsl-2.28.so /lib64/libnsl.so.1 \
    && cp /opt/ibm/itx/wmqi/dtxwmqi.sh /var/mqsi/common/profiles/ \
    && chown -R aceuser:aceuser /var/mqsi/common/profiles/ \ 
    && chown -R aceuser:aceuser /opt/ibm/itx

# User exit injection
RUN mkdir /var/mqsi/WMBTM
COPY userexit/WMBTM.lel /var/mqsi/exits/

# Testing ITX
USER aceuser
RUN mkdir -p /home/aceuser/data/file_in \ 
    && mkdir -p /home/aceuser/data/file_out \
    && chmod -R 777 /home/aceuser/data