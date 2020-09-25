#!/usr/bin/env python
# Move files to date-named directories in dst_dir
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

__author__ = 'Yan Li'
__license__ = 'All rights reserved.'
__credits__ = ['Yan Li']

import os.path
import shutil
import sys
import time

if len(sys.argv) < 3:
    print('Move files to date-named directories in dst_dir')
    print('Usage: {0} [-d] dst_dir files'.format(sys.argv[0]))
    print(' -d     dry run')
    exit(2)

dry_run = False
if sys.argv[1] == '-d':
    dry_run = True
    sys.argv = sys.argv[2:]
else:
    sys.argv = sys.argv[1:]
dst_dir = sys.argv[0]
sys.argv = sys.argv[1:]

for f in sys.argv:
    to_dir = dst_dir + '/' + time.strftime('%Y-%m-%d', time.localtime(os.path.getmtime(f)))
    if dry_run:
        print('Will move {0} to dir {1}'.format(f, to_dir))
    else:
        if not os.path.isdir(to_dir):
            os.makedirs(to_dir)
        print('Moving {0} to dir {1}'.format(f, to_dir))
        shutil.move(f, to_dir)

