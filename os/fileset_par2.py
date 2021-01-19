#!/usr/bin/env python3
# Maintain/verify par2 files for a set of files based on mtime
#
# Copyright (c) 2016-2020, Yan Li <yanli@tuneup.ai>,
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
import logging
import os
import sys

DRY_RUN = False
BASE_DIR = ''
logger = None


def escape_for_bash(name: str) -> str:
    result = name
    # '\\' must be the first one so it wouldn't be escaped twice
    for special_char in ('\\', '"', '`', '$', '*', '?'):
        result = result.replace(special_char, '\\' + special_char)
    return result


def create_par2(file: str, par2_path: str):
    par2_path = os.path.realpath(par2_path)
    assert par2_path[-5:] == '.par2', 'par2_path must end with .par2 ext name'
    par2_path_no_ext = par2_path[0:-5]
    par2_parent_dir = os.path.split(os.path.realpath(par2_path))[0]
    file_parent_dir, file_name = os.path.split(os.path.realpath(file))
    if len(file_name) == 1:
        logger.info(f'Ignoring file {file} because par2 cannot process file that has name of length 1')
        return
    if '*' in file_name or '?' in file_name:
        logger.info(f'Ignoring file {file} because par2 cannot process file that has wildcards in name')
        return
    if os.path.getsize(file) == 0:
        logger.info(f'Ignoring file {file} because par2 cannot process file that has size 0')
        return

    cmd = f'cd "{escape_for_bash(par2_parent_dir)}" && '\
          f'chronic par2create "-B{escape_for_bash(file_parent_dir)}" -r1 -n1 "{escape_for_bash(par2_path)}" '\
          f'"{escape_for_bash(file)}" && mv "{escape_for_bash(par2_path_no_ext)}".vol*.par2 '\
          f'"{escape_for_bash(par2_path_no_ext)}.par2"'
    if not DRY_RUN:
        if not os.path.exists(par2_parent_dir):
            os.makedirs(par2_parent_dir)
        logger.debug(f'Creating par2 file: {cmd}')
        if os.system(cmd) != 0:
            logger.error(f'Failed to create par2 file for {file} in {par2_path}')
    else:
        if not os.path.exists(par2_parent_dir):
            print(f'Will create dir {par2_parent_dir}')
        print(cmd)


def verify_par2(file: str, par2_path: str) -> bool:
    par2_parent_dir = os.path.split(os.path.realpath(par2_path))[0]
    file_parent_dir = os.path.split(os.path.realpath(file))[0]
    cmd = f'cd "{escape_for_bash(par2_parent_dir)}" && '\
          f'chronic par2verify "-B{escape_for_bash(file_parent_dir)}" "{escape_for_bash(par2_path)}" '\
          f'"{escape_for_bash(file)}"'
    if DRY_RUN:
        print(f'dry run: {cmd}')
        return True
    else:
        logger.info(f'Verifying {file} using par2 file {par2_file}')
        logger.debug(f'Running {cmd}')
        rc = os.system(cmd)
        if rc == 0:
            logger.info(f'Verified file data for {file}')
            return True
        else:
            logger.error(f'CORRUPTED FILE DETECTED: {file}')
            return False


def update_par2(file: str, par2_file: str, no_update: bool) -> bool:
    """Update par2

    :returns false if a corrupted file is detected
    """
    file_mtime = os.path.getmtime(file)
    if os.path.exists(par2_file) and os.path.getsize(par2_file) > 0:
        logger.info(f'par2 file {par2_file} exists')
        par2_mtime = os.path.getmtime(par2_file)
        if file_mtime <= par2_mtime:
            return verify_par2(file, par2_file)
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
                logger.error(f'NO-UPDATE MODE: {file} does not have par2 file at {par2_file}')
                return False
            else:
                logger.debug(f'par2 file {par2_file} does not exists, will create it')
        else:
            if no_update:
                logger.error(f'NO-UPDATE MODE: {file} has a 0-size par2 file at {par2_file}')
                return False
            logger.info(f'par2 file {par2_file} has size 0, recreating it')
    create_par2(file, par2_file)
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=
"""Maintain/verify par2 files for a set of files based on mtime. Input is read from
stdin and should have a file name on each time.

Examples: list all files and filter out certain directories:
find -name ".snapshots" -prune -o ! -name "*.par2" -type f | ~/yan-common/os/fileset_par2.py --systemd_log --use_hidden_dir

You can store par2 files in a .par2 directory along with the original data so
they could be moved around together.""", formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('--systemd_log', action='store_true',
                        help='also log every event to systemd')
    parser.add_argument('--dry_run', action='store_true')
    parser.add_argument('--use_hidden_dir', action='store_true',
                        help='store par2 files in a hidden .par2 directory next to file')
    parser.add_argument('--no_update', action='store_true',
                        help='check only, do not update par2 files')
    parser.add_argument('--par2_dir', metavar='DIR', type=str,
                        help='the directory for storing par2 files')
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

    logger.debug(f'Using par2_dir {args.par2_dir}')
    if args.dry_run:
        DRY_RUN = True
    BASE_DIR = os.getcwd()
    logger.debug(f'Base dir {BASE_DIR}')

    corrupted_files = 0
    for file in map(str.rstrip, sys.stdin):
        if os.path.isabs(file) and args.par2_dir is not None:
            logger.error('Input file path must be relative path when par2_dir is set. Exiting')
            exit(1)
        if os.path.isdir(file):
            logger.debug(f'Ignoring directory {file}')
            continue
        data_file = os.path.realpath(os.path.join(BASE_DIR, file))
        if args.par2_dir is not None:
            par2_file = os.path.realpath(os.path.join(os.path.realpath(args.par2_dir), file + '.par2'))
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
                logger.debug(f'Checking if the data file {data_file} for par2 file {par2_file} exists')
                if os.path.isfile(data_file):
                    logger.debug(f'File {data_file} exists')
                else:
                    if args.no_update:
                        logger.error(f'NO-UPDATE MODE: data file missing {data_file}')
                        corrupted_files += 1
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
                                logger.info(f'Removing the empty dir {par2_file_dir}')
                                os.rmdir(par2_file_dir)
                continue
            par2_file = os.path.join(os.path.join(data_file_path, '.par2'), data_file_name) + '.par2'
        logger.info(f'Checking {data_file} with par2 file {par2_file}')
        if not update_par2(data_file, par2_file, args.no_update):
            corrupted_files += 1
    sys.exit(corrupted_files)
