FROM crystallang/crystal
RUN mkdir /tmp/crystal-cache
ENV CRYSTAL_CACHE_DIR /tmp/crystal-cache
WORKDIR /app
COPY func.cr .
RUN crystal build func.cr

RUN mkdir -p /tmp/iofs
CMD ./func
