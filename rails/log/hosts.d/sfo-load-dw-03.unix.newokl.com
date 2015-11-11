default ks
prompt 0
timeout 20
label ks
kernel Debian-6.0.6-amd64/vmlinuz
append ks=nfs:10.110.2.101:/etc/synto/netinstall/hosts.d/sfo-load-dw-03.unix.newokl.com/anaconda-ks.cfg initrd=CentOS-5.9-x86_64/initrd.img lang= ramdisk_size=9216 ksdevice=eth0
