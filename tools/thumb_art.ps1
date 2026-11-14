# Store-thumbnail art helper (docs/THUMBNAILS.md §9). Windows only: headless Edge + System.Drawing, no extra installs.
#   render   docs/art/logo/logo.html -> transparent, trimmed PNGs in docs/art/logo/ (light + dark logo, pawprint mark).
#   compose  puts a logo PNG onto a frame:   -Frame <jpg/png> [-Logo <png>] -Out <png> [-Width 0.42] [-Corner TL|TR|BL|BR]
#            [-Margin 0.035]. The frame is first cropped to its middle -Aspect band (default 16:9; Studio captures are
#            taller) and scaled to -Size "WxH" if given (the store wants 1920x1080; the icon 512x512). No -Logo: crop only.
#   tiles    writes one image with the frame at 320, 200 and 150 px wide (store tile sizes): -Frame <png> -Out <png>
#   grab     captures Roblox Studio's window at full resolution (PrintWindow: Studio needn't be in front, but must not be
#            minimized) and saves the 3D viewport's middle -Aspect band: -Out <png> -Rect "x,y,w,h" (the viewport inside the
#            capture, in physical pixels). Without -Rect it saves the whole window so you can read the viewport's edges off it
#            (on a 150 % display: workspace.CurrentCamera.ViewportSize x 1.5; the edge is the grey 188,190,200 border).
# Outputs ending in .jpg are saved as JPEG (quality 92), others as PNG.
param(
	[Parameter(Mandatory)][ValidateSet("render", "compose", "tiles", "grab")][string]$Mode,
	[string]$Frame, [string]$Logo, [string]$Out, [string]$Rect, [string]$Aspect = "16:9", [string]$Size,
	[double]$Width = 0.42, [ValidateSet("TL", "TR", "BL", "BR")][string]$Corner = "TL", [double]$Margin = 0.035,
	[int]$Scale = 2
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class LogoArt {
	// Crops a 32-bit image to the bounding box of its non-transparent pixels.
	public static Bitmap Trim(Bitmap src) {
		var b = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(b)) g.DrawImage(src, 0, 0, src.Width, src.Height);
		var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
		var px = new byte[d.Stride * b.Height]; Marshal.Copy(d.Scan0, px, 0, px.Length); b.UnlockBits(d);
		int x0 = b.Width, y0 = b.Height, x1 = -1, y1 = -1;
		for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++)
			if (px[y * d.Stride + x * 4 + 3] > 0) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
		if (x1 < 0) throw new Exception("image is fully transparent");
		var r = b.Clone(new Rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1), PixelFormat.Format32bppArgb); b.Dispose(); return r;
	}
	// The largest centred band of aspect aw:ah, scaled to outW x outH (0 = keep its size).
	public static Bitmap Band(Image src, double aw, double ah, int outW, int outH) {
		int h = (int)Math.Round(src.Width * ah / aw), w = src.Width;
		if (h > src.Height) { h = src.Height; w = (int)Math.Round(h * aw / ah); }
		if (outW <= 0) { outW = w; outH = h; }
		var r = new Bitmap(outW, outH, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(r)) {
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
			g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
			using (var a = new ImageAttributes()) {
				a.SetWrapMode(System.Drawing.Drawing2D.WrapMode.TileFlipXY);
				g.DrawImage(src, new Rectangle(0, 0, outW, outH), (src.Width - w) / 2, (src.Height - h) / 2, w, h, GraphicsUnit.Pixel, a);
			}
		}
		return r;
	}
	[DllImport("user32.dll")] static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
	[DllImport("user32.dll")] static extern bool SetProcessDPIAware();
	[DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
	[DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
	struct RECT { public int L, T, R, B; }
	public static Bitmap GrabWindow(IntPtr h) {
		if (IsIconic(h)) throw new Exception("the window is minimized: restore it first");
		SetProcessDPIAware(); RECT r; GetWindowRect(h, out r);
		var b = new Bitmap(r.R - r.L, r.B - r.T, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(b)) { var dc = g.GetHdc(); PrintWindow(h, dc, 2); g.ReleaseHdc(dc); } // 2 = full content
		return b;
	}
	public static void Save(Image img, string path) {
		if (path.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase)) {
			var codec = Array.Find(ImageCodecInfo.GetImageEncoders(), c => c.MimeType == "image/jpeg");
			var ps = new EncoderParameters(1); ps.Param[0] = new EncoderParameter(Encoder.Quality, 92L);
			img.Save(path, codec, ps);
		} else img.Save(path, ImageFormat.Png);
	}
	public static void Draw(Graphics g, Image img, int x, int y, int w, int h) {
		g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
		g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
		g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
		using (var a = new ImageAttributes()) {
			a.SetWrapMode(System.Drawing.Drawing2D.WrapMode.TileFlipXY);
			g.DrawImage(img, new Rectangle(x, y, w, h), 0, 0, img.Width, img.Height, GraphicsUnit.Pixel, a);
		}
	}
}
"@

