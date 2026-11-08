-- Simple Twemoji fetcher: downloads a curated set of PNGs per twemoji_manifest.json
-- Requirements: curl
-- Usage: lua fetch_twemoji.lua

local manifest_path = "twemoji_manifest.json"
local json = nil

-- Very small JSON parser for our limited manifest structure using dkjson if present
local ok, dkjson = pcall(require, 'dkjson')
if ok and dkjson then json = dkjson end

local function readfile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local d = f:read("*a"); f:close(); return d
end

local function parse_json(s)
  if json then
    local obj, pos, err = json.decode(s)
    if not obj then error(err) end
    return obj
  end
  -- Minimal fallback: expect flat keys and values; not a general JSON parser
  error("Please install dkjson (Lua) or run this with a Lua that has json.decode available.")
end

local function run(cmd)
  local ok = os.execute(cmd)
  return ok == true or ok == 0
end

local function ensure_dir()
  -- already in emoji/ directory
  return true
end

local function main()
  ensure_dir()
  local data = readfile(manifest_path)
  if not data then
    io.stderr:write("Missing manifest twemoji_manifest.json\n")
    os.exit(1)
  end
  local manifest = parse_json(data)
  local base = string.format("https://cdn.jsdelivr.net/gh/twitter/twemoji@v%%d/assets/%s/", manifest.format)
  base = string.format(base, manifest.version)

  for code, _ in pairs(manifest.emoji) do
    local url = base .. code .. ".png"
    local out = code .. ".png"
    if not readfile(out) then
      local cmd = string.format("curl -fsSL '%s' -o '%s'", url, out)
      print("Downloading", code)
      if not run(cmd) then
        io.stderr:write("Failed to download " .. code .. " from " .. url .. "\n")
      end
    end
  end

  print("Done. You can rename/link to the filenames your filter expects, e.g., 1f604.png for :smile: etc.")
end

main()
