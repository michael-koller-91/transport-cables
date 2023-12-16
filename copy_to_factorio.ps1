$source = "C:\git\transport-cables"
$destination = "C:\Users\Admin\AppData\Roaming\Factorio\mods\transport-cables_0.0.1"
$files = (
    "locale\",
    "prototypes\",
    "sprites\",
    "control.lua",
    "data.lua",
    "info.json",
    "lib.lua"
)

foreach ($file in $files) {
    Copy-Item "$source\$file" -Destination "$destination\$file" -Recurse -Force -Verbose
}
