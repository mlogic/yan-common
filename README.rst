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
* media/to-png.sh: Convert images to best-compression lossless png
  using optipng.
* os/{daily-health-monitor.sh,enable-health-monitors.yaml}: Handy
  script for checking system health that should be run daily on
  servers and sending out emails.
* os/fileset_par2.py: create par2 files recursively for a set of files.
* os/git-compare-remote.sh: Check if a git-repo against its remote
  branch.
* os/if-bytes-warn.sh: Check the bytes sent from all NICs and sent a
  warning email or run a command.
* os/is-{debian/rhel}.sh: Distro detection.
* os/powertune.sh: Run `powertop --auto-tune` but disable autosuspend
  for USB HID device because autosuspend could make most of them
  unusable.
* os/pull-docker-base-image.sh: Pull the base image referred to by a
  dockerfile.
* os/run_until_success.sh: Run a command until success.
* os/start-virtualbox-vm.yaml: Ansible playbook for starting a
  VirtualBox VM and waiting until it starts accepting SSH connection.
* os/stop-virtualbox-vm.yaml: Ansible playbook for stop a
  VirtualBox VM and waiting until it is fully stopped.
* remote-backup: Incremental, differential, de-duplicated backup tool
  using zpaq (http://mattmahoney.net/dc/zpaq.html). This tool creates
  snapshots and uploads them to a remote host.
* borgmatic_wrapper: A wrapper script for running borgmatic with
  anacron. Retry automatically on flaky network.
* shell/_check.sh: A shell function for checking a condition with
  timeout.
* vbox-remove-old-auto-snapshots.sh: A tool for keeping a certain
  number of VirtualBox snapshots and removing the older ones.
* roles/bootstrap-linux: default tasks that need to be done on all my
  newly installed Debian/Ubuntu systems.
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

I am currently using `Ubuntu <https://www.ubuntu.com/>`_ 20.10 and
`Debian <http://www.debian.org/>`_, and have only tested these tools
on them. I no longer have CentOS installation, so CentOS support will
gradually be removed unless someone else want to step up. But patches
for supporting other OS and any kinds of improvements are always
welcome!


TODO
====

* Many scripts lack test cases.


Naming Convention
=================

I try to follow Google's style as closely as possible:

* `Google Shell Style Guide
  <https://google.github.io/styleguide/shellguide.html>`_
* `Google Python Style Guide
  <https://google.github.io/styleguide/pyguide.html>`_

Scripts that begin with `_` are support scripts that generally
shouldn't be called by users directly.

Code that doesn't conform to the style guide will be fixed
gradually. Patches are welcome!


Test Status
============

.. image:: https://travis-ci.org/mlogic/yan-common.svg?branch=master
   :alt: Build Status
   :target: https://travis-ci.org/mlogic/yan-common
