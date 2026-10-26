#!/usr/bin/env python3
# Maintain/verify par2 files for a set of files based on mtime
#
# Copyright (c) 2016-2021, Yan Li <yanli@tuneup.ai>,
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of yan-common nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# TODO:
# 1. better documentation

import argparse
import grp
import math
import logging
import os
import pwd
import sys
import concurrent.futures

DRY_RUN = False
BASE_DIR = ''
logger = None

# par2create splits a file into 2000 blocks by default, so with -r1 any file
# smaller than 2000 * 4096 bytes gets recovery blocks smaller than a disk
# sector and can't repair even one bad sector. For such files we use
# sector-sized blocks and 1% (at least one) recovery blocks instead, which
# also makes their par2 files much smaller.
DEFAULT_RECOVERY_ARG = '-r1'
PAR2_DEFAULT_BLOCK_COUNT = 2000
SECTOR_SIZE = 4096


def escape_for_bash(name: str) -> str:
    result = name
    # '\\' must be the first one so it wouldn't be escaped twice
    for special_char in ('\\', '"', '`', '$', '*', '?'):
        result = result.replace(special_char, '\\' + special_char)
    return result


def create_par2(file: str, par2_path: str, par2_recovery_file_arg: str):
    '''Create par2 file for file at par2_path.

    Args:
        file: Path of the source data file.
        par2_path: Path of the destination par2 file.
        par2_recovery_file_arg: The args that will be passed to par2create.

    All parent directories will be created automatically. If being run
    as root, the par2 files (and required directories) will be created
    as owned by the same owner and group of their parent.
    '''
    par2_path = os.path.realpath(par2_path)
    assert par2_path[-5:] == '.par2', 'par2_path must end with .par2 ext name'
    par2_path_no_ext = par2_path[0:-5]
    par2_parent_dir = os.path.split(os.path.realpath(par2_path))[0]
    file_parent_dir, file_name = os.path.split(os.path.realpath(file))
    if len(file_name) == 1:
        logger.info(
            f'Ignoring file {file} because par2 cannot process file that has name of length 1')
        return
    if '*' in file_name or '?' in file_name:
        logger.info(
            f'Ignoring file {file} because par2 cannot process file that has wildcards in name')
        return
    file_size = os.path.getsize(file)
    if file_size == 0:
        logger.info(
            f'Ignoring file {file} because par2 cannot process file that has size 0')
        return

    if (par2_recovery_file_arg == DEFAULT_RECOVERY_ARG
            and file_size < PAR2_DEFAULT_BLOCK_COUNT * SECTOR_SIZE):
        recovery_block_count = max(1, math.ceil(file_size / SECTOR_SIZE / 100))
        par2_recovery_file_arg = f'-s{SECTOR_SIZE} -c{recovery_block_count}'

    # -t1: we already run --workers par2 processes in parallel. Letting each
    # one start a thread per CPU oversubscribes the CPUs and par2create on a
    # small file goes from 0.03s to 20+s.
    cmd = (f'set -eu; cd "{escape_for_bash(par2_parent_dir)}" && '
           f'chronic nice -n 19 par2create -t1 "-B{escape_for_bash(file_parent_dir)}" {par2_recovery_file_arg} -n1 '
           f'"{escape_for_bash(par2_path)}" "{escape_for_bash(file)}" && '
           f'mv "{escape_for_bash(par2_path_no_ext)}".vol*.par2 "{escape_for_bash(par2_path_no_ext)}.par2"')
    if not DRY_RUN:
        # Find the uid and gid of the first parent that exists
        higher_parent_dir = par2_parent_dir
        while True:
            if os.path.exists(higher_parent_dir):
                stat = os.stat(higher_parent_dir)
                uid = stat.st_uid
                gid = stat.st_gid
                username = pwd.getpwuid(uid).pw_name
                groupname = grp.getgrgid(gid).gr_name
                break
            higher_parent_dir = os.path.split(higher_parent_dir)[0]

        # Check if we have write permission to the parent dir that exists.
        # Normally you'd use os.access(higher_parent_dir, os.W_OK), but we
        # can't do that here, because if we were root, os.access() would
        # always return success, which might cause a failure when we run
        # mkdir under {username} later. We use [ -w dir ]; to test if we
        # have write access to it.
        if os.geteuid() == 0:
            check_writable_cmd = f'sudo -u {username} -g {groupname} '
        else:
            check_writable_cmd = ''
        check_writable_cmd += f'[ -w "{higher_parent_dir}" ]'
        rc = os.system(check_writable_cmd)
        if rc != 0:
            logger.debug(
                f'Parent directory {higher_parent_dir} is not writable. Granting write permission temporarily...')
            chmod_cmd = f'chmod u+w "{higher_parent_dir}"'
            rc = os.system(chmod_cmd)
            if rc != 0:
                error_msg = f'Failed command with rc {rc}: {chmod_cmd}'
                logger.error(error_msg)
                raise IOError(error_msg)
            need_remove_higher_parent_dir_write_permission = True
        else:
            need_remove_higher_parent_dir_write_permission = False

        try:
            if not os.path.exists(par2_parent_dir):
                if os.geteuid() == 0:
                    # We don't want to create files as root. Change the
                    # owner of the directory to the owner of parent
                    # directory. We use sudo + mkdir -p instead of
                    # os.makedirs() so that all missing directories could
                    # be created with the desired uid and gid
                    # automatically.
                    mkdir_cmd = f'sudo -u {username} -g {groupname} '
                    logger.debug(
                        f'Creating par2 file parent directory(s) with user {username} and group {groupname}')
                else:
                    mkdir_cmd = ''
                    logger.debug('Creating par2 file parent directory(s)')

                mkdir_cmd += f'mkdir -p "{par2_parent_dir}"'
                rc = os.system(mkdir_cmd)
                if rc != 0:
                    error_msg = f'Failed command with rc {rc}: {mkdir_cmd}'
                    logger.error(error_msg)
                    raise IOError(error_msg)
        finally:
            if need_remove_higher_parent_dir_write_permission:
                logger.debug(
                    f'Removing temporary write permission from parent directory {higher_parent_dir}...')
                chmod_cmd = f'chmod u-w "{higher_parent_dir}"'
                rc = os.system(chmod_cmd)
                if rc != 0:
                    error_msg = f'Failed command with rc {rc}: {chmod_cmd}'
                    logger.error(error_msg)
                    raise IOError(error_msg)

        logger.debug(f'Creating par2 file: {cmd}')
        if os.geteuid() == 0:
            cmd += f' && chown {username}:{groupname} "{escape_for_bash(par2_path_no_ext)}.par2"'
        if os.system(cmd) != 0:
            logger.error(
                f'Failed to create par2 file for {file} in {par2_path}')
    else:
        if not os.path.exists(par2_parent_dir):
            print(f'Will create dir {par2_parent_dir}')
        print(cmd)


