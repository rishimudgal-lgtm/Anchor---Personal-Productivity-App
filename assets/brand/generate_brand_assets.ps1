Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

function New-AnchorHubIcon {
    param(
        [Parameter(Mandatory = $true)][int]$Size,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $scale = $Size / 512.0

    $bounds = [System.Drawing.RectangleF]::new(0, 0, $Size, $Size)
    $surface = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $bounds,
        [System.Drawing.Color]::FromArgb(255, 6, 17, 22),
        [System.Drawing.Color]::FromArgb(255, 11, 38, 48),
        45.0
    )
    $graphics.FillRectangle($surface, $bounds)

    $glowBounds = [System.Drawing.RectangleF]::new(82 * $scale, 82 * $scale, 348 * $scale, 348 * $scale)
    $glowPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $glowPath.AddEllipse($glowBounds)
    $glow = [System.Drawing.Drawing2D.PathGradientBrush]::new($glowPath)
    $glow.CenterColor = [System.Drawing.Color]::FromArgb(62, 6, 182, 212)
    $glow.SurroundColors = [System.Drawing.Color[]]@([System.Drawing.Color]::FromArgb(0, 6, 182, 212))
    $graphics.FillEllipse($glow, $glowBounds)

    $ringPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(26, 34, 211, 238), 2 * $scale)
    $graphics.DrawEllipse($ringPen, 52 * $scale, 52 * $scale, 408 * $scale, 408 * $scale)

    $anchorPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(245, 233, 252, 253), 23 * $scale)
    $anchorPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $anchorPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $anchorPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawEllipse($anchorPen, 214 * $scale, 94 * $scale, 84 * $scale, 84 * $scale)
    $graphics.DrawLine($anchorPen, 256 * $scale, 178 * $scale, 256 * $scale, 376 * $scale)
    $graphics.DrawLine($anchorPen, 164 * $scale, 228 * $scale, 348 * $scale, 228 * $scale)

    $arms = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $arms.AddBezier(
        [System.Drawing.PointF]::new(176 * $scale, 296 * $scale),
        [System.Drawing.PointF]::new(176 * $scale, 345 * $scale),
        [System.Drawing.PointF]::new(216 * $scale, 378 * $scale),
        [System.Drawing.PointF]::new(256 * $scale, 382 * $scale)
    )
    $arms.AddBezier(
        [System.Drawing.PointF]::new(256 * $scale, 382 * $scale),
        [System.Drawing.PointF]::new(296 * $scale, 378 * $scale),
        [System.Drawing.PointF]::new(336 * $scale, 345 * $scale),
        [System.Drawing.PointF]::new(336 * $scale, 296 * $scale)
    )
    $graphics.DrawPath($anchorPen, $arms)
    $graphics.DrawLine($anchorPen, 176 * $scale, 296 * $scale, 139 * $scale, 333 * $scale)
    $graphics.DrawLine($anchorPen, 139 * $scale, 333 * $scale, 197 * $scale, 337 * $scale)
    $graphics.DrawLine($anchorPen, 336 * $scale, 296 * $scale, 373 * $scale, 333 * $scale)
    $graphics.DrawLine($anchorPen, 373 * $scale, 333 * $scale, 315 * $scale, 337 * $scale)

    $cyanBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 34, 211, 238))
    $graphics.FillEllipse($cyanBrush, 244 * $scale, 124 * $scale, 24 * $scale, 24 * $scale)

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    $cyanBrush.Dispose()
    $arms.Dispose()
    $anchorPen.Dispose()
    $ringPen.Dispose()
    $glow.Dispose()
    $glowPath.Dispose()
    $surface.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

New-AnchorHubIcon -Size 512 -Path (Join-Path $projectRoot 'assets/brand/anchor_hub_logo.png')
New-AnchorHubIcon -Size 192 -Path (Join-Path $projectRoot 'web/icons/Icon-192.png')
New-AnchorHubIcon -Size 512 -Path (Join-Path $projectRoot 'web/icons/Icon-512.png')
New-AnchorHubIcon -Size 192 -Path (Join-Path $projectRoot 'web/icons/Icon-maskable-192.png')
New-AnchorHubIcon -Size 512 -Path (Join-Path $projectRoot 'web/icons/Icon-maskable-512.png')
New-AnchorHubIcon -Size 32 -Path (Join-Path $projectRoot 'web/favicon.png')

$androidSizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($folder in $androidSizes.Keys) {
    New-AnchorHubIcon -Size $androidSizes[$folder] -Path (Join-Path $projectRoot "android/app/src/main/res/$folder/ic_launcher.png")
}
