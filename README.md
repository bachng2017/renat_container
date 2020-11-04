A container for RENAT server. Check https://github.com/bachng2017/RENAT for more details.

A super simple way to try RENAT is running it from a container. Below are instructions.

1. import docker image from dockerhub

    ```
    $ docker pull bachng/renat:latest
    ```

2. prepare local user and data folder (optional)
    By default, RENAT will create a default user with UID/GID as 5000:5000. To match the uid/gid and also make configuration and created scenario persistent, prepare those steps.
 
    ```
    $ groupadd -g 5000 renat
    $ useradd -u 5000 -g 5000 robot
    $ mkdir config
    $ chown robot:renat config
    $ chmod 0775 config
    $ mkdir scenario
    $ chown robot:renat scenario
    $ chmod 0775 scenario
    ```
    Folder `config` will be mapped to the `$RENAT_PATH/config` folder and folder `scenario` will be mapped to `~robot/work/scenario` on the container. If mapping was set correctly, modified configuration and created scenario will remain even after the container is stopped or initialized again.

2. start the container that opens port 80 and 10022

    ```
    $ docker run -td --privileged --rm \
		-v <config_full_path>:/home/robot/work/renat/config \
		-v <scenario_full_path>:/home/robot/work/scenario \
		-p 80:80 -p 10022:22 --name renat bachng/renat:latest -g logstash
    ```
    The server runs in UTC timezone by default.Add  below option to change the timezone:

    ```
    -z Asia/Tokyo 
    ```

    Another option is the `-g` which define where to send the running information (syslog format) to a ELK filebeat collector.

    At this point, a RENAT server will all necessary packages and latest RENAT is ready with predefined `robot` user.

3. login to the container as `robot` user

    ```
    $ docker exec -it --user robot renat /bin/bash --login
    ```
4. create a test scenario

    ```
    [robot@afeb42da1974 renat]$ cd scenario
    [robot@afeb42da1974 renat]$ $RENAT_PATH/tools/project.sh renat-sample
    [robot@afeb42da1974 renat]$ cd renat-sample
    [robot@afeb42da1974 renat]$ $RENAT_PATH/tools/item.sh -b -l test01
    ```

    A `do nothing` scenario is made. Check test01/main.robot for more details
5. run and check the result

    ```
    [robot@afeb42da1974 renat]$ cd test01
    [robot@afeb42da1974 renat]$ ./run.sh
    ```

    Test results and logs could be checked by a browser as `http://<host_IP>/~robot/result.log`


