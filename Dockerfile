FROM ubuntu:trusty
MAINTAINER Casey Link <casey@outskirtslabs.com>

WORKDIR /
RUN apt-get update && \
    apt-get -yq install mysql-client

ADD create-db.sh /create-db.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Expose environment variables
ENV DB_HOST **LinkMe**
ENV DB_PORT **LinkMe**
ENV DB_ADMIN_USER admin
ENV DB_ADMIN_PASS **ChangeMe**
ENV DATA_DB_USER **ChangeMe**
ENV DATA_DB_PASS **ChangeMe**
ENV DATA_DB_NAME **ChangeMe**

VOLUME ["/app/wp-content"]
CMD ["/run.sh"]
