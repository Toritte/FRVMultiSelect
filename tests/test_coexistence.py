import unittest
from pathlib import Path
from test_frv import Fixture, R, C, GUARD, GAME, TARGETS

class CoexistenceTests(unittest.TestCase):
    def test_both_initialization_orders(self):
        for order in ['exo_first','frv_first']:
            with self.subTest(order=order):
                f=Fixture(); lua=f.lua
                # Both guards overlap the same original code region.
                exoguard=GUARD[0x11cce65-0x11ccd5d:0x11ccf45-0x11ccd5d]
                origread=f.read
                def read(a,n):
                    if a==GAME+0x11cce65 and n==224:return exoguard
                    return origread(a,n)
                alltargets=set(TARGETS)|{26,10,89,86}
                writes=[]
                import test_frv
                def write(a,s):
                    offset=int(a)-test_frv.BASE
                    assert len(s)==1 and offset in [f.offsets[id]+0x106 for id in alltargets]
                    f.memory[offset]=s[0];writes.append(offset);return True
                api=lua.table_from({b'read':read,b'pointer':f.pointer,b'distance':lambda a,b:a-b,b'writable_data':lambda a,n:True,b'write':write,
                    b'module':lambda n=None:GAME,b'module_hash':lambda n: C['game_sha256'].encode()})
                # Module adapter distinct identities for executable and game hash checks.
                api[b'module']=lambda n=None: GAME if n else GAME+1
                api[b'module_hash']=lambda n:(C['game_sha256'] if n==GAME else C['exe_sha256']).encode()
                lua.execute(b"update=function()return 7 end;CowboyBingusModLoader={open_log=function()return {write=function()return true end,flush=function()return true end,close=function()end} end}")
                create=lambda:api
                exoinstall=lua.execute((R/'tests/fixtures/exosuit_lifecycle.lua').read_bytes())
                exoapply=lua.execute((R/'tests/fixtures/exosuit_data_patch.lua').read_bytes())
                frvinstall=lua.execute((R/'src/lifecycle.lua').read_bytes())
                baseline=lua.table_from(dict(C['baseline_flags']))
                def exo():exoinstall(create,exoapply,baseline,exoguard)
                def frv():frvinstall(create,f.apply,baseline,GUARD)
                (exo if order=='exo_first' else frv)();(frv if order=='exo_first' else exo)()
                for i in range(3):self.assertEqual(lua.globals().update(1),7)
                self.assertEqual(lua.globals().ExosuitMultiSelect[b'status'],b'applied')
                self.assertEqual(lua.globals().FRVMultiSelect[b'status'],b'applied')
                self.assertEqual(len(writes),7)
                expected=bytearray(f.original)
                for id in alltargets:expected[f.offsets[id]+0x106]&=255^(32 if id in TARGETS else 16)
                self.assertEqual(f.memory,expected)
                self.assertEqual(baseline[26],dict(C['baseline_flags'])[26])

    def test_unfinished_exosuit_times_out_without_patch(self):
        f=Fixture();lua=f.lua
        lua.execute(b"update=function()end;ExosuitMultiSelect={revision='0.2-data-experimental',status='pending'};CowboyBingusModLoader={open_log=function()return {write=function()return true end,flush=function()return true end,close=function()end} end}")
        install=lua.execute((R/'src/lifecycle.lua').read_bytes())
        def forbidden(*args):raise AssertionError('must not initialize adapter or patch')
        install(forbidden,forbidden,lua.table_from(dict(C['baseline_flags'])),GUARD)
        for _ in range(125):lua.globals().update(1)
        self.assertEqual(lua.globals().FRVMultiSelect[b'status'],b'failed')
        self.assertFalse(f.writes)
