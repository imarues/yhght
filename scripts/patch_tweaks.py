#!/usr/bin/env python3
import argparse, struct, pathlib, shutil, hashlib, sys

MH_MAGIC_64 = 0xfeedfacf
LC_SEGMENT_64 = 0x19
S_REGULAR = 0x0
S_INIT_FUNC_OFFSETS = 0x16
S_MOD_INIT_FUNC_POINTERS = 0x9


def cstr16(b):
    return b.split(b'\0',1)[0].decode('ascii','replace')


def patch_sections(path):
    data = bytearray(path.read_bytes())
    if len(data) < 32 or struct.unpack_from('<I', data, 0)[0] != MH_MAGIC_64:
        raise RuntimeError(f'{path.name}: expected thin 64-bit little-endian Mach-O')
    ncmds = struct.unpack_from('<I', data, 16)[0]
    off = 32
    found=[]
    for _ in range(ncmds):
        cmd,cmdsize=struct.unpack_from('<II',data,off)
        if cmdsize < 8 or off+cmdsize > len(data):
            raise RuntimeError(f'{path.name}: malformed load command')
        if cmd == LC_SEGMENT_64:
            nsects=struct.unpack_from('<I',data,off+64)[0]
            sec_off=off+72
            for i in range(nsects):
                s=sec_off+i*80
                sect=cstr16(data[s:s+16]); seg=cstr16(data[s+16:s+32])
                flags=struct.unpack_from('<I',data,s+64)[0]
                typ=flags & 0xff
                if sect in ('__init_offsets','__mod_init_func'):
                    if typ not in (S_INIT_FUNC_OFFSETS,S_MOD_INIT_FUNC_POINTERS,S_REGULAR):
                        raise RuntimeError(f'{path.name}: unexpected {seg},{sect} type 0x{typ:x}')
                    struct.pack_into('<I',data,s+64,(flags & ~0xff) | S_REGULAR)
                    size=struct.unpack_from('<Q',data,s+40)[0]
                    found.append((seg,sect,typ,size))
        off += cmdsize
    if not found:
        raise RuntimeError(f'{path.name}: no initializer section found')
    path.write_bytes(data)
    return found


def rename_lead_collisions(path):
    data=bytearray(path.read_bytes())
    replacements={
        b'LanguageSelector': b'LeadLangSelector',
        b'LocationSelector': b'LeadLocaSelector',
    }
    stats={}
    for old,new in replacements.items():
        if len(old)!=len(new): raise AssertionError('replacement length mismatch')
        count=data.count(old)
        if count == 0:
            raise RuntimeError(f'{path.name}: expected class string {old.decode()} not found')
        data=data.replace(old,new)
        stats[old.decode()] = count
    path.write_bytes(data)
    return stats


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--input-dir',required=True)
    ap.add_argument('--output-dir',required=True)
    args=ap.parse_args()
    src=pathlib.Path(args.input_dir); out=pathlib.Path(args.output_dir)
    out.mkdir(parents=True,exist_ok=True)
    names=['Mx.dylib','iQTele.dylib','Lead.dylib']
    for n in names:
        s=src/n; d=out/n
        if not s.exists(): raise SystemExit(f'Missing {s}')
        shutil.copy2(s,d)
        if n=='Lead.dylib':
            print('Lead collision rename:', rename_lead_collisions(d))
        sections=patch_sections(d)
        print(n,'patched sections:',sections,'sha256:',sha(d))

if __name__=='__main__': main()
