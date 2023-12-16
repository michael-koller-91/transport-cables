$source = "C:\git\transport-cables"
$destination = "C:\Users\Admin\AppData\Roaming\Factorio\mods\transport-cables_0.0.1"
$folders = (
    "locale",
    "prototypes",
    "sprites"
)
$files = (
    "control.lua",
    "data.lua",
    "info.json",
    "lib.lua"
)

foreach ($folder in $folders) {
    New-Item -Path $destination -Name $folder -Type "directory" -Force
    Copy-Item -Path "$source\$folder\*" -Destination "$destination\$folder" -Recurse -Verbose -Force
}

foreach ($file in $files) {
    Copy-Item -Path "$source\$file" -Destination "$destination\$file" -Recurse -Verbose -Force
}
