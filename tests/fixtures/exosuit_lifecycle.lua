return function(create_api,apply,baseline,guard)
    if rawget(_G,'ExosuitMultiSelect') then return end
    local state={revision='0.2-data-experimental',status='pending'}
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
            assert(file:write('ExosuitMultiSelect v0.2 DATA EXPERIMENTAL\n'));assert(file:flush())
            local api=create_api()
            local exe=assert(api.module(nil),'exe_missing')
            local game=assert(api.module('game.dll'),'game_missing')
            assert(api.module_hash(exe)=='A09FF52663E73B94FB0CAC0DCB5BA84FFD10ECF44F74A8921AC66AF923988CC3','unsupported_exe')
            assert(api.module_hash(game)=='CC75948D90FDFDE259DCB519E9933DB7FFA3CCB281CE4FB89E6B1B011557470C','unsupported_game')
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
