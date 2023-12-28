$source = Get-Location
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

Write-Host "source: $source\"

foreach ($folder in $folders) {
    if ("$destination\$folder" -ne $null) {
        Remove-Item "$destination\$folder" -Force -Recurse
    }
    $null = New-Item -Path $destination -Name $folder -Type "directory" -Force
    Copy-Item -Path "$source\$folder\*" -Destination "$destination\$folder" -Recurse -Force
    Write-Host "destination: $destination\$folder\*"
}

foreach ($file in $files) {
    if ("$destination\$file" -ne $null) {
        Remove-Item "$destination\$file" -Force
    }
    Copy-Item -Path "$source\$file" -Destination "$destination\$file" -Recurse -Force
    Write-Host "destination: $destination\$file"
}
