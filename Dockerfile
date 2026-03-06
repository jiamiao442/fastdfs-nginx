## Dockerfile
FROM ubuntu:24.04

LABEL maintainer="379289162@qq.com"

ENV FASTDFS_PATH=/usr/local/src \
  FASTDFS_BASE_PATH=/data/fdfs \
  LIBFASTCOMMON_VERSION="V1.0.84" \
  LIBSERVERFRAME_VERSION="master" \
  FASTDFS_NGINX_MODULE_VERSION="V1.26" \
  FASTDFS_VERSION="V6.15.3" \
  NGINX_VERSION="1.28.2" \
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

# 安装 tzdata 包以配置时区
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

# 配置时区为 Asia/Shanghai
RUN echo $TZ > /etc/timezone && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# get all the dependences
RUN apt-get update && apt-get install -y curl git gcc make wget libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev liburing-dev \
  && rm -rf /var/lib/apt/lists/*


WORKDIR ${FASTDFS_PATH}

## compile the libfastcommon
RUN git clone --depth=1 -b $LIBFASTCOMMON_VERSION https://github.com/happyfish100/libfastcommon.git libfastcommon \
  && cd libfastcommon \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/libfastcommon

## compile the libserverframe
RUN git clone --depth=1 -b $LIBSERVERFRAME_VERSION https://github.com/happyfish100/libserverframe.git libserverframe \
  && cd libserverframe \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/libserverframe

## compile the fastdfs
RUN git clone --depth=1 -b $FASTDFS_VERSION https://github.com/happyfish100/fastdfs.git fastdfs \
  && cd fastdfs \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/fastdfs


## comile nginx
# nginx url: https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
# tengine url: http://tengine.taobao.org/download/tengine-${TENGINE_VERSION}.tar.gz
RUN git clone --depth=1 -b $FASTDFS_NGINX_MODULE_VERSION https://github.com/happyfish100/fastdfs-nginx-module.git fastdfs-nginx-module \
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
  && rm -rf ${FASTDFS_PATH}/fastdfs-nginx-module

EXPOSE 22122 23000 9088
VOLUME ["${FASTDFS_BASE_PATH}","/etc/fdfs","/usr/local/nginx/conf/conf.d"]

COPY fastdfs-conf/conf/*.* /etc/fdfs/
COPY fastdfs-conf/nginx_conf/nginx.conf /usr/local/nginx/conf/
COPY fastdfs-conf/nginx_conf.d/*.conf /usr/local/nginx/conf.d/

COPY entrypoint.sh /usr/bin/

#make the entrypoint.sh executable 
RUN chmod a+x /usr/bin/entrypoint.sh

WORKDIR ${FASTDFS_PATH}

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["tracker"]
