# -*- coding: utf-8 -*-
"""Golden inventory: every committed PNG is compared, every compared PNG exists.

A missing golden already fails loudly — `matchesGoldenFile` cannot read a file
that is not there. An **orphan** fails silently: a committed image no test
compares any more is a case that was deleted or renamed without anybody
noticing, and it sits in the repository looking like coverage.

  python scripts/check_goldens.py            # run the golden suite, then check
  python scripts/check_goldens.py --no-run   # check the last run's records

`test/goldens/flutter_test_config.dart` records every golden the run asked
about. This clears those records, runs the suite, unions them and diffs
against `test/goldens/images/`.

Exit status is 1 on an orphan, a missing file, or a run that failed.
"""
from __future__ import print_function

import io
import os
import shutil
import subprocess
import sys

RECORDS = 'build/golden_keys'
IMAGES = 'test/goldens/images'
SUITE = 'test/goldens'


def norm(path):
    return os.path.normcase(os.path.normpath(os.path.abspath(path)))


def run_suite():
    if os.path.isdir(RECORDS):
        shutil.rmtree(RECORDS)
    os.makedirs(RECORDS)
    print('running %s ...' % SUITE)
    p = subprocess.Popen(['flutter', 'test', SUITE], shell=(os.name == 'nt'))
    p.wait()
    return p.returncode


def compared():
    """Every golden the last run asked about.

    The comparator records the key as the test wrote it — `images/x.png`,
    relative to the suite directory, which is what `matchesGoldenFile`
    resolves against.
    """
    seen = set()
    if not os.path.isdir(RECORDS):
        return seen
    for name in os.listdir(RECORDS):
        if not name.endswith('.txt'):
            continue
        with io.open(os.path.join(RECORDS, name), encoding='utf-8',
                     errors='replace') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                if not os.path.isabs(line):
                    line = os.path.join(SUITE, line)
                seen.add(norm(line))
    return seen


def committed():
    """Every PNG in the golden directory."""
    out = {}
    for d, _sub, names in os.walk(IMAGES):
        for n in names:
            if n.lower().endswith('.png'):
                full = os.path.join(d, n)
                out[norm(full)] = os.path.relpath(full).replace(os.sep, '/')
    return out


def main(argv):
    code = 0
    if '--no-run' not in argv:
        code = run_suite()
        if code != 0:
            print('\nthe golden suite failed; inventory not checked')
            return code

    seen = compared()
    on_disk = committed()

    if not seen:
        print('no records were written — is '
              'test/goldens/flutter_test_config.dart in place?')
        return 1

    orphans = sorted(on_disk[k] for k in set(on_disk) - seen)
    missing = sorted(seen - set(on_disk))

    print()
    print('golden inventory')
    print('  compared by the suite   %4d' % len(seen))
    print('  committed on disk       %4d' % len(on_disk))
    print('  orphans                 %4d' % len(orphans))
    print('  compared but absent     %4d' % len(missing))

    for o in orphans:
        print('  ORPHAN  %s' % o)
    for m in missing:
        print('  MISSING %s' % os.path.relpath(m).replace(os.sep, '/'))

    if orphans or missing:
        return 1
    print('  ok — every committed golden is compared, and every comparison '
          'has a file')
    return code


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
