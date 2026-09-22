"""Build the mod using Python's standard library; no game installation needed."""
from pathlib import Path
import argparse, hashlib, json, struct, zipfile, uuid

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = '9ba626afa44a3aa3.patch_0'
RESOURCE = 'mods/toritte/frv_multiselect'  # Stable addon resource identity.

def digest(data):
    return hashlib.sha256(data).hexdigest().upper()

def resource_hash(text):
    data=text.encode('utf-8'); mask=(1<<64)-1; mix=0xc6a4a7935bd1e995
    value=len(data)*mix&mask
    end=len(data)//8*8
    for at in range(0,end,8):
        word=int.from_bytes(data[at:at+8],'little')*mix&mask
        word^=word>>47;word=word*mix&mask
        value=((value^word)*mix)&mask
    if end<len(data):value=((value^int.from_bytes(data[end:],'little'))*mix)&mask
    value^=value>>47;value=value*mix&mask;return value^(value>>47)

def archive_for(payload):
    offset=192
    final_size=(offset+len(payload)+15)&~15
    result=bytearray(final_size)
    result[:72]=struct.pack('<III20sQQ24s',0xf0000011,1,1,b'',final_size,0,b'')
    result[72:104]=struct.pack('<IIQIIII',0,0,0xa14e8dfa2cd117e2,1,0,16,16)
    result[104:184]=struct.pack('<7Q6I',resource_hash(RESOURCE),0xa14e8dfa2cd117e2,offset,0,0,0,0,len(payload),0,0,16,16,0)
    result[offset:offset+len(payload)]=payload
    return bytes(result)

def assemble(root):
    config=json.loads((root/'config/supported-build.json').read_text(encoding='utf-8'))
    expr=lambda text:'(function()\n'+text+'\nend)()'
    source='local create_api='+expr((root/'src/windows_api.lua').read_text(encoding='utf-8'))
    source+='\nlocal apply='+expr((root/'src/data_patch.lua').read_text(encoding='utf-8'))
    source+='\nlocal install='+expr((root/'src/lifecycle.lua').read_text(encoding='utf-8'))
    source+='\nlocal baseline={'+','.join(f'[{key}]={value}' for key,value in config['baseline_flags'])+'}'
    source+='\nlocal guard="'+''.join('\\%03d'%v for v in bytes.fromhex(config['selection_guard_hex']))+'"\ninstall(create_api,apply,baseline,guard)\n'
    return config,source

def make_files(root=ROOT):
    config,source=assemble(root)
    marker=('-- HD2-Addon: '+RESOURCE+'\n').encode()
    lua=marker+source.encode('utf-8')
    payload=struct.pack('<II',len(lua),2)+lua
    patch=archive_for(payload)
    manager=json.loads((root/'packaging/manifest.json').read_text(encoding='utf-8'))
    uuid.UUID(manager['Guid'])
    if manager['Guid']!=config['guid'] or manager['Options'][0]['Include']!=['Addon']:
        raise ValueError('Manager identity or deployment path differs from the configured package')
    files={'Addon/'+ARCHIVE:patch,'Addon/'+ARCHIVE+'.stream':b'','Addon/'+ARCHIVE+'.gpu_resources':b'',
        'manifest.json':(json.dumps(manager,ensure_ascii=False,indent=2)+'\n').encode(),
        'FRVMultiSelect_ReadMe.txt':(root/'INSTALL.txt').read_bytes(),
}
    provenance={'name':'FRV MultiSelect','author':'Toritte','revision':'v0.2-data','display_version':'v0.2','gameplay_verified':False,
        'steam_build':25327279,'exe_version':'1.8.45850.0',
        'game_exe_sha256':config['exe_sha256'],'game_dll_sha256':config['game_sha256'],
        'files':{name:digest(data) for name,data in sorted(files.items())},
        'files_scope':'Every ZIP member except this provenance manifest; paths are relative to ZIP root.',
        'requires':[{'name':'Bingus Shared Loader','api':1,'minimum_release':'v15'}],
        'resource_name':RESOURCE,'resource_sha256':digest(payload),'resource_sha256_scope':'Lua resource including 8-byte length/version envelope',
        'boot_replaced':False,'executable_memory_changed':False,'memory_protection_changed':False,
        'release_rights_status':'Upstream redistribution permission not yet recorded; see THIRD_PARTY.md in source repository.'}
    files['FRVMultiSelect-manifest.json']=(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n').encode()
    return files

def verify_files(files):
    provenance=json.loads(files['FRVMultiSelect-manifest.json'])
    expected=set(files)-{'FRVMultiSelect-manifest.json'}
    if set(provenance['files'])!=expected:raise ValueError('Incomplete manifest inventory')
    for name,expected_hash in provenance['files'].items():
        if digest(files[name])!=expected_hash:raise ValueError('Hash mismatch: '+name)

def build(out,root=ROOT):
    files=make_files(root);verify_files(files);out.mkdir(parents=True,exist_ok=True)
    destination=out/'FRV-MultiSelect-v0.2.zip'
    with zipfile.ZipFile(destination,'w',compression=zipfile.ZIP_DEFLATED) as z:
        for name,data in sorted(files.items()):
            info=zipfile.ZipInfo(name,(1980,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
            z.writestr(info,data)
    with zipfile.ZipFile(destination) as z:
        if z.testzip() is not None:raise ValueError('ZIP integrity error')
        verify_files({name:z.read(name) for name in z.namelist()})
    (out/'SHA256SUMS.txt').write_text(digest(destination.read_bytes())+'  '+destination.name+'\n',encoding='ascii')
    return destination

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--out',type=Path,default=ROOT/'dist')
    args=parser.parse_args();print(build(args.out))
