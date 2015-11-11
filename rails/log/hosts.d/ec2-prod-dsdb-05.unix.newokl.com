default ks
prompt 0
timeout 20
label ks
kernel CentOS-5.9-x86_64/vmlinuz
append ks=nfs:10.110.2.101:/etc/synto/netinstall/hosts.d/ec2-prod-dsdb-05.unix.newokl.com/anaconda-ks.cfg initrd=CentOS-5.9-x86_64/initrd.img lang= ramdisk_size=9216 ksdevice=eth0
