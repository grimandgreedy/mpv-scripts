local mp = require 'mp'

-- Load config
local function load_config()
    local config_path = mp.command_native({"expand-path", "~/.config/mpv/script-opts/timestamp_logger.conf"})
    local ok, conf = pcall(dofile, config_path)
    if not ok then
        mp.msg.error("Failed to load config file: " .. config_path)
        return nil
    end
    return conf
end

local config = load_config()
if not config then
    mp.msg.error("Using default config values.")

    config = {
        csv_path = os.getenv("HOME") .. "/Documents/tmp/mpv_timestamps.csv",
        bindings = {
            ["CTRL+I"] = "important",
            ["CTRL+E"] = "example",
            ["CTRL+R"] = "revisit",
            ["CTRL+U"] = "unclear",
            ["CTRL+W"] = "warning",
        }
    }
end

-- Helper: format seconds to HH:MM:SS
local function format_time(seconds)
    if not seconds then return "00:00:00" end
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hrs, mins, secs)
end

-- Escape CSV fields if needed
local function escape_csv_field(field)
    if field:find('[,"\n]') then
        field = '"' .. field:gsub('"', '""') .. '"'
    end
    return field
end

-- Get original URL (works for YouTube and local files)
local function get_original_url()
    local filename = mp.get_property("filename") or ""
    local stream_open_filename = mp.get_property("stream-open-filename") or ""

    local url = "unknown"

    if filename:match("^watch%?v=") then
        url = "https://youtube.com/" .. filename
    elseif stream_open_filename:match("^https?://") then
        url = stream_open_filename
    elseif stream_open_filename:match("^edl://") or stream_open_filename:match("^file://") then
        url = "local file"
    elseif stream_open_filename:match("^/") then
        url = "file://" .. stream_open_filename
    end

    -- Clip long URLs
    local max_length = 128
    if #url > max_length then
        url = url:sub(1, max_length) .. "..."
    end

    return url
end

-- Ensure parent directory exists for the CSV path
local function ensure_directory_for_file(file_path)
    -- Extract directory path from full file path
    local dir_path = file_path:match("(.+)/[^/]+$")
    if dir_path then
        local mkdir_command = string.format('mkdir -p "%s"', dir_path)
        os.execute(mkdir_command)
    end
end

-- Logging function
local function log_timestamp(type_label)
    local title = mp.get_property("media-title") or "unknown title"
    local url = get_original_url()
    local time_pos = mp.get_property_number("time-pos", 0)
    local duration = mp.get_property_number("duration", 0)

    local formatted_time = format_time(time_pos)
    local formatted_duration = format_time(duration)

    -- Make sure directory exists
    ensure_directory_for_file(config.csv_path)

    -- Format CSV line: Title, URL, Timestamp, Duration, Label
    local csv_line = string.format(
        "%s,%s,%s,%s,%s\n",
        escape_csv_field(title),
        escape_csv_field(url),
        formatted_time,
        formatted_duration,
        escape_csv_field(type_label)
    )

    local file = io.open(config.csv_path, "a")
    if file then
        file:write(csv_line)
        file:close()
    else
        mp.msg.error("Failed to write to " .. config.csv_path)
    end

    mp.osd_message(string.format("Logged [%s] %s @ %s", type_label, title, formatted_time), 2)
    print(string.format("Logged [%s] %s @ %s", type_label, title, formatted_time))
end

-- Register key bindings from config
for key, label in pairs(config.bindings) do
    mp.add_forced_key_binding(key, "log-" .. label:gsub(" ", "-"), function()
        log_timestamp(label)
    end)
end