$root = Split-Path -Parent $PSScriptRoot
$logoDir = Join-Path $root "docs\art\logo"
function Full([string]$p) { if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path (Get-Location) $p } }
function Get-Band($img) {
	$a = $Aspect.Split(":") | ForEach-Object { [double]$_ }
	$s = if ($Size) { $Size.ToLower().Split("x") | ForEach-Object { [int]$_ } } else { 0, 0 }
	[LogoArt]::Band($img, $a[0], $a[1], $s[0], $s[1])
}

if ($Mode -eq "render") {
	$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
	if (-not (Test-Path $edge)) { throw "Edge not found at $edge" }
	$page = "file:///" + ((Join-Path $logoDir "logo.html") -replace "\\", "/")
	$tmp = Join-Path $env:TEMP "pawvest-logo-render"
	New-Item -ItemType Directory -Force $tmp | Out-Null
	foreach ($job in @(@("pawvest-logo-light.png", "v=light"), @("pawvest-logo-dark.png", "v=dark"), @("pawvest-mark.png", "part=mark"))) {
		$shot = Join-Path $tmp $job[0]
		$argv = @("--headless=new", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000",
			"--virtual-time-budget=4000", "--force-device-scale-factor=$Scale", "--window-size=1600,1000",
			"--user-data-dir=$tmp\profile", "--screenshot=$shot", "$page#$($job[1])")
		Start-Process -FilePath $edge -ArgumentList $argv -Wait -WindowStyle Hidden
		$img = [Drawing.Bitmap]::FromFile($shot)
		$trimmed = [LogoArt]::Trim($img); $img.Dispose()
		$dest = Join-Path $logoDir $job[0]
		$trimmed.Save($dest, [Drawing.Imaging.ImageFormat]::Png)
		"$($job[0]): $($trimmed.Width)x$($trimmed.Height)"
		$trimmed.Dispose()
	}
}
elseif ($Mode -eq "compose") {
	$src = [Drawing.Image]::FromFile((Full $Frame)); $band = Get-Band $src; $src.Dispose()
	$note = "no logo"
	if ($Logo) {
		$logoImg = [Drawing.Image]::FromFile((Full $Logo))
		$w = [int]($band.Width * $Width); $h = [int]($w * $logoImg.Height / $logoImg.Width); $m = [int]($band.Width * $Margin)
		$x = if ($Corner -like "?L") { $m } else { $band.Width - $w - $m }
		$y = if ($Corner -like "T?") { $m } else { $band.Height - $h - $m }
		$g = [Drawing.Graphics]::FromImage($band); [LogoArt]::Draw($g, $logoImg, $x, $y, $w, $h); $g.Dispose(); $logoImg.Dispose()
		$note = "logo ${w}x$h at $x,$y"
	}
	[LogoArt]::Save($band, (Full $Out))
	"composed $($band.Width)x$($band.Height), $note"
	$band.Dispose()
}
elseif ($Mode -eq "grab") {
	$studio = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
	if (-not $studio) { throw "no Roblox Studio window" }
	$win = [LogoArt]::GrabWindow($studio.MainWindowHandle)
	if (-not $Rect) { [LogoArt]::Save($win, (Full $Out)); "whole window $($win.Width)x$($win.Height) saved: read the viewport rect off it"; $win.Dispose(); return }
	$r = $Rect.Split(",") | ForEach-Object { [int]$_ }
	$vp = $win.Clone([Drawing.Rectangle]::new($r[0], $r[1], $r[2], $r[3]), [Drawing.Imaging.PixelFormat]::Format32bppArgb); $win.Dispose()
	$band = Get-Band $vp; $vp.Dispose()
	[LogoArt]::Save($band, (Full $Out)); "grabbed $($band.Width)x$($band.Height)"; $band.Dispose()
}
else {
	$src = [Drawing.Image]::FromFile((Full $Frame))
	$sizes = 320, 200, 150; $gap = 16
	$sheet = [Drawing.Bitmap]::new([int](($sizes | Measure-Object -Sum).Sum + $gap * 4), [int](320 * $src.Height / $src.Width + $gap * 2))
	$g = [Drawing.Graphics]::FromImage($sheet); $g.Clear([Drawing.Color]::FromArgb(255, 32, 34, 38)); $x = $gap
	foreach ($s in $sizes) { [LogoArt]::Draw($g, $src, $x, $gap, $s, [int]($s * $src.Height / $src.Width)); $x += $s + $gap }
	$g.Dispose(); $src.Dispose()
	[LogoArt]::Save($sheet, (Full $Out)); $sheet.Dispose()
	"tiles written"
}
