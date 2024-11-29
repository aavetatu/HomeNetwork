install_nfs_now:
  pkg.installed:
    - pkgs:
      - nfs-kernel-server
