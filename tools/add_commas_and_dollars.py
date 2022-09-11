import sys,re,os, glob
import argparse
import collections

# tool to convert mame hex dump (prefixed by dc.b manually) to replace
# space separated hex values (no $) by comma separated $ values
#
#   dc.b  00 0a 0b => dc.b  $00,$0a,$0b

parser = argparse.ArgumentParser()
parser.add_argument("asmfile", help="assembly file")

args = parser.parse_args()

asmfile = args.asmfile

dc_re = re.compile(r"\s+dc\.([bwl])\s+([0-9a-f][0-9a-f].*)",flags=re.I)

with open(asmfile) as f:
    lines = f.readlines()

for line in lines:
    m = dc_re.match(line)
    if m:
        size,rest = m.groups()
        line = "\tdc.{}\t${}\n".format(size,",$".join(rest.split()))
    print(line,end="")

