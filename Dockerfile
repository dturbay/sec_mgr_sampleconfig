FROM maven:3.5.4-jdk-8 AS BUILD

ENV BUILD_APP_DIR=/usr/src/myapp

COPY ./secmgr/src ${BUILD_APP_DIR}/src
COPY ./secmgr/pom.xml ${BUILD_APP_DIR}

RUN mvn -f ${BUILD_APP_DIR}/pom.xml clean package -Dmaven.test.skip=true


# -----------------------

FROM tomcat:8.0-jre8

ARG AUTH_SITES_FILE_NAME
ARG HTTP_PORT
ARG HTTPS_PORT
ARG HOST_NAME
ARG METADATA_CONFIG

ENV WEB_APP_PATH=/opt/security-manager
ENV WEB_APP_CONF_PATH=/opt/security-manager-conf

COPY --from=BUILD /usr/src/myapp/target/security-manager-1.0-SNAPSHOT ${WEB_APP_PATH}

COPY ./config ${WEB_APP_CONF_PATH}

RUN cd ${WEB_APP_CONF_PATH} && ln -s ${AUTH_SITES_FILE_NAME} SampleAuthSites.json

COPY ./config/logging.properties ${WEB_APP_PATH}/WEB-INF/classes
COPY ./config/security-manager.xml ${CATALINA_HOME}/conf/Catalina/localhost/
RUN sed -i "s@#APP_PATH#@${WEB_APP_PATH}@" ${CATALINA_HOME}/conf/Catalina/localhost/security-manager.xml \
	&& sed -i "s@#AUTHN_SITES_PATH#@${WEB_APP_CONF_PATH}/SampleAuthSites.json@" ${CATALINA_HOME}/conf/Catalina/localhost/security-manager.xml \
	&& sed -i "s@#CONFIG_DIR#@${WEB_APP_CONF_PATH}@" ${WEB_APP_CONF_PATH}/SampleAuthSites.json

RUN cp --backup=numbered ${WEB_APP_CONF_PATH}/server.xml ${CATALINA_HOME}/conf

COPY ./keystore.p12 ${WEB_APP_CONF_PATH}

COPY ./secmgr1.crt /usr/local/share/ca-certificates/secmgr1.crt
RUN update-ca-certificates
RUN keytool -noprompt -import -alias secmgr1 -file /usr/local/share/ca-certificates/secmgr1.crt -keystore cacerts -storepass changeit


RUN sed -i -e "s|{HTTP_PORT}|${HTTP_PORT}|" -e "s|{HTTPS_PORT}|${HTTPS_PORT}|" ${CATALINA_HOME}/conf/server.xml

RUN cp ${WEB_APP_CONF_PATH}/${METADATA_CONFIG} ${WEB_APP_CONF_PATH}/saml-metadata.xml

EXPOSE ${HTTPS_PORT}
EXPOSE ${HTTP_PORT}



