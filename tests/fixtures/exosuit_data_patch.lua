-- Four setting-byte edits in pre-existing private read/write memory only.
-- This changes shared classification, not just selection. Experimental.
return function(api,game,baseline,code_guard)
    local buffer_rva,table_rva,size=0x348e8f8,0x37cb600,80280
    local targets={[27]=true,[10]=true,[91]=true,[88]=true}
    local function u32(s,o)
        assert(s and o>=0 and o+4<=#s,'field_bounds')
        local a,b,c,d=s:byte(o+1,o+4);return a+b*256+c*65536+d*16777216
    end
    local function changed(s,o,value)return s:sub(1,o)..string.char(value)..s:sub(o+2)end
    assert(#code_guard==224 and api.read(game+0x146e385,224)==code_guard,'selection_code_not_original')
    local pointer_bytes=assert(api.read(game+buffer_rva,8),'settings_pointer_unreadable')
    local buffer=assert(api.pointer(pointer_bytes),'settings_pointer_invalid')
    assert(api.writable_data(buffer,size),'settings_not_private_readwrite')
    local source=assert(api.read(buffer,size),'settings_unreadable')
    local table_bytes=assert(api.read(game+table_rva,150*8),'table_unreadable')
    assert(u32(source,0)==11,'group_count')
    local pos,total,seen,changes=4,0,{},{}
    for group=1,11 do
        assert(u32(source,pos)==0x444c444c and u32(source,pos+4)==1 and u32(source,pos+8)==0x30eb6399
            and u32(source,pos+16)==1 and u32(source,pos+20)==0,'group_header')
        local root=pos+24;local finish=root+u32(source,pos+12)
        assert(finish>=root+16 and finish<=size,'group_bounds')
        local count=u32(source,root+8)
        assert(count>0 and count<=149,'record_count')
        local items=assert(api.pointer(source,root),'items_pointer')
        local start=api.distance(items,buffer)
        assert(start>=root+16 and start+count*400<=finish,'record_bounds')
        for i=0,count-1 do
            local record=start+i*400;local id=u32(source,record)
            assert(id>=1 and id<=149 and not seen[id],'record_identity')
            seen[id]=true;total=total+1
            assert(api.pointer(table_bytes,id*8)==buffer+record,'table_identity')
            assert(u32(source,record+0x104)==baseline[id],'flags_not_baseline')
            if targets[id] then
                local offset=record+0x106;local before=source:byte(offset+1)
                assert(bit.band(before,0x10)~=0,'target_not_exosuit')
                changes[#changes+1]={id=id,record=record,offset=offset,before=before,after=bit.band(before,0xef)}
            end
        end
        pos=finish
    end
    assert(pos==size and total==149 and #changes==4,'incomplete_settings')
    assert(api.read(game+buffer_rva,8)==pointer_bytes and api.read(game+table_rva,150*8)==table_bytes
        and api.read(buffer,size)==source,'settings_changed_before_write')
    local expected,attempted=source,{}
    local ok,err=pcall(function()
        for _,c in ipairs(changes) do
            assert(api.read(game+buffer_rva,8)==pointer_bytes,'settings_owner_changed')
            assert(api.pointer(api.read(game+table_rva+c.id*8,8))==buffer+c.record,'target_owner_changed')
            assert(api.read(buffer+c.record,400)==source:sub(c.record+1,c.record+400),'target_changed')
            attempted[#attempted+1]=c
            assert(api.write(buffer+c.offset,string.char(c.after)),'setting_write_failed')
            expected=changed(expected,c.offset,c.after)
        end
        assert(api.read(game+buffer_rva,8)==pointer_bytes and api.read(game+table_rva,150*8)==table_bytes
            and api.read(buffer,size)==expected,'settings_verification_failed')
        assert(api.read(game+0x146e385,224)==code_guard,'selection_code_changed')
    end)
    if ok then return 'applied: four exosuit classification bits cleared; original selection code verified; gameplay unverified' end
    local restored=true
    for i=#attempted,1,-1 do
        local c=attempted[i]
        if api.read(game+buffer_rva,8)==pointer_bytes and api.pointer(api.read(game+table_rva+c.id*8,8))==buffer+c.record then
            local before=source:sub(c.record+1,c.record+400)
            local after=changed(before,0x106,c.after)
            local current=api.read(buffer+c.record,400)
            if current==after then
                restored=api.write(buffer+c.offset,string.char(c.before)) and restored
                restored=(api.read(buffer+c.record,400)==before) and restored
            elseif current~=before then restored=false end
        else restored=false end
    end
    error(tostring(err)..'; owned_record_recovery='..tostring(restored))
end
