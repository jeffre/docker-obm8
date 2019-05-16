FROM centos:latest
ENV PATH="${PATH}:/obm/bin:/bootstrap" \
    APP=obm \
    APP_HOME=/obm
WORKDIR ${APP_HOME}

COPY ${APP}/ docker-entrypoint.sh ./

RUN \
# Prevent Scheduler from daemonizing
  sed -i "bin/Scheduler.sh" \
    -e 's|> "\${APP_HOME}/log/Scheduler/console.log" 2>&1 &||g' \
# Run install script
  && ./bin/install.sh

ENTRYPOINT ["docker-entrypoint.sh"]
