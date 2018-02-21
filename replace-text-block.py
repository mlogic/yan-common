#!/usr/bin/python
# Based on code from https://gist.github.com/2661995

import os
import sys
import argparse

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--dryrun', '-n', action='store_true')
    p.add_argument('search')
    p.add_argument('replace')
    p.add_argument('files', nargs='*')
    return p.parse_args()

def main():
    opts = parse_args()

    search = open(opts.search).read()
    replace = open(opts.replace).read()

    for file in opts.files:
        with open(file) as f:
            data = f.read()

        if search in data:
            print file
            if opts.dryrun:
                continue

            while search in data:
                i = data.find(search)
                fixed = data[:i] + \
                        replace + \
                        data[i + len(search):]
                data = fixed

            with open(file, 'w') as f:
                f.write(fixed)

if __name__ == '__main__':
    main()

