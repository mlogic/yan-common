INTRODUCTION
============

Yan's collection of scripts for daily chores. Use at your own risk!
There is no warranty. But I still welcome comments/issues/pull
requests.

* del: Use this instead of rm because rm is too risky. del uses /tmp
  as a recycle bin so you can recover your files until you reboot.
* distill-pdf.sh: Distill a PDF and generat a (somehow) PDF/A
  compliant PDF file using GhostScript.
* os/clean-up-dangling-docker-images.sh
* os/os/clean-up-remote-dangling-docker-images.sh: Clean up dangling
  (unused) docker images to save disk space on a remote host via ssh.
* os/{daily-health-monitor.sh,enable-health-monitors.yaml}: Handy
  script for checking system health that should be run daily on
  servers and sending out emails.
* os/start-virtualbox-vm.yaml: Ansible playbook for starting a
  VirtualBox VM.
* remote-backup: Incremental, differential, de-duplicated backup tool
  using zpaq (http://mattmahoney.net/dc/zpaq.html). This tool creates
  snapshots and uploads them to a remote host.
* shell/_check.sh: A shell function for checking a condition with
  timeout.
* vbox-remove-old-auto-snapshots.sh: A tool for keeping a certain
  number of VirtualBox snapshots and removing the older ones.

Check out each tool for help information.


Supported OS
============

`CentOS <https://www.centos.org/>`_ (usually the latest and latest-1
releases) is my work horse OS so most scripts here are tested on it. I
also use `Debian <http://www.debian.org/>`_ (usually the stable and
testing branches) but not all scripts are tested on Debian.

Naming Convention
=================

Generally scripts that begin with _ are support scripts that will be
called by other scripts.


Test Status
============

.. image:: https://travis-ci.org/mlogic/yan-common.svg?branch=master
   :alt: Build Status
   :target: https://travis-ci.org/mlogic/yan-common
