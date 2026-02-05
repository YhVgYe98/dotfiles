-- 基础路径配置
local config_dir = vim.fn.stdpath('config')
local cache_dir = vim.fn.stdpath('cache')
local data_dir = vim.fn.stdpath('data')
local fennel_version = "1.6.1"
local fennel_name = "fennel-" .. fennel_version .. ".lua"
local fennel_path = vim.fs.joinpath(data_dir, fennel_name)
local fennel_temp_path = vim.fs.joinpath(cache_dir, fennel_name)

-- 下载 fennel.lua
if vim.fn.filereadable(fennel_path) == 0 then
    vim.fn.mkdir(cache_dir, "p")
    vim.fn.mkdir(data_dir, "p")

    local url = "https://fennel-lang.org/downloads/fennel-" .. fennel_version .. ".lua"
    print("Downloading Fennel compiler...")
    local output = vim.fn.system({ "curl", "-L", url, "-o", fennel_temp_path })
    if vim.v.shell_error ~= 0 then
        vim.notify("Fennel download failed:\n" .. output, vim.log.levels.ERROR)
        return nil
    end

    local success, err = os.rename(fennel_temp_path, fennel_path)
    if not success then
        vim.notify("Download success but failed to move file: " .. err, vim.log.levels.ERROR)
        return nil
    end
    print("Fennel compiler download success!")
end

local fennel = dofile(fennel_path)

-- 配置 Fennel 搜索路径
local fnl_cfg_path = vim.fs.joinpath(config_dir, "fnl")
fennel['path'] = vim.fs.joinpath(fnl_cfg_path, "?.fnl") .. ";" .. vim.fs.joinpath(fnl_cfg_path, "?", "init.fnl")
fennel['macro-path'] = fennel.path

-- 注册 Fennel 加载器
table.insert(package.loaders or package.searchers, 1, fennel.makeSearcher({
    correlate = true, -- 出错时将 Lua 行号映射回 Fennel 行号
    useMetadata = false,
}))

-- 加载入口文件
require("init")
