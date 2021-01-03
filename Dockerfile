# base information
FROM bachng/renat_base7:latest
LABEL maintainer="bachng@gmail.com"

# Set environment
ENV RENAT_PATH /home/robot/work/renat

# Copy RENAT source
ADD renat_project/ /home/robot/work/renat/

# Update document
RUN cd $RENAT_PATH/doc && ./run.sh


