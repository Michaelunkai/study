Add-Type -AssemblyName System.Drawing

# Create a 256x256 icon
$sizes = @(256, 128, 64, 48, 32, 16)
$bmp256 = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp256)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# Dark background
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 15, 26))), 0, 0, 256, 256)

# Rounded rect (simulate with ellipse corners)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(233, 69, 96))
$g.FillEllipse($brush, 10, 10, 236, 236)

# Inner dark circle
$innerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 15, 26))
$g.FillEllipse($innerBrush, 20, 20, 216, 216)

# Game controller emoji / clock symbol
$font = New-Object System.Drawing.Font("Segoe UI Emoji", 100, [System.Drawing.FontStyle]::Bold)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(233, 69, 96))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("🎮", $font, $whiteBrush, [System.Drawing.RectangleF]::new(0, 0, 256, 256), $sf)

$g.Dispose()

# Save as PNG first
$bmp256.Save("F:\Downloads\GameTime\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Save as ICO using multiple sizes
$iconPath = "F:\Downloads\GameTime\icon.ico"
$ms = New-Object System.IO.MemoryStream

# ICO header
$writer = New-Object System.IO.BinaryWriter($ms)
$writer.Write([uint16]0)   # reserved
$writer.Write([uint16]1)   # type: icon
$writer.Write([uint16]1)   # count: 1 image

# Image data offset = 6 (header) + 16 (dir entry) = 22
$imgMs = New-Object System.IO.MemoryStream
$bmp256.Save($imgMs, [System.Drawing.Imaging.ImageFormat]::Png)
$imgBytes = $imgMs.ToArray()

# Directory entry
$writer.Write([byte]0)     # width (0 = 256)
$writer.Write([byte]0)     # height (0 = 256)
$writer.Write([byte]0)     # color count
$writer.Write([byte]0)     # reserved
$writer.Write([uint16]1)   # planes
$writer.Write([uint16]32)  # bit count
$writer.Write([uint32]$imgBytes.Length)
$writer.Write([uint32]22)  # offset

$writer.Write($imgBytes)
$writer.Flush()

[System.IO.File]::WriteAllBytes($iconPath, $ms.ToArray())
$ms.Dispose()

Write-Host "Icon created: $iconPath ($($imgBytes.Length) bytes)"
$bmp256.Dispose()
