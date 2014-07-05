#!/bin/bash -v
chown -R dockerx /usr/local/Elexis3
if [ ! -f /.root_pw_set ]; then
	/set_root_pw.sh
fi

# /etc/init.d/ssh start
/etc/init.d/ssh status

/etc/init.d/x2goserver start
/etc/init.d/x2goserver status

/usr/sbin/sshd -D
