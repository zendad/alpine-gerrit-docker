FROM openjdk:8-jre-alpine

MAINTAINER Dereck Zenda <dereck.zenda@gmail.com>

# Overridable defaults
ENV GERRIT_HOME /opt/gerrit
ENV GERRIT_SITE $GERRIT_HOME
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 3.0.1
ENV GERRIT_USER gerrit

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -D -h "${GERRIT_HOME}" -g "Gerrit User" -s /sbin/nologin "${GERRIT_USER}"

RUN set -x \
    && apk add --update --no-cache git openssh-client openssl bash perl perl-cgi git-gitweb curl su-exec procmail wget python build-base gcc iputils zip tar apache-ant unzip

RUN mkdir /docker-entrypoint-init.d

#Download gerrit.war
RUN curl -fSsL https://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war -o $GERRIT_WAR
#Only for local test
#COPY gerrit-${GERRIT_VERSION}.war $GERRIT_WAR

#Download Plugins
ENV PLUGIN_VERSION=bazel-stable-3.0
ENV GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-bin/plugins

## several plugins
RUN curl -fSsL  https://gerrit-ci.gerritforge.com/job/plugin-avatars-gravatar-bazel-master-stable-3.0/5/artifact/bazel-bin/plugins/avatars-gravatar/avatars-gravatar.jar -o ${GERRIT_HOME}/avatars-gravatar.jar

RUN curl -fSsL https://gerrit-ci.gerritforge.com/job/plugin-motd-bazel-stable-2.15/lastSuccessfulBuild/artifact/bazel-bin/plugins/motd/motd.jar -o ${GERRIT_HOME}/motd.jar

RUN curl -fSsL https://gerrit-ci.gerritforge.com/job/plugin-uploadvalidator-bazel-master-stable-3.0/lastSuccessfulBuild/artifact/bazel-bin/plugins/uploadvalidator/uploadvalidator.jar -o ${GERRIT_HOME}/uploadvalidator.jar

RUN curl -fSsL https://gerrit-ci.gerritforge.com/job/plugin-quota-bazel-stable-2.16/lastSuccessfulBuild/artifact/bazel-bin/plugins/quota/quota.jar -o ${GERRIT_HOME}/quota.jar


#events-log
#This plugin is required by gerrit-trigger plugin of Jenkins.
RUN curl -fSsL \
    ${GERRITFORGE_URL}/job/plugin-events-log-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar \
    -o ${GERRIT_HOME}/events-log.jar

#oauth2
RUN curl -fSsL \
    ${GERRITFORGE_URL}/job/plugin-oauth-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/oauth/oauth.jar \
    -o ${GERRIT_HOME}/oauth.jar

#importer
# Not ready for 3.0
#RUN curl -fSsL \
#    ${GERRITFORGE_URL}/job/plugin-importer-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/importer/importer.jar \
#    -o ${GERRIT_HOME}/importer.jar

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-entrypoint.sh /
COPY gerrit-start.sh /
RUN chmod +x /gerrit*.sh

#A directory has to be created before a volume is mounted to it.
#So gerrit user can own this directory.
RUN chmod +x /gerrit*.sh

#A directory has to be created before a volume is mounted to it.
#So gerrit user can own this directory.
RUN su-exec ${GERRIT_USER} mkdir -p $GERRIT_SITE

#Gerrit site directory is a volume, so configuration and repositories
#can be persisted and survive image upgrades.
VOLUME $GERRIT_SITE

WORKDIR $GERRIT_SITE

ENTRYPOINT ["/gerrit-entrypoint.sh"]

EXPOSE 8080 29418


CMD ["/gerrit-start.sh"]
