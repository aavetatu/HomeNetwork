install_nfs_common:
  pkg.installed:
    - name: nfs-common

/media/share:
  file.directory:
    - user: vagrant
    - group: users
    - mode: 755

/etc/fstab:
  file.managed:
    - name: /etc/fstab
    - source: salt://nfs/client/fstab_config
