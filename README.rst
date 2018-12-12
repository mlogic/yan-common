INTRODUCTION
============

Yan's collection of scripts for daily chores. Use at your own risk!
There is no warranty, but I do welcome comments/issues/pull requests.

* del: Use this instead of rm because rm is too risky. del uses /tmp
  as a recycle bin so you can recover your files until you reboot.
* distill-pdf.sh: Distill a PDF and generat a (somehow) PDF/A
  compliant PDF file using GhostScript.
* media/to-webp-lossless.sh: Convert images to best-compression
  lossless webp and preserve metadata. Useful for reduce the space for
  archiving large images that need lossless compression.
* os/clean-up-dangling-docker-images.sh
* os/clean-up-remote-dangling-docker-images.sh: Clean up dangling
  (unused) docker images to save disk space on a remote host via ssh.
* os/{daily-health-monitor.sh,enable-health-monitors.yaml}: Handy
  script for checking system health that should be run daily on
  servers and sending out emails.
* os/git-compare-remote.sh: Check if a git-repo against its remote
  branch.
* os/is-{debian/rhel}.sh: Distro detection.
* os/pull-docker-base-image.sh: Pull the base image referred to by a
  dockerfile.
* os/start-virtualbox-vm.yaml: Ansible playbook for starting a
  VirtualBox VM and waiting until it starts accepting SSH connection.
* os/stop-virtualbox-vm.yaml: Ansible playbook for stop a
  VirtualBox VM and waiting until it is fully stopped.
* remote-backup: Incremental, differential, de-duplicated backup tool
  using zpaq (http://mattmahoney.net/dc/zpaq.html). This tool creates
  snapshots and uploads them to a remote host.
* shell/_check.sh: A shell function for checking a condition with
  timeout.
* vbox-remove-old-auto-snapshots.sh: A tool for keeping a certain
  number of VirtualBox snapshots and removing the older ones.
* roles/bootstrap-linux: default tasks that need to be done on all my
  newly installed Debian/Ubuntu/CentOS 7 systems.
* roles/mail-relay-gmx: set up a host to send outgoing emails through
  a GMX relay account.
* roles/mysql-container: Start a MySQL container and wait until it
  starts to accept incoming requests.
* roles/reboot: Reboot a host and wait for it to come back online.
* roles/local-security-scanners: Install and set up local security
  scanners (for now it only includes ClamAV). The local security scan
  is done weekly and any changes are mailed to you. Check
  `roles/local-security-scanners/README` for instructions.
* roles/bootstrap-docker: Install Docker CE.
* replace-text-block.py: Find and replace a block of text.
* roles/ipv6: Disable or enable IPv6.

Check out the README file of each tool for help information.


Supported OS
============

`Ubuntu 18.10 <https://www.ubuntu.com/>`_ and `CentOS 7
<https://www.centos.org/>`_ are my work horse OS so most scripts here
are tested on them. I also use `Debian <http://www.debian.org/>`_
(usually the stable and testing branches) but not all scripts are
tested on Debian. I welcome patches for making these scripts work on
other OS and other kinds of improvements.

Naming Convention
=================

Generally scripts that begin with _ are support scripts that will be
called by other scripts.


Test Status
============

.. image:: https://travis-ci.org/mlogic/yan-common.svg?branch=master
   :alt: Build Status
   :target: https://travis-ci.org/mlogic/yan-common