def verify_par2(file: str, par2_path: str) -> bool:
    par2_parent_dir = os.path.split(os.path.realpath(par2_path))[0]
    file_parent_dir = os.path.split(os.path.realpath(file))[0]
    cmd = f'cd "{escape_for_bash(par2_parent_dir)}" && '\
        f'chronic nice -n 19 par2verify -t1 "-B{escape_for_bash(file_parent_dir)}" "{escape_for_bash(par2_path)}" '\
        f'"{escape_for_bash(file)}"'
    if DRY_RUN:
        print(f'dry run: {cmd}')
        return True
    else:
        logger.info(f'Verifying {file} using par2 file {par2_path}')
        logger.debug(f'Running {cmd}')
        rc = os.system(cmd)
        if rc == 0:
            logger.info(f'Verified file data for {file}')
            return True
        else:
            logger.error(f'CORRUPTED FILE DETECTED: {file}')
            return False


def update_par2(file: str, par2_file: str, no_update: bool, par2_recovery_file_arg: str) -> bool:
    """Verify, update, or create a par2 file for one file

    If the par2 file for the file exists, is not empty and is newer than the
    file, verify the correctness of the file. If the par2 file is older than the
    file, remove the par2 file and create a new one. If the par2 file does not
    exist, create a new one.

    Args:
        file: The path of the source data file.
        par2_file: The path of the destination par2 file.
        no_update: If true, verify only and do not update the par2 file. Returns
            false if the par2 file does not exist or is empty.
        par2_recovery_file_arg: The args that will be passed to par2create.

    :returns false if a corrupted file is detected
    """
    try:
        file_mtime = os.path.getmtime(file)
    except FileNotFoundError:
        # It is possible a file got deleted while we are processing the input
        # list. We should just skip it.
        logger.warning(f'File {file} does not exist, skipping')
        return True
    if os.path.exists(par2_file) and os.path.getsize(par2_file) > 0:
        logger.info(f'par2 file {par2_file} exists')
        par2_mtime = os.path.getmtime(par2_file)
        if file_mtime <= par2_mtime:
            verify_result = verify_par2(file, par2_file)
            if not verify_result:
                logger.error(f'File {file} has mtime {file_mtime}, par2 file {par2_file} '
                             f'has mtime {par2_mtime}.')
            return verify_result
        else:
            if no_update:
                logger.error(f'NO-UPDATE MODE, SKIPPED CHANGED FILE {file}')
                return False
            if DRY_RUN:
                print(f'dry run: rm {par2_file}')
            else:
                print(f'Updating {par2_file}')
                # par2create doesn't overwrite existing par2 file, so we have
                # to remove it first
                os.remove(par2_file)
    else:
        if not os.path.exists(par2_file):
            if no_update:
                logger.error(
                    f'NO-UPDATE MODE: {file} does not have par2 file at {par2_file}')
                return False
            else:
                logger.debug(
                    f'par2 file {par2_file} does not exists, will create it')
        else:
            if no_update:
                logger.error(
                    f'NO-UPDATE MODE: {file} has a 0-size par2 file at {par2_file}')
                return False
            logger.info(f'par2 file {par2_file} has size 0, recreating it')
    create_par2(file, par2_file, par2_recovery_file_arg)
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""Maintain/verify par2 files for a set of files based on mtime. Input is read from
stdin and should have a file name on each time.

