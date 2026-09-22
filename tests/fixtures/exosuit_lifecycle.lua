return function(create_api,apply,baseline,guard)
    if rawget(_G,'ExosuitMultiSelect') then return end
    local state={revision='0.3-data',status='pending'}
    _G.ExosuitMultiSelect=state
    local previous=update
    if type(previous)~='function' then state.status='disabled_no_update';return end
    local callback
    local function initialize()
        if state.status~='pending' then return end
        state.status='checking'
        local file
        local ok,result=pcall(function()
            local loader=assert(rawget(_G,'CowboyBingusModLoader'),'loader_missing')
            file=assert(loader.open_log('ExosuitMultiSelectData.log'),'log_open_failed')
            assert(file:write('ExosuitMultiSelect v0.3\n'));assert(file:flush())
            local api=create_api()
            local exe=assert(api.module(nil),'exe_missing')
            local game=assert(api.module('game.dll'),'game_missing')
            assert(api.module_hash(exe)=='D8E23968D1412B07E06785321727D63EDF74E711214D6F6ADEB3BFCA95CA6827','unsupported_exe')
            assert(api.module_hash(game)=='73374BD4E38386BEB9A23BEF480082B67D457EBC77485FBEC5F488B4E95E201F','unsupported_game')
            return apply(api,game,baseline,guard)
        end)
        state.status=ok and 'applied' or 'failed';state.detail=tostring(result)
        if file then
            pcall(function()file:write(state.status..': '..state.detail..'\n');file:flush()end)
            pcall(function()file:close()end)
        end
        print('[ExosuitMultiSelectData] '..state.status..': '..state.detail)
        if update==callback then update=previous end
    end
    local function after(...)initialize();return ... end
    callback=function(dt,...)return after(previous(dt,...))end
    update=callback
end
