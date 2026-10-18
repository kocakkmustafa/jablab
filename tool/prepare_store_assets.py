"""Package the approved icon and render review-only store compositions offline.

Uses the existing approved full-frame LANCZOS recipe. The feature graphic is
a code-defined PDF composition, rasterized locally; it is not an app screenshot.
No source image is redrawn, and no network/image-generation service is used.
"""
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

MASTER_SHA = '94e23e1069f0f5f78c6503b12fc2e8e6edab340cfecb3b301bf5976188f7d8c2'
ICON_SHA = '399b21552dfaec9310ff7a9423bd397ed4e83a027a4f1783c111f02f22e1869a'
MASTER = 'docs/design/icon/approved-2026-10-16/master.png'
ICON = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
COPY = {
    'en-US': ('Solo boxing practice', 'Text lessons', 'Self-check and practice record'),
    'tr-TR': ('Solo boks pratiği', 'Metin dersleri', 'Öz denetim ve çalışma kaydı'),
}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def approved_sources(repo):
    repo = Path(repo)
    for relative, expected in [(MASTER, MASTER_SHA), (ICON, ICON_SHA)]:
        if digest(repo / relative) != expected:
            raise ValueError('Approved icon source hash mismatch: ' + relative)
    manifest = json.loads((repo / 'docs/design/icon/approved-2026-10-16/manifest.json').read_text())
    if manifest['master']['sha256'] != MASTER_SHA or manifest['approved_version'] != 'v14-natural-wrap':
        raise ValueError('Reconcile changed icon approval before export')
    return repo / MASTER, repo / ICON


def export_assets(repo, output):
    from PIL import Image, PngImagePlugin, __version__ as pillow_version
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.pdfgen import canvas

    master, icon = approved_sources(repo)
    output = Path(output)
    if output.exists():
        raise FileExistsError('Asset output must be new')
    output.mkdir(parents=True)
    ios = output / 'app-store-icon-1024.png'
    play = output / 'play-icon-512.png'
    shutil.copyfile(icon, ios)
    tag = PngImagePlugin.PngInfo()
    tag.add(b'sRGB', b'\x00')
    with Image.open(master) as image:
        if image.mode != 'RGB' or image.size != (1254, 1254):
            raise ValueError('Approved master dimensions/color changed')
        image.resize((512, 512), Image.Resampling.LANCZOS).save(play, pnginfo=tag)

    font_dir = Path('/System/Library/Fonts/Supplemental')
    fonts = [('JabLabStoreRegular', font_dir / 'Arial.ttf'),
             ('JabLabStoreBold', font_dir / 'Arial Bold.ttf')]
    for name, path in fonts:
        if name not in pdfmetrics.getRegisteredFontNames():
            pdfmetrics.registerFont(TTFont(name, str(path)))
    graphics = []
    for locale, lines in COPY.items():
        pdf = output / ('play-feature-' + locale + '.pdf')
        png = pdf.with_suffix('.png')
        page = canvas.Canvas(str(pdf), pagesize=(1024, 500), invariant=1)
        page.setTitle('JabLab feature graphic review draft ' + locale)
        page.setFillColorRGB(0.075, 0.059, 0.086)
        page.rect(0, 0, 1024, 500, fill=1, stroke=0)
        page.drawImage(str(ios), 40, 40, width=420, height=420)
        page.setFillColorRGB(1, 0.96, 0.94)
        page.setFont('JabLabStoreBold', 58)
        page.drawString(512, 324, 'JabLab')
        for text, size, y in [(lines[0], 29, 264), (lines[1], 24, 184), (lines[2], 24, 144)]:
            if pdfmetrics.stringWidth(text, 'JabLabStoreRegular', size) > 472:
                raise ValueError('Feature graphic text exceeds safe width')
            page.setFont('JabLabStoreRegular', size)
            page.drawString(512, y, text)
        page.setFillColorRGB(0.91, 0.08, 0.18)
        page.rect(512, 222, 80, 5, fill=1, stroke=0)
        page.showPage()
        page.save()
        subprocess.run(['/usr/bin/sips', '-s', 'format', 'png', str(pdf), '--out', str(png)],
                       check=True, capture_output=True, text=True)
        # Flatten only the local vector renderer's output to store-compatible RGB.
        with Image.open(png) as rendered:
            if rendered.size != (1024, 500):
                raise ValueError('Feature graphic raster dimensions changed')
            flattened = rendered.convert('RGB')
        flattened.save(png, pnginfo=tag)
        graphics.append({'locale': locale, 'file': png.name, 'sha256': digest(png),
                         'dimensions': [1024, 500], 'mode': 'RGB',
                         'editable_layout': pdf.name, 'pdf_sha256': digest(pdf),
                         'approval': 'OWNER_VISUAL_REVIEW_PENDING', 'app_screenshot': False})
    return {
        'icon_approval': 'v14-natural-wrap, 2026-10-16',
        'source_master': {'path': MASTER, 'sha256': MASTER_SHA},
        'icons': [{'file': ios.name, 'sha256': digest(ios), 'dimensions': [1024, 1024],
                   'mode': 'RGB', 'method': 'byte-for-byte approved native icon'},
                  {'file': play.name, 'sha256': digest(play), 'dimensions': [512, 512],
                   'mode': 'RGB', 'method': 'approved master full-frame LANCZOS; sRGB, no alpha'}],
        'feature_graphics': graphics,
        'renderer': {'pillow': pillow_version, 'layout': 'ReportLab PDF', 'rasterizer': '/usr/bin/sips',
                     'font_hashes': {path.name: digest(path) for _, path in fonts}},
        'historical_store_candidates_exported': False,
        'native_screenshots': 'PENDING_CURRENT_NATIVE_BUILD',
    }
