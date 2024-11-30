install_nfs:
  pkg.installed:
    - name: nfs-kernel-server

start_nfs:
  service.running:
    - name: nfs-server
    - enable: True

push_nfs_conf:
  file.managed:
    - name: /etc/exports
    - source: salt://nfs/nfs_config

