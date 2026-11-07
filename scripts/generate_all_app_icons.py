import os
import subprocess
from PIL import Image

def get_svg(is_maskable=False):
    # If maskable/full-bleed, background covers 100% square without rx
    # If squircle, rounded corners rx=224 ry=224
    rx_attr = '' if is_maskable else 'rx="224"'
    border_element = '' if is_maskable else '<rect x="3" y="3" width="1018" height="1018" rx="221" fill="none" stroke="url(#borderGlow)" stroke-width="4" />'

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <!-- Background Gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1E1B4B" />
      <stop offset="45%" stop-color="#0F172A" />
      <stop offset="100%" stop-color="#090D16" />
    </linearGradient>

    <!-- Outer Squircle Border Glow -->
    <linearGradient id="borderGlow" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#818CF8" stop-opacity="0.55" />
      <stop offset="50%" stop-color="#38BDF8" stop-opacity="0.25" />
      <stop offset="100%" stop-color="#10B981" stop-opacity="0.45" />
    </linearGradient>

    <!-- Ambient Glow behind Owl -->
    <radialGradient id="ambientBackGlow" cx="50%" cy="48%" r="45%">
      <stop offset="0%" stop-color="#10B981" stop-opacity="0.32" />
      <stop offset="50%" stop-color="#06B6D4" stop-opacity="0.18" />
      <stop offset="80%" stop-color="#F59E0B" stop-opacity="0.08" />
      <stop offset="100%" stop-color="#0F172A" stop-opacity="0" />
    </radialGradient>

    <!-- Owl Body Gradient -->
    <linearGradient id="owlBodyGrad" x1="50%" y1="18%" x2="50%" y2="92%">
      <stop offset="0%" stop-color="#10B981" />
      <stop offset="35%" stop-color="#059669" />
      <stop offset="75%" stop-color="#047857" />
      <stop offset="100%" stop-color="#064E3B" />
    </linearGradient>

    <!-- Wing Left Gradient -->
    <linearGradient id="wingLeftGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#059669" />
      <stop offset="60%" stop-color="#047857" />
      <stop offset="100%" stop-color="#064E3B" />
    </linearGradient>

    <!-- Wing Right Gradient -->
    <linearGradient id="wingRightGrad" x1="100%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#10B981" />
      <stop offset="60%" stop-color="#059669" />
      <stop offset="100%" stop-color="#047857" />
    </linearGradient>

    <!-- Belly Gradient -->
    <linearGradient id="bellyGrad" x1="50%" y1="0%" x2="50%" y2="100%">
      <stop offset="0%" stop-color="#FFFBEB" />
      <stop offset="60%" stop-color="#FEF3C7" />
      <stop offset="100%" stop-color="#FDE68A" />
    </linearGradient>

    <!-- Gold Metallic Gradient (Glasses & Tassel) -->
    <linearGradient id="goldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FDE68A" />
      <stop offset="40%" stop-color="#FBBF24" />
      <stop offset="70%" stop-color="#F59E0B" />
      <stop offset="100%" stop-color="#D97706" />
    </linearGradient>

    <!-- Beak Gradient -->
    <linearGradient id="beakGrad" x1="50%" y1="0%" x2="50%" y2="100%">
      <stop offset="0%" stop-color="#FBBF24" />
      <stop offset="60%" stop-color="#F59E0B" />
      <stop offset="100%" stop-color="#D97706" />
    </linearGradient>

    <!-- Mortarboard Cap Top Gradient -->
    <linearGradient id="capTopGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#3730A3" />
      <stop offset="40%" stop-color="#1E1B4B" />
      <stop offset="100%" stop-color="#0F172A" />
    </linearGradient>

    <!-- Cap Base Gradient -->
    <linearGradient id="capBaseGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#1E1B4B" />
      <stop offset="50%" stop-color="#4338CA" />
      <stop offset="100%" stop-color="#1E1B4B" />
    </linearGradient>

    <!-- Eye Iris Gradient -->
    <radialGradient id="irisGrad" cx="45%" cy="40%" r="55%">
      <stop offset="0%" stop-color="#34D399" />
      <stop offset="45%" stop-color="#10B981" />
      <stop offset="85%" stop-color="#059669" />
      <stop offset="100%" stop-color="#064E3B" />
    </radialGradient>

    <!-- Book Cover Gradient -->
    <linearGradient id="bookCoverGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#4F46E5" />
      <stop offset="50%" stop-color="#3730A3" />
      <stop offset="100%" stop-color="#312E81" />
    </linearGradient>

    <!-- Book Pages Gradient -->
    <linearGradient id="bookPagesGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF" />
      <stop offset="80%" stop-color="#F1F5F9" />
      <stop offset="100%" stop-color="#E2E8F0" />
    </linearGradient>

    <!-- Drop Shadows -->
    <filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.45" />
    </filter>
    <filter id="glowFilter" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>

  <!-- Base Icon Background -->
  <rect x="0" y="0" width="1024" height="1024" {rx_attr} fill="url(#bgGrad)" />
  {border_element}

  <!-- Ambient Light Sphere Behind Owl -->
  <circle cx="512" cy="510" r="390" fill="url(#ambientBackGlow)" />

  <!-- Magic Stars / Sparkles in Background -->
  <!-- Top Right Sparkle -->
  <g transform="translate(810, 200) scale(1.1)">
    <path d="M 0 -24 Q 0 0 24 0 Q 0 0 0 24 Q 0 0 -24 0 Q 0 0 0 -24 Z" fill="#FBBF24" opacity="0.85" filter="url(#glowFilter)" />
    <circle cx="0" cy="0" r="4" fill="#FFFFFF" />
  </g>
  <!-- Small Top Right Star -->
  <circle cx="890" cy="270" r="4.5" fill="#38BDF8" opacity="0.8" />
  <!-- Top Left Sparkle -->
  <g transform="translate(200, 230) scale(0.85)">
    <path d="M 0 -22 Q 0 0 22 0 Q 0 0 0 22 Q 0 0 -22 0 Q 0 0 0 -22 Z" fill="#38BDF8" opacity="0.85" filter="url(#glowFilter)" />
    <circle cx="0" cy="0" r="3" fill="#FFFFFF" />
  </g>
  <circle cx="150" cy="300" r="4" fill="#FBBF24" opacity="0.75" />

  <!-- Ground Shadow under Perch / Book -->
  <ellipse cx="512" cy="880" rx="320" ry="32" fill="#000000" opacity="0.5" filter="url(#softShadow)" />

  <!-- OPEN BOOK / PEDAGOGICAL PERCH AT BOTTOM -->
  <g id="bookPerch">
    <!-- Book Backing Shadow -->
    <path d="M 270 820 C 370 845 470 840 512 822 C 554 840 654 845 754 820 C 760 825 765 838 750 845 C 650 870 550 862 512 846 C 474 862 374 870 274 845 C 259 838 264 825 270 820 Z" fill="#1E1B4B" opacity="0.8" />

    <!-- Left Book Page -->
    <path d="M 512 820 C 460 836 360 840 260 812 C 256 811 254 807 256 803 L 274 748 C 275 745 279 743 283 744 C 370 766 460 762 512 748 Z" fill="url(#bookPagesGrad)" stroke="#CBD5E1" stroke-width="2" />
    <!-- Left Page Lines -->
    <path d="M 310 765 C 370 778 440 776 480 768" stroke="#94A3B8" stroke-width="3" stroke-linecap="round" opacity="0.7" />
    <path d="M 310 782 C 370 795 440 793 480 785" stroke="#94A3B8" stroke-width="3" stroke-linecap="round" opacity="0.7" />

    <!-- Right Book Page -->
    <path d="M 512 748 C 564 762 654 766 741 744 C 745 743 749 745 750 748 L 768 803 C 770 807 768 811 764 812 C 664 840 564 836 512 820 Z" fill="url(#bookPagesGrad)" stroke="#CBD5E1" stroke-width="2" />
    <!-- Right Page Lines -->
    <path d="M 544 768 C 584 776 654 778 714 765" stroke="#94A3B8" stroke-width="3" stroke-linecap="round" opacity="0.7" />
    <path d="M 544 785 C 584 793 654 795 714 782" stroke="#94A3B8" stroke-width="3" stroke-linecap="round" opacity="0.7" />

    <!-- Golden Ribbon Bookmark hanging from center -->
    <path d="M 506 748 L 504 840 L 512 833 L 520 840 L 518 748 Z" fill="url(#goldGrad)" />
  </g>

  <!-- OWL MASCOT -->
  <g id="owlMascot">
    <!-- Cute Ear Tufts -->
    <path d="M 310 390 C 270 340 260 270 270 230 C 300 260 340 310 360 360 Z" fill="#047857" />
    <path d="M 305 375 C 280 335 275 285 280 255 C 300 280 330 320 345 355 Z" fill="#10B981" opacity="0.6" />
    <path d="M 714 390 C 754 340 764 270 754 230 C 724 260 684 310 664 360 Z" fill="#047857" />
    <path d="M 719 375 C 744 335 749 285 744 255 C 724 280 694 320 679 355 Z" fill="#10B981" opacity="0.6" />

    <!-- Main Owl Body (Chubby, Friendly Form) -->
    <path d="M 512 280 C 370 280 300 370 290 510 C 280 650 330 790 512 790 C 694 790 744 650 734 510 C 724 370 654 280 512 280 Z" fill="url(#owlBodyGrad)" filter="url(#softShadow)" />

    <!-- Owl Body Highlight Glow on Head -->
    <ellipse cx="512" cy="360" rx="150" ry="70" fill="#34D399" opacity="0.18" />

    <!-- Left Wing (Folded at side) -->
    <path d="M 292 480 C 255 540 240 645 285 710 C 305 690 335 630 345 550 C 350 500 340 470 330 460 C 310 460 298 470 292 480 Z" fill="url(#wingLeftGrad)" stroke="#064E3B" stroke-width="3" />
    <!-- Feather layer on left wing -->
    <path d="M 275 565 C 265 620 280 680 300 700 C 310 660 325 610 330 550" stroke="#065F46" stroke-width="4" stroke-linecap="round" fill="none" />

    <!-- Right Wing (Warmly gesturing / slightly raised) -->
    <path d="M 732 480 C 769 540 784 645 739 710 C 719 690 689 630 679 550 C 674 500 684 470 694 460 C 714 460 726 470 732 480 Z" fill="url(#wingRightGrad)" stroke="#047857" stroke-width="3" />
    <path d="M 749 565 C 759 620 744 680 724 700 C 714 660 699 610 694 550" stroke="#059669" stroke-width="4" stroke-linecap="round" fill="none" />

    <!-- Belly / Chest Patch -->
    <path d="M 512 490 C 420 490 375 550 375 645 C 375 735 435 780 512 780 C 589 780 649 735 649 645 C 649 550 604 490 512 490 Z" fill="url(#bellyGrad)" filter="url(#softShadow)" />

    <!-- Cute Feather Chevrons on Belly -->
    <g stroke="url(#goldGrad)" stroke-width="5" stroke-linecap="round" fill="none" opacity="0.9">
      <!-- Row 1 -->
      <path d="M 465 560 L 480 575 L 495 560" />
      <path d="M 529 560 L 544 575 L 559 560" />
      <!-- Row 2 -->
      <path d="M 438 610 L 453 625 L 468 610" />
      <path d="M 497 610 L 512 625 L 527 610" />
      <path d="M 556 610 L 571 625 L 586 610" />
      <!-- Row 3 -->
      <path d="M 465 660 L 480 675 L 495 660" />
      <path d="M 529 660 L 544 675 L 559 660" />
      <!-- Row 4 -->
      <path d="M 497 705 L 512 718 L 527 705" />
    </g>

    <!-- Cute Golden Paws / Claws -->
    <g fill="url(#goldGrad)" stroke="#D97706" stroke-width="3">
      <!-- Left Foot (3 toes) -->
      <ellipse cx="420" cy="780" rx="18" ry="12" />
      <ellipse cx="445" cy="783" rx="19" ry="13" />
      <ellipse cx="470" cy="780" rx="18" ry="12" />
      <!-- Right Foot (3 toes) -->
      <ellipse cx="554" cy="780" rx="18" ry="12" />
      <ellipse cx="579" cy="783" rx="19" ry="13" />
      <ellipse cx="604" cy="780" rx="18" ry="12" />
    </g>

    <!-- Soft Cheek Blush (Friendly & Warm) -->
    <ellipse cx="340" cy="510" rx="35" ry="20" fill="#F43F5E" opacity="0.22" />
    <ellipse cx="684" cy="510" rx="35" ry="20" fill="#F43F5E" opacity="0.22" />

    <!-- BIG EXPRESSIVE EYES -->
    <!-- Left Eye Socket White Base -->
    <g id="leftEye">
      <ellipse cx="410" cy="455" rx="85" ry="85" fill="#FFFFFF" filter="url(#softShadow)" />
      <!-- Eye Top Eyelid Shadow -->
      <path d="M 335 435 C 360 405 450 405 485 435 C 470 415 350 415 335 435 Z" fill="#E2E8F0" />
      <!-- Iris -->
      <ellipse cx="420" cy="458" rx="54" ry="54" fill="url(#irisGrad)" />
      <!-- Pupil -->
      <circle cx="423" cy="459" r="36" fill="#0F172A" />
      <!-- Eye Catchlight Primary (Large Soft Shine) -->
      <circle cx="440" cy="438" r="16" fill="#FFFFFF" />
      <!-- Eye Catchlight Secondary (Small sparkle twinkle) -->
      <circle cx="400" cy="478" r="7.5" fill="#FFFFFF" />
    </g>

    <!-- Right Eye Socket White Base -->
    <g id="rightEye">
      <ellipse cx="614" cy="455" rx="85" ry="85" fill="#FFFFFF" filter="url(#softShadow)" />
      <!-- Eye Top Eyelid Shadow -->
      <path d="M 539 435 C 564 405 654 405 689 435 C 674 415 554 415 539 435 Z" fill="#E2E8F0" />
      <!-- Iris -->
      <ellipse cx="604" cy="458" rx="54" ry="54" fill="url(#irisGrad)" />
      <!-- Pupil -->
      <circle cx="601" cy="459" r="36" fill="#0F172A" />
      <!-- Eye Catchlight Primary (Large Soft Shine) -->
      <circle cx="621" cy="438" r="16" fill="#FFFFFF" />
      <!-- Eye Catchlight Secondary (Small sparkle twinkle) -->
      <circle cx="581" cy="478" r="7.5" fill="#FFFFFF" />
    </g>

    <!-- SCHOLAR GLASSES (Gold wireframe with metallic shine & bridge) -->
    <g id="glasses" filter="url(#softShadow)">
      <!-- Left Rim -->
      <ellipse cx="410" cy="455" rx="87" ry="87" fill="none" stroke="url(#goldGrad)" stroke-width="13" />
      <ellipse cx="410" cy="455" rx="87" ry="87" fill="none" stroke="#FDE68A" stroke-width="3" opacity="0.6" />
      <!-- Left Lens Glint -->
      <path d="M 355 420 L 400 380 M 375 450 L 440 385" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.35" />

      <!-- Right Rim -->
      <ellipse cx="614" cy="455" rx="87" ry="87" fill="none" stroke="url(#goldGrad)" stroke-width="13" />
      <ellipse cx="614" cy="455" rx="87" ry="87" fill="none" stroke="#FDE68A" stroke-width="3" opacity="0.6" />
      <!-- Right Lens Glint -->
      <path d="M 560 420 L 605 380 M 580 450 L 645 385" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.35" />

      <!-- Golden Bridge connecting glasses over beak -->
      <path d="M 495 450 C 505 440 519 440 529 450" fill="none" stroke="url(#goldGrad)" stroke-width="12" stroke-linecap="round" />
      <path d="M 495 450 C 505 440 519 440 529 450" fill="none" stroke="#FDE68A" stroke-width="3" stroke-linecap="round" opacity="0.7" />
    </g>

    <!-- CUTE BEAK -->
    <g id="beak" filter="url(#softShadow)">
      <!-- Beak Base (Rounded triangle) -->
      <path d="M 512 555 C 496 555 480 495 488 480 C 496 468 528 468 536 480 C 544 495 528 555 512 555 Z" fill="url(#beakGrad)" stroke="#D97706" stroke-width="3" />
      <!-- Top Beak Highlight -->
      <path d="M 498 482 C 507 476 517 476 526 482" stroke="#FEF3C7" stroke-width="4" stroke-linecap="round" fill="none" />
      <!-- Friendly Smile Line under Beak -->
      <path d="M 494 562 C 504 570 520 570 530 562" stroke="#064E3B" stroke-width="4" stroke-linecap="round" fill="none" />
    </g>

    <!-- ACADEMIC MORTARBOARD CAP (Конфедератка) -->
    <g id="mortarboardCap" filter="url(#softShadow)">
      <!-- Cap Base Skullcap Band -->
      <ellipse cx="512" cy="305" rx="160" ry="46" fill="url(#capBaseGrad)" stroke="#4338CA" stroke-width="4" />
      <ellipse cx="512" cy="295" rx="155" ry="40" fill="#1E1B4B" />

      <!-- Diamond Mortarboard Top (Perspective 3D) -->
      <!-- Shadow edge -->
      <polygon points="512,185 780,265 512,345 244,265" fill="#111827" opacity="0.3" transform="translate(0, 10)" />
      <!-- Board Top Surface -->
      <polygon points="512,180 780,260 512,340 244,260" fill="url(#capTopGrad)" stroke="#6366F1" stroke-width="5" stroke-linejoin="round" />

      <!-- Top Edge Light Sheen -->
      <line x1="244" y1="260" x2="512" y2="180" stroke="#818CF8" stroke-width="4" stroke-linecap="round" />
      <line x1="512" y1="180" x2="780" y2="260" stroke="#818CF8" stroke-width="4" stroke-linecap="round" />

      <!-- Golden Center Button -->
      <ellipse cx="512" cy="260" rx="20" ry="15" fill="url(#goldGrad)" stroke="#B45309" stroke-width="3" />
      <ellipse cx="512" cy="257" rx="9" ry="6" fill="#FEF3C7" opacity="0.8" />

      <!-- Golden Braided Tassel flowing to right -->
      <g id="tassel">
        <!-- Tassel String drape -->
        <path d="M 512 260 C 620 280 690 310 715 380" fill="none" stroke="url(#goldGrad)" stroke-width="9" stroke-linecap="round" />
        <path d="M 512 260 C 620 280 690 310 715 380" fill="none" stroke="#FEF3C7" stroke-width="3" stroke-linecap="round" opacity="0.6" />

        <!-- Tassel Joint Ring -->
        <ellipse cx="715" cy="385" rx="10" ry="7" fill="url(#goldGrad)" stroke="#B45309" stroke-width="2" />

        <!-- Tassel Hanging Brush -->
        <path d="M 706 390 C 700 440 702 465 706 475 C 716 478 726 478 736 475 C 738 465 738 440 730 390 Z" fill="url(#goldGrad)" stroke="#D97706" stroke-width="3" />
        <!-- Tassel Fringe details -->
        <line x1="714" y1="440" x2="714" y2="472" stroke="#92400E" stroke-width="2.5" />
        <line x1="720" y1="440" x2="720" y2="474" stroke="#92400E" stroke-width="2.5" />
        <line x1="727" y1="440" x2="727" y2="472" stroke="#92400E" stroke-width="2.5" />
      </g>
    </g>
  </g>
