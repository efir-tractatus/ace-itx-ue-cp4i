FROM cp.icr.io/cp/appc/ace-server-prod:12.0.7.0-r4-20230222-094320@sha256:558e2d74fdd4ea291d56eab1360167294e3385defa7fe1f4701b27dbb6e6bba6

USER root

# Loading MQ libs
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/mqm/lib64

#ITX Libs injection
RUN mkdir /opt/ibm/itx
COPY itx /opt/ibm/itx
COPY libs/libnsl-2.28.so /lib64/
RUN ln -s /lib64/libnsl-2.28.so /lib64/libnsl.so.1 \
    && cp /opt/ibm/itx/wmqi/dtxwmqi.sh /var/mqsi/common/profiles/ \
    && chmod -R 777 /var/mqsi/common/profiles/ \ 
    && chmod -R 777 /opt/ibm/itx

# User exit injection
RUN mkdir /var/mqsi/WMBTM
COPY userexit/WMBTM.lel /var/mqsi/exits/

# Testing ITX
USER aceuser
RUN mkdir -p /home/aceuser/data/file_in \ 
    && mkdir -p /home/aceuser/data/file_out \
    && chmod -R 777 /home/aceuser/data
