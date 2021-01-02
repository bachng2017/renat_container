# base information
FROM bachng:renat_base7
LABEL maintainer="bachng@gmail.com"

# Copy RENAT source
ADD renat_project: /home/robot/work/

# startup cmds
USER root
COPY files/tmp/entry.sh /tmp
ENTRYPOINT ["/tmp/entry.sh"]


