find -name .git -prune -o -type f -print0 | xargs -0 -n 1 sed -i -e 's/# Copyright (c) \(.*\)-.*/# Copyright (c) \1-2021, Yan Li <yanli@tuneup.ai>,/'
