install_nfs:
  pkg.installed:
    - name: nfs-kernel-server

start_nfs:
  service.running:
    - name: nfs-server
    - enable: True

/etc/exports:
  file.managed:
    - name: /etc/exports
    - source: salt://nfs/server/nfs_config

/media/nfs:
  file.directory:
    - user: vagrant
    - group: users
    - mode: 755
