return function(create_api,apply,baseline,guard)
    if rawget(_G,'FRVMultiSelect') then return end
    local state={revision='0.2-data',status='pending'}
    _G.FRVMultiSelect=state
    local previous=update
    if type(previous)~='function' then state.status='disabled_no_update';return end
    local callback
    local function initialize()
        if state.status~='pending' then return end
        local exosuit=rawget(_G,'ExosuitMultiSelect')
        local combined=rawget(_G,'VehicleMultiSelect')
        if not combined and type(exosuit)=='table' and (exosuit.status=='pending' or exosuit.status=='checking') then
            state.wait_frames=(state.wait_frames or 0)+1
            if state.wait_frames<120 then return end
        end
        state.status='checking'
        local file
        local ok,result=pcall(function()
            local loader=assert(rawget(_G,'CowboyBingusModLoader'),'loader_missing')
            file=assert(loader.open_log('FRVMultiSelectData.log'),'log_open_failed')
            assert(file:write('FRVMultiSelect v0.2\n'));assert(file:flush())
            assert(not combined,'conflict_disable_VehicleMultiSelect_and_restart')
            local expected=baseline
            if exosuit then
                assert(type(exosuit)=='table' and exosuit.revision=='0.3-data' and exosuit.status=='applied','unsupported_or_unfinished_ExosuitMultiSelect')
                expected={}
                for id,flags in pairs(baseline) do expected[id]=flags end
                for _,id in ipairs({27,10,91,88}) do expected[id]=bit.band(expected[id],bit.bnot(0x100000)) end
            end
            local api=create_api()
            local exe=assert(api.module(nil),'exe_missing')
            local game=assert(api.module('game.dll'),'game_missing')
            assert(api.module_hash(exe)=='D8E23968D1412B07E06785321727D63EDF74E711214D6F6ADEB3BFCA95CA6827','unsupported_exe')
            assert(api.module_hash(game)=='73374BD4E38386BEB9A23BEF480082B67D457EBC77485FBEC5F488B4E95E201F','unsupported_game')
            return apply(api,game,expected,guard)
        end)
        state.status=ok and 'applied' or 'failed';state.detail=tostring(result)
        if file then
            pcall(function()file:write(state.status..': '..state.detail..'\n');file:flush()end)
            pcall(function()file:close()end)
        end
        print('[FRVMultiSelectData] '..state.status..': '..state.detail)
        if update==callback then update=previous end
    end
    local function after(...)initialize();return ... end
    callback=function(dt,...)return after(previous(dt,...))end
    update=callback
end
