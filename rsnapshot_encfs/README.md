1. Create a config file using `rsnapshot_encfs_template.config` as a
   sample.

2. Create an anacrontab file using
   `rsnapshot_encfs_anacrontab_template` as a sample. Fill in your
   config file location.

3. Add the following to your crontab. It's OK to use your non-root user.
  ```bash
# Backup bellatrix
# -d: don't deamonize
# -s: serialize execution
# -t: use this anacrontab file instead of system's
# -S: use a spool that is writable by the current user if running as non-root
*/30 *        * * *           anacron -d -s -t /home/yanli/config/etc/bellatrix-anacrontab -S /home/yanli/.anacron/spool
```

