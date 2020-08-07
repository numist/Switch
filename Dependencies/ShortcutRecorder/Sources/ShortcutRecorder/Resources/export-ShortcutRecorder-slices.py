#!/usr/bin/env python

from __future__ import print_function

import argparse
import os
import shutil
import subprocess
import tempfile


def find_sketchtool():
    bundle = subprocess.check_output("/usr/bin/mdfind \"kMDItemCFBundleIdentifier == 'com.bohemiancoding.sketch3'\" | head -n 1", shell=True).strip()

    if bundle:
        return os.path.join(bundle, 'Contents/Resources/sketchtool/bin/sketchtool')
    else:
        return None


def iter_slices(sketchtool):
    sketch = os.path.join(os.path.dirname(__file__), 'ShortcutRecorder.sketch')
    tmpdir = tempfile.mkdtemp()

    try:
        subprocess.check_call([sketchtool, 'export', 'slices', sketch, '--output={0}'.format(tmpdir), '--formats=png', '--scales=1,2'])

        for s in os.listdir(tmpdir):
            yield os.path.join(tmpdir, s)
    finally:
        shutil.rmtree(tmpdir)


def update_xcassets(slices):
    xcassets = os.path.join(os.path.dirname(__file__), 'Images.xcassets')
    for s in slices:
        s_basename = os.path.basename(s)
        match = subprocess.check_output("/usr/bin/find \"{0}\" -name \"{1}\" -type f -print -quit | head -n 1".format(xcassets, s_basename), shell=True).strip()

        if match:
            shutil.move(s, match)
            print("Replaced {0}".format(s_basename))
        else:
            print("Ignored {0}".format(s_basename))


def main():
    parser = argparse.ArgumentParser(description="Export slices from ShortcutRecorder.sketch")
    parser.add_argument('--sketchtool', type=str, help="path to the sketchtool binary")
    args = parser.parse_args()

    sketchtool = args.sketchtool
    if not sketchtool:
        sketchtool = find_sketchtool()

    update_xcassets(iter_slices(sketchtool))


if __name__ == '__main__':
    main()
