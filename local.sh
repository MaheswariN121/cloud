 #!/bin/bash

       exec 1>/tmp/rc.local.log 2>&1
       set -x
       touch /var/lock/subsys/local
       sh /home/ec2-user/startup.sh

       exit 0