Examples: list all files and filter out certain directories:
find -name ".snapshots" -prune -o ! -name "*.par2" -type f | ~/yan-common/os/fileset_par2.py --systemd_log --use_hidden_dir

You can store par2 files in a .par2 directory along with the original data so
they could be moved around together.""", formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('--systemd_log', action='store_true',
                        help='also log every event to systemd')
    parser.add_argument('-c', metavar='RECOVERY_BLOCK_COUNT', type=int,
                        help='the recovery block count; if not set, -r1 will be passed to par2create, which creates a '
                             'recovery file the size of which equals 1%% of the size of original file (files '
                             'smaller than 8 MB use 4096-byte blocks and 1%% but at least one recovery block); it is '
                             'recommended to use -c and -s together to find tune the amount of recovery blocks and '
                             'size you want to create')
    parser.add_argument('-s', metavar='BLOCK_SIZE', type=int,
                        help='the block size')
    parser.add_argument('--dry_run', action='store_true')
    parser.add_argument('--use_hidden_dir', action='store_true',
                        help='store par2 files in a hidden .par2 directory next to file')
    parser.add_argument('--no_update', action='store_true',
                        help='check only, do not update par2 files')
    parser.add_argument('--par2_dir', metavar='DIR', type=str,
                        help='the directory for storing par2 files')
    parser.add_argument('--workers', type=int, default=4,
                        help='number of worker threads to use for parallel processing (default: 4)')
    args = parser.parse_args()

    logger = logging.getLogger(__name__)
    if args.systemd_log:
        from systemd.journal import JournalHandler
        journald_handler = JournalHandler()
        # set a formatter to include the level name
        journald_handler.setFormatter(logging.Formatter(
            '[%(levelname)s] %(message)s'
        ))
        journald_handler.setLevel(logging.DEBUG)
        # add the journald handler to the current logger
        logger.addHandler(journald_handler)
    stream_handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    stream_handler.setFormatter(formatter)
    stream_handler.setLevel(logging.DEBUG if args.verbose else logging.WARNING)
    logger.addHandler(stream_handler)
    # logger always emit the lowest logging level. This basically deligates
    # filtering to each handler. We usually want journald_handler to log
    # everything.
    logger.setLevel(logging.DEBUG)

    if args.c:
        par2_recovery_file_arg = f'-c{args.c}'
    else:
        par2_recovery_file_arg = DEFAULT_RECOVERY_ARG
    if args.s:
        par2_recovery_file_arg += f' -s{args.s}'

    logger.debug(f'Using par2_dir {args.par2_dir}')
    if args.dry_run:
        DRY_RUN = True
    BASE_DIR = os.getcwd()
    logger.debug(f'Base dir {BASE_DIR}')

    corrupted_files = 0

    def process_file(file):
        """
        Process a single file for par2 verification or creation.

        Returns:
            0 if the file was processed successfully or skipped.
            1 if the file is corrupted or an error occurred.
        """
        try:
            if os.path.isabs(file) and args.par2_dir is not None:
                logger.error(
                    'Input file path must be relative path when par2_dir is set. Exiting')
                return 1
            if os.path.isdir(file):
                logger.debug(f'Ignoring directory {file}')
                return 0
            data_file = os.path.realpath(os.path.join(BASE_DIR, file))
            if args.par2_dir is not None:
                par2_file = os.path.realpath(os.path.join(
                    os.path.realpath(args.par2_dir), file + '.par2'))
            else:
                assert args.use_hidden_dir, "You must either set par2_dir or use_hidden_dir."
                # using hidden dir
                data_file_path, data_file_name = os.path.split(data_file)
                if data_file_name[-5:] == '.par2' and data_file_path[-6:] == '/.par2':
                    # This file is actually a par2 file. We check if the corresponding data
                    # file exists. If not, prune this par2 file.
                    par2_file = data_file
                    # Remove the .par2 from path
                    data_file_path = os.path.split(data_file_path)[0]
                    data_file_name = data_file_name[:-5]
                    data_file = os.path.join(data_file_path, data_file_name)
                    logger.debug(
                        f'Checking if the data file {data_file} for par2 file {par2_file} exists')
                    if os.path.isfile(data_file):
                        logger.debug(f'File {data_file} exists')
                    else:
                        if args.no_update:
                            logger.error(
                                f'NO-UPDATE MODE: data file missing {data_file}')
                            return 1
                        else:
                            if DRY_RUN:
                                print(f'dry run: cannot find the data file {data_file} for par2 file {par2_file}, '
                                      'will remove the dangling par2 file')
                            else:
                                logger.info(f'Cannot find the data file {data_file} for par2 file {par2_file}, '
                                            'removing the dangling par2 file')
                                os.remove(par2_file)
                                par2_file_dir = os.path.split(par2_file)[0]
                                files = os.listdir(par2_file_dir)
                                if len(files) == 0:
                                    logger.info(
                                        f'Removing the empty dir {par2_file_dir}')
                                    try:
                                        os.rmdir(par2_file_dir)
                                    except FileNotFoundError:
                                        # This directory might have already been
                                        # removed by another thread.
                                        pass
                    return 0
                par2_file = os.path.join(os.path.join(
                    data_file_path, '.par2'), data_file_name) + '.par2'
            logger.info(f'Checking {data_file} with par2 file {par2_file}')
            if not update_par2(data_file, par2_file, args.no_update, par2_recovery_file_arg):
                return 1
            return 0
        except Exception as e:
            logger.error(f"Error processing file {file}: {e}")
            return 1

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        results = list(executor.map(process_file, map(str.rstrip, sys.stdin)))

    corrupted_files = sum(results)
    sys.exit(corrupted_files)
