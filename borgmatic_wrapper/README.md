1. Create a config file using `borgmatic_template.config` as a sample.

2. Create an anacrontab file using `borgmatic_anacrontab_template` as
   a sample. Fill in your config file location.

3. Add the following to your crontab. It's OK to use your non-root user.
  ```bash
# Backup bellatrix
# -d: don't deamonize
# -s: serialize execution
# -t: use this anacrontab file instead of system's
# -S: use a spool that is writable by the current user if running as non-root
*/30 *        * * *           chronic anacron -d -s -t /home/yanli/config/etc/backup-anacrontab -S /home/yanli/.anacron/spool
```

4, You could pass other parameters to `borgmatic_wrapper.sh` directly
   on the command line. For instance, pass `-v 1 --progress` to show
   the progress. Pass "check --repair" to do check and repair.
