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


def create_par2(file: str, par2_path: str):
    par2_path = os.path.realpath(par2_path)
    assert par2_path[-5:] == '.par2', 'par2_path must end with .par2 ext name'
    par2_path_no_ext = par2_path[0:-5]
    par2_parent_dir = os.path.split(os.path.realpath(par2_path))[0]
    file_parent_dir = os.path.split(os.path.realpath(file))[0]
    cmd = f'cd "{par2_parent_dir}" && chronic par2create "-B{file_parent_dir}" -r1 -n1 "{par2_path}" "{file}" && mv "{par2_path_no_ext}".vol*.par2 "{par2_path_no_ext}.par2"'
    if not DRY_RUN:
        if not os.path.exists(par2_parent_dir):
            os.makedirs(par2_parent_dir)
        logging.debug(f'Running {cmd}')
        os.system(cmd)
    else:
        if not os.path.exists(par2_parent_dir):
            print(f'Will create dir {par2_parent_dir}')
        print(cmd)


def verify_par2(file: str, par2_path: str) -> bool:
    par2_parent_dir = os.path.split(os.path.realpath(par2_path))[0]
    file_parent_dir = os.path.split(os.path.realpath(file))[0]
    cmd = f'cd "{par2_parent_dir}" && chronic par2verify "-B{file_parent_dir}" "{par2_path}" "{file}"'
    if not DRY_RUN:
        logging.debug(f'Running {cmd}')
        return os.system(cmd) == 0
    else:
        print(cmd)
        return True


def update_par2(file: str, par2_file: str):
    file_mtime = os.path.getmtime(file)
    if os.path.exists(par2_file):
        logging.info(f'par2 file {par2_file} exists')
        par2_mtime = os.path.getmtime(par2_file)
        if file_mtime <= par2_mtime:
            if not DRY_RUN:
                print(f'Verifying {par2_file}: ', end='')
            if verify_par2(file, par2_file):
                print('OK')
            else:
                print('FAILED, FILE IS CORRUPTED')
            return
        else:
            if not DRY_RUN:
                print(f'Updating {par2_file}')
    else:
        logging.info(f'par2 file {par2_file} does not exists')
        if not DRY_RUN:
            print(f'Creating {par2_file}')
    create_par2(file, par2_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=
"""Maintain/verify par2 files for a set of files based on mtime. Input is read from
stdin and should have a file name on each time.

Examples: list all files and filter out certain directories:
find . -type f -not -path "./.par2/*" | ~/yan-common/os/fileset_par2.py --par2_dir .par2

You can store par2 files in a .par2 directory along with the original data so
they could be moved around together.""", formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('--dry_run', action='store_true')
    parser.add_argument('--use_hidden_dir', action='store_true',
                        help='store par2 files in a hidden .par2 directory next to file')
    parser.add_argument('--par2_dir', metavar='DIR', type=str,
                        help='the directory for storing par2 files')
    args = parser.parse_args()
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    logging.debug(f'Using par2_dir {args.par2_dir}')
    if args.dry_run:
        DRY_RUN = True
    BASE_DIR = os.getcwd()
    logging.debug(f'Base dir {BASE_DIR}')

    for file in map(str.rstrip, sys.stdin):
        if os.path.isabs(file) and args.par2_dir is not None:
            logging.error('Input file path must be relative path when par2_dir is set. Exiting')
            exit(1)
        data_file = os.path.realpath(os.path.join(BASE_DIR, file))
        if args.par2_dir is not None:
            par2_file = os.path.realpath(os.path.join(os.path.realpath(args.par2_dir), file + '.par2'))
        else:
            data_file_path, data_file_name = os.path.split(data_file)
            if data_file_name[-5:] == '.par2' and data_file_path[-6:] == '/.par2':
                # This file is actually a par2 file. We check if the corresponding data
                # file exists. If not, prune this par2 file.
                par2_file = data_file
                # Remove the .par2 from path
                data_file_path = os.path.split(data_file_path)[0]
                data_file_name = data_file_name[:-5]
                data_file = os.path.join(data_file_path, data_file_name)
                logging.info(f'Checking if the data file {data_file} for par2 file {par2_file} exists')
                if os.path.isfile(data_file):
                    logging.info(f'File {data_file} exists')
                else:
                    print(f'Cannot find the data file {data_file} for par2 file {par2_file}, remove the dangling par2 file')
                    if not DRY_RUN:
                        os.remove(par2_file)
                        par2_file_dir = os.path.split(par2_file)[0]
                        files = os.listdir(par2_file_dir)
                        if len(files) == 0:
                            os.rmdir(par2_file_dir)
                continue
            par2_file = os.path.join(os.path.join(data_file_path, '.par2'), data_file_name) + '.par2'
        logging.info(f'Checking {data_file} with par2 file {par2_file}')
        update_par2(data_file, par2_file)
