FROM maven:3.5.4-jdk-8 AS BUILD

#RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev

#ENV PROTOBUF_VERSION=3.5.1

#RUN mkdir -p /protobuf && \
#    curl -L https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz | tar xvz --strip-components=1 -C /protobuf

#RUN cd /protobuf && \
#    autoreconf -f -i -Wall,no-obsolete && \
#    ./configure --prefix=/usr --enable-static=no && \
#    make -j2 && make install

ENV BUILD_APP_DIR=/usr/src/myapp

COPY ./secmgr/src ${BUILD_APP_DIR}/src
COPY ./secmgr/lib ${BUILD_APP_DIR}/lib
COPY ./secmgr/pom.xml ${BUILD_APP_DIR}

RUN mvn install:install-file -Dfile=${BUILD_APP_DIR}/lib/cryptix-jce-provider.jar -DgroupId=cryptix -DartifactId=cryptix-jce -Dversion=na -Dpackaging=jar
RUN mvn -f ${BUILD_APP_DIR}/pom.xml clean package


# -----------------------

FROM tomcat:8.0-jre8

# TODO: remove after file gets completed
RUN apt update && apt install -y less vim

ENV WEB_APP_PATH=/opt/security-manager
ENV WEB_APP_CONF_PATH=/opt/security-manager-conf

COPY --from=BUILD /usr/src/myapp/target/security-manager-1.0-SNAPSHOT ${WEB_APP_PATH}

COPY ./config ${WEB_APP_CONF_PATH}

ARG AUTH_SITES_FILE_NAME
RUN cd ${WEB_APP_CONF_PATH} && ln -s ${AUTH_SITES_FILE_NAME} SampleAuthSites.json

COPY ./config/logging.properties ${WEB_APP_PATH}/WEB-INF/classes
COPY ./config/security-manager.xml ${CATALINA_HOME}/conf/Catalina/localhost/
RUN sed -i "s@#APP_PATH#@${WEB_APP_PATH}@" ${CATALINA_HOME}/conf/Catalina/localhost/security-manager.xml \
	&& sed -i "s@#AUTHN_SITES_PATH#@${WEB_APP_CONF_PATH}/SampleAuthSites.json@" ${CATALINA_HOME}/conf/Catalina/localhost/security-manager.xml \
	&& sed -i "s@#CONFIG_DIR#@${WEB_APP_CONF_PATH}@" ${WEB_APP_CONF_PATH}/SampleAuthSites.json

RUN keytool -genkey -noprompt -trustcacerts -keyalg RSA -alias tomcat -dname "CN=secmgr.com, OU=ou, O=o, L=l, S=s ,C=us" -keystore ${WEB_APP_CONF_PATH}/keystore.jks -keypass changeit -storepass changeit

RUN cp --backup=numbered ${WEB_APP_CONF_PATH}/server.xml ${CATALINA_HOME}/conf

ARG SP_SAML_ENTITY
ARG IDP_SAML_ENTITY
ARG SEC_MGR_HOST_PORT
ARG ARTIFACT_CONSUMER_URL


RUN sed -i "s|{SP_SAML_ENTITY}|${SP_SAML_ENTITY}|" ${WEB_APP_CONF_PATH}/saml-metadata.xml \
	&& sed -i "s|{IDP_SAML_ENTITY}|${IDP_SAML_ENTITY}|" ${WEB_APP_CONF_PATH}/saml-metadata.xml \
	&& sed -i "s|{SEC_MGR_HOST_PORT}|${SEC_MGR_HOST_PORT}|" ${WEB_APP_CONF_PATH}/saml-metadata.xml \
	&& sed -i "s|{ARTIFACT_CONSUMER_URL}|${ARTIFACT_CONSUMER_URL}|" ${WEB_APP_CONF_PATH}/saml-metadata.xml

EXPOSE 8443
EXPOSE 8080



