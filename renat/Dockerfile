# base information
FROM bachng/renat_base7:latest
LABEL maintainer="bachng@gmail.com"

# Copy RENAT source
ADD renat_project/ /home/robot/work/renat/

# startup cmds
USER root
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


