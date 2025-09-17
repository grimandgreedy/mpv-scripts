## log_timestamps.lua

Log "filename, path (or url), timestamp, duration, tag" to a file.
Keys are assigned to labels and when a specified keybind is pressed it logs a row to a csv file. The row consists of:

 1. Title
 2. Path (or URL)
 3. Timestamp
 4. Duration
 5. The tag associated with that keybind

The default output file is "~/Documents/mpv_timestamps.csv".

The labels and keybinds are defined as so:

```lua
local bindings = {
    ["CTRL+I"] = "important",
    ["CTRL+E"] = "example",
    ["CTRL+R"] = "revisit",
    ["CTRL+U"] = "unclear",
    ["CTRL+W"] = "warning",
}
```

## seek-to.lua

Based on `seek-to.lua`. Improvements to UI. Active digit is highlighted. Prompt enlarged.
