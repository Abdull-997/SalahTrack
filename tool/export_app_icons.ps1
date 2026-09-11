$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Artwork = [System.Drawing.Image]::FromFile((Join-Path $ProjectRoot 'native/branding/mosque-icon.png'))

function Export-Icon([string]$Path, [int]$Size) {
    $Target = Join-Path $ProjectRoot $Path
    New-Item -ItemType Directory -Force (Split-Path -Parent $Target) | Out-Null
    # Opaque RGB exports also meet the iOS App Store icon requirements.
    $Bitmap = New-Object System.Drawing.Bitmap($Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb))
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    try {
        $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $Graphics.DrawImage($Artwork, 0, 0, $Size, $Size)
        $Bitmap.Save($Target, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $Graphics.Dispose()
        $Bitmap.Dispose()
    }
}

try {
    $Densities = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($Density in $Densities.GetEnumerator()) {
        $Relative = "mipmap-$($Density.Key)/ic_launcher.png"
        Export-Icon "native/android/res/$Relative" $Density.Value
        $Destination = Join-Path $ProjectRoot "android/app/src/main/res/$Relative"
        New-Item -ItemType Directory -Force (Split-Path -Parent $Destination) | Out-Null
        Copy-Item -LiteralPath (Join-Path $ProjectRoot "native/android/res/$Relative") -Destination $Destination
    }
    Export-Icon 'native/android/res/drawable-nodpi/ic_launcher_art.png' 432
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'native/android/res') -Directory |
        Copy-Item -Destination (Join-Path $ProjectRoot 'android/app/src/main/res') -Recurse -Force

    $CatalogPath = Join-Path $ProjectRoot 'native/ios/AppIcon.appiconset'
    $Catalog = Get-Content -Raw (Join-Path $CatalogPath 'Contents.json') | ConvertFrom-Json
    foreach ($Entry in ($Catalog.images | Sort-Object filename -Unique)) {
        $Points = [double]::Parse($Entry.size.Split('x')[0], [System.Globalization.CultureInfo]::InvariantCulture)
        $Scale = [int]$Entry.scale.TrimEnd('x')
        Export-Icon "native/ios/AppIcon.appiconset/$($Entry.filename)" ([int]($Points * $Scale))
    }
    $Destination = Join-Path $ProjectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    New-Item -ItemType Directory -Force $Destination | Out-Null
    Get-ChildItem -LiteralPath $CatalogPath -File | Copy-Item -Destination $Destination
    Write-Host 'Exported mosque launcher icons for Android and iOS.'
}
finally {
    $Artwork.Dispose()
}