</svg>
"""

def render_svg_to_png(svg_string, output_png_path):
    html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body, html {{ width: 1024px; height: 1024px; overflow: hidden; background: transparent; }}
  svg {{ width: 1024px; height: 1024px; display: block; }}
</style>
</head>
<body>
{svg_string}
</body>
</html>"""

    html_file = os.path.abspath('temp_render.html')
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(html_content)

    temp_screenshot = os.path.join(os.environ['TEMP'], 'chrome_render_icon.png')
    if os.path.exists(temp_screenshot):
        os.remove(temp_screenshot)

    url = 'file:///' + html_file.replace('\\', '/')
    cmd = [
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        '--headless=new',
        '--no-sandbox',
        '--disable-gpu',
        '--default-background-color=00000000',
        '--window-size=1024,1024',
        f'--screenshot={temp_screenshot}',
        url
    ]
    subprocess.run(cmd, check=True, capture_output=True)

    if os.path.exists(temp_screenshot):
        img = Image.open(temp_screenshot)
        img.save(output_png_path)
        os.remove(temp_screenshot)
    if os.path.exists(html_file):
        os.remove(html_file)

def generate_all_icons():
    print("Generating master full-bleed & squircle icons...")
    squircle_svg = get_svg(is_maskable=False)
    maskable_svg = get_svg(is_maskable=True)

    with open('owl_app_icon.svg', 'w', encoding='utf-8') as f:
        f.write(squircle_svg)

    render_svg_to_png(squircle_svg, 'master_squircle_1024.png')
    render_svg_to_png(maskable_svg, 'master_full_bleed_1024.png')

    squircle_master = Image.open('master_squircle_1024.png')
    full_bleed_master = Image.open('master_full_bleed_1024.png')

    # 1. Web icons
    print("Generating Web icons...")
    squircle_master.resize((192, 192), Image.Resampling.LANCZOS).save('web/icons/Icon-192.png')
    squircle_master.resize((512, 512), Image.Resampling.LANCZOS).save('web/icons/Icon-512.png')
    full_bleed_master.resize((192, 192), Image.Resampling.LANCZOS).save('web/icons/Icon-maskable-192.png')
    full_bleed_master.resize((512, 512), Image.Resampling.LANCZOS).save('web/icons/Icon-maskable-512.png')
    squircle_master.resize((48, 48), Image.Resampling.LANCZOS).save('web/favicon.png')

    # Root favicon & icons
    squircle_master.resize((48, 48), Image.Resampling.LANCZOS).save('favicon.png')
    if os.path.exists('icons'):
        squircle_master.resize((192, 192), Image.Resampling.LANCZOS).save('icons/Icon-192.png')
        squircle_master.resize((512, 512), Image.Resampling.LANCZOS).save('icons/Icon-512.png')
        full_bleed_master.resize((192, 192), Image.Resampling.LANCZOS).save('icons/Icon-maskable-192.png')
        full_bleed_master.resize((512, 512), Image.Resampling.LANCZOS).save('icons/Icon-maskable-512.png')

    # 2. Android mipmaps
    print("Generating Android icons...")
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    for folder, size in android_sizes.items():
        dir_path = os.path.join('android', 'app', 'src', 'main', 'res', folder)
        if os.path.exists(dir_path):
            squircle_master.resize((size, size), Image.Resampling.LANCZOS).save(os.path.join(dir_path, 'ic_launcher.png'))

    # 3. iOS AppIcon
    print("Generating iOS icons...")
    ios_dir = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(ios_dir):
        ios_files = {
            'Icon-App-1024x1024@1x.png': (1024, full_bleed_master),
            'Icon-App-20x20@1x.png': (20, full_bleed_master),
            'Icon-App-20x20@2x.png': (40, full_bleed_master),
            'Icon-App-20x20@3x.png': (60, full_bleed_master),
            'Icon-App-29x29@1x.png': (29, full_bleed_master),
            'Icon-App-29x29@2x.png': (58, full_bleed_master),
            'Icon-App-29x29@3x.png': (87, full_bleed_master),
            'Icon-App-40x40@1x.png': (40, full_bleed_master),
            'Icon-App-40x40@2x.png': (80, full_bleed_master),
            'Icon-App-40x40@3x.png': (120, full_bleed_master),
            'Icon-App-60x60@2x.png': (120, full_bleed_master),
            'Icon-App-60x60@3x.png': (180, full_bleed_master),
            'Icon-App-76x76@1x.png': (76, full_bleed_master),
            'Icon-App-76x76@2x.png': (152, full_bleed_master),
            'Icon-App-83.5x83.5@2x.png': (167, full_bleed_master),
        }
        for filename, (sz, src) in ios_files.items():
            src.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(ios_dir, filename))

    # 4. macOS AppIcon
    print("Generating macOS icons...")
    macos_dir = os.path.join('macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(macos_dir):
        macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
        for sz in macos_sizes:
            squircle_master.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(macos_dir, f'app_icon_{sz}.png'))

    # 5. Windows app_icon.ico
    print("Generating Windows ICO...")
    win_ico = os.path.join('windows', 'runner', 'resources', 'app_icon.ico')
    if os.path.exists(os.path.dirname(win_ico)):
        squircle_master.save(
            win_ico,
            format='ICO',
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        )

    print("All icons successfully generated across all platforms!")

if __name__ == '__main__':
    generate_all_icons()
