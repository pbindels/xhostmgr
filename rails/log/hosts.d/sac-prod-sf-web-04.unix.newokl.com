default ks
prompt 0
timeout 20
label ks
kernel CentOS-5.9-x86_64/vmlinuz
append ks=nfs:10.120.3.04:/etc/synto/netinstall/hosts.d/sac-prod-sf-web-04.unix.newokl.com/anaconda-ks.cfg initrd=CentOS-5.9-x86_64/initrd.img lang= ramdisk_size=9216 ksdevice=eth0
