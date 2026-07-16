#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
COLOR="#000000"   # CW&T convention: solid circle, diameter = 50% of width
gen() { # size outfile
  /usr/bin/python3 - "$1" "$2" "$COLOR" <<'PY'
import sys, struct, zlib
s=int(sys.argv[1]); out=sys.argv[2]
col=sys.argv[3].lstrip('#'); R,G,B=int(col[0:2],16),int(col[2:4],16),int(col[4:6],16)
c=s/2.0; r=s/4.0  # diameter = 50% of width
raw=bytearray()
for y in range(s):
    raw.append(0)
    for x in range(s):
        inside=(x-c+0.5)**2+(y-c+0.5)**2 <= r*r
        raw += bytes((R,G,B,255)) if inside else bytes((0,0,0,0))
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'
png+=chunk(b'IHDR',struct.pack('>IIBBBBB',s,s,8,6,0,0,0))
png+=chunk(b'IDAT',zlib.compress(bytes(raw),9))
png+=chunk(b'IEND',b'')
open(out,'wb').write(png)
PY
}
gen 16  favicon-16x16.png
gen 32  favicon-32x32.png
gen 180 apple-touch-icon.png
# favicon.ico = the 32px PNG wrapped in an ICO container
/usr/bin/python3 - <<'PY'
import struct
png=open('favicon-32x32.png','rb').read()
hdr=struct.pack('<HHH',0,1,1)
entry=struct.pack('<BBBBHHII',32,32,0,0,1,32,len(png),22)
open('favicon.ico','wb').write(hdr+entry+png)
PY
echo "favicon assets generated"
