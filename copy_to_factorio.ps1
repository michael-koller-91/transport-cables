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
    if ("$destination\$folder" -ne $null) {
        Remove-Item "$destination\$folder" -Force -Recurse
    }
    New-Item -Path $destination -Name $folder -Type "directory" -Force
    Copy-Item -Path "$source\$folder\*" -Destination "$destination\$folder" -Recurse -Verbose -Force
}

foreach ($file in $files) {
    if ("$destination\$file" -ne $null) {
        Remove-Item "$destination\$file" -Force
    }
    Copy-Item -Path "$source\$file" -Destination "$destination\$file" -Recurse -Verbose -Force
}
