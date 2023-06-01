## Dockerfile
#FROM centos:7
FROM alpine:3.16

LABEL maintainer="379289162@qq.com"

ENV FASTDFS_PATH=/usr/local/src \
  FASTDFS_BASE_PATH=/data/fdfs \
  LIBFASTCOMMON_VERSION="V1.0.66" \
  LIBSERVERFRAME_VERSION="V1.1.25" \
  FASTDFS_NGINX_MODULE_VERSION="V1.23" \
  FASTDFS_VERSION="V6.9.4" \
  NGINX_VERSION="1.23.3" \
  PORT='' \
  GROUP_NAME='' \
  TRACKER_SERVER='' \
  TZ="Asia/Shanghai"

RUN mkdir -p ${FASTDFS_PATH}/libfastcommon \
  && mkdir -p ${FASTDFS_PATH}/libserverframe \
  && mkdir -p ${FASTDFS_PATH}/fastdfs \
  && mkdir -p ${FASTDFS_PATH}/fastdfs-nginx-module \
  && mkdir -p ${FASTDFS_BASE_PATH}

WORKDIR ${FASTDFS_PATH}
#get all the dependences and nginx
#RUN yum install -y git gcc make wget pcre pcre-devel openssl openssl-devel \
#  && rm -rf /var/cache/yum/*
# 0.change the system source for installing libs
RUN  apk update  && apk add --no-cache --virtual .build-deps bash autoconf gcc libc-dev make pcre-dev zlib-dev linux-headers gnupg libxslt-dev gd-dev geoip-dev wget git \
  && git clone -b ${LIBFASTCOMMON_VERSION} https://github.com/happyfish100/libfastcommon.git libfastcommon \
  && cd libfastcommon \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/libfastcommon \
  && cd ..   \
  && git clone -b ${LIBSERVERFRAME_VERSION} https://github.com/happyfish100/libserverframe.git libserverframe \
  && cd libserverframe \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/libserverframe \
  && cd ..  \
  && git clone -b ${FASTDFS_VERSION} https://github.com/happyfish100/fastdfs.git fastdfs \
  && cd fastdfs \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/fastdfs \
  && cd .. \
  && git clone -b ${FASTDFS_NGINX_MODULE_VERSION} https://github.com/happyfish100/fastdfs-nginx-module.git fastdfs-nginx-module \
  && wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar -zxf nginx-${NGINX_VERSION}.tar.gz \
  && cd nginx-${NGINX_VERSION} \
  && ./configure --prefix=/usr/local/nginx \
      --add-module=${FASTDFS_PATH}/fastdfs-nginx-module/src/ \
      --with-stream=dynamic \
  && make \
  && make install \
  && ln -s /usr/local/nginx/sbin/nginx /usr/bin/ \
  && rm -rf ${FASTDFS_PATH}/nginx-* \
  && rm -rf ${FASTDFS_PATH}/fastdfs-nginx-module \
  && apk del .build-deps \
  && rm -rf /var/cache/apk/*

EXPOSE 22122 23000 9088
VOLUME ["${FASTDFS_BASE_PATH}","/etc/fdfs","/usr/local/nginx/conf/conf.d"]

COPY fastdfs-conf/conf/*.* /etc/fdfs/
COPY fastdfs-conf/nginx_conf/nginx.conf /usr/local/nginx/conf/
COPY fastdfs-conf/nginx_conf.d/*.conf /usr/local/nginx/conf.d/

COPY entrypoint.sh /usr/bin/

#make the entrypoint.sh executable 
RUN chmod a+x /usr/bin/entrypoint.sh \
   && apk add --no-cache bash pcre-dev zlib-dev \
   && apk add --no-cache alpine-conf  \
   && /sbin/setup-timezone -z ${TZ} \
   && apk del alpine-conf \
   && rm -rf /var/cache/apk/*

WORKDIR ${FASTDFS_PATH}

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["tracker"]
