"""
Tommoro Robotics 4th Anniversary Video - Version 3: 감동 반전
ACT 1: Slow, emotional piano intro (0:00-0:20)
ACT 2: Meme explosion with rapid cuts (0:20-0:55)
"""

from moviepy import (
    ImageClip, TextClip, CompositeVideoClip, ColorClip,
    concatenate_videoclips, vfx
)
import os

IMG = "/home/weed/autofree/docs/video-assets/images"
OUT = "/home/weed/autofree/docs/video-assets"
W, H = 1080, 1920  # 9:16 vertical
FPS = 30


def load_img(filename, duration):
    """Load image, resize to fill 9:16 frame, apply slow zoom."""
    path = os.path.join(IMG, filename)
    clip = (
        ImageClip(path, duration=duration)
        .resized(width=W + 100)  # slightly larger for zoom room
    )
    # Center crop to 1080x1920
    clip = clip.cropped(
        x_center=clip.w // 2, y_center=clip.h // 2,
        width=W, height=H
    )
    return clip


def load_img_fit(filename, duration):
    """Load image, fit within frame with black background."""
    path = os.path.join(IMG, filename)
    img = ImageClip(path, duration=duration)

    # Scale to fit within W x H while maintaining aspect ratio
    scale_w = W / img.w
    scale_h = H / img.h
    scale = min(scale_w, scale_h) * 0.85  # 85% of frame

    img = img.resized(scale)

    # Center on black background
    bg = ColorClip(size=(W, H), color=(0, 0, 0), duration=duration)
    return CompositeVideoClip([
        bg,
        img.with_position("center")
    ])


def text_card(text, duration, fontsize=60, color="white", bg_color=(0, 0, 0)):
    """Create a text card with background."""
    bg = ColorClip(size=(W, H), color=bg_color, duration=duration)
    txt = TextClip(
        text=text,
        font_size=fontsize,
        color=color,
        font="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        text_align="center",
        size=(W - 100, None),
        method="caption",
        duration=duration,
    )
    return CompositeVideoClip([bg, txt.with_position("center")])


def add_overlay_text(clip, text, fontsize=48, position=("center", 0.82)):
    """Add text overlay on bottom of clip."""
    txt = TextClip(
        text=text,
        font_size=fontsize,
        color="white",
        font="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        text_align="center",
        size=(W - 80, None),
        method="caption",
        stroke_color="black",
        stroke_width=3,
        duration=clip.duration,
    )
    return CompositeVideoClip([clip, txt.with_position(position)])


def black_screen(duration):
    return ColorClip(size=(W, H), color=(0, 0, 0), duration=duration)


def glitch_flash(duration=0.3):
    """Simulate glitch with rapid color flash."""
    clips = []
    colors = [(255, 0, 80), (0, 255, 200), (255, 255, 0), (255, 255, 255)]
    per = duration / len(colors)
    for c in colors:
        clips.append(ColorClip(size=(W, H), color=c, duration=per))
    return concatenate_videoclips(clips)


# ============================================================
# ACT 1: Emotional intro (0:00 - ~20s)
# ============================================================
print("Building ACT 1...")

act1_clips = []

# Cut 1: Black screen with "2022년 봄..."
cut1 = text_card("2022년 봄,\n작은 연구실에서", 4, fontsize=56, color="#cccccc")
act1_clips.append(cut1)

# Cut 2: Early days - CEO photo (used as research lab feel)
cut2 = load_img_fit("07_ceo_photo3.jpg", 3)
cut2 = add_overlay_text(cut2, "로봇에게 말을 가르치겠다는")
act1_clips.append(cut2)

# Cut 3: CLIP-RT tech diagram (early research)
cut3 = load_img_fit("03_cliprt_tech.jpg", 4)
cut3 = add_overlay_text(cut3, "조금은 무모한 꿈을\n꾸었습니다")
act1_clips.append(cut3)

# Cut 4: CEO portrait
cut4 = load_img_fit("05_ceo_photo1.jpg", 3)
cut4 = add_overlay_text(cut4, "그리고 4년이 지났습니다")
act1_clips.append(cut4)

# Cut 5: Pause - team/office
cut5 = load_img_fit("06_ceo_photo2.jpg", 3)
act1_clips.append(cut5)

# Cut 6: Fade to black
cut6 = black_screen(0.5)
act1_clips.append(cut6)

# Apply fade transitions to ACT 1
for i, clip in enumerate(act1_clips):
    if i < len(act1_clips) - 1:  # Don't fade the final black
        act1_clips[i] = clip.with_effects([vfx.CrossFadeIn(0.5)])

act1 = concatenate_videoclips(act1_clips, method="compose")

# ============================================================
# TRANSITION: Glitch flash
# ============================================================
print("Building transition...")
transition = glitch_flash(0.4)

# ============================================================
# ACT 2: Meme explosion (~0:20 - ~0:55)
# ============================================================
print("Building ACT 2...")

act2_clips = []

# Cut 7: MEME DROP
cut7 = text_card(
    "쌰갈 여러분\n저희 됐어요\n됐다고요!!",
    3, fontsize=72, color="#FF1744", bg_color=(0, 0, 0)
)
act2_clips.append(cut7)

# Cut 8: CLIP-RT
cut8 = load_img_fit("03_cliprt_tech.jpg", 2)
cut8 = add_overlay_text(cut8, "로봇 AI 모델 됐고요", fontsize=52)
act2_clips.append(cut8)

# Cut 9: RSS 2025 - reuse CEO context photo
cut9 = load_img_fit("08_habilis_photo4.png", 2)
cut9 = add_overlay_text(cut9, "세계 학회 됐고요", fontsize=52)
act2_clips.append(cut9)

# Cut 10: CES demo
cut10 = load_img_fit("01_ces_picking.jpg", 2)
cut10 = add_overlay_text(cut10, "라스베가스에서\n데모 됐고요", fontsize=52)
act2_clips.append(cut10)

# Cut 11: Habilis Brain
cut11 = load_img_fit("04_habilis_product.png", 2)
cut11 = add_overlay_text(cut11, "브레인 됐고요", fontsize=52)
act2_clips.append(cut11)

# Cut 12: Console (use habilis photo5 as proxy)
cut12 = load_img_fit("09_habilis_photo5.png", 2)
cut12 = add_overlay_text(cut12, "콘솔 됐고요", fontsize=52)
act2_clips.append(cut12)

# Cut 13: Habilis-β (CES picking as proxy for packing demo)
cut13 = load_img_fit("01_ces_picking.jpg", 2)
cut13 = add_overlay_text(cut13, "1시간 572번 됐고요", fontsize=52)
act2_clips.append(cut13)

# Cut 14: WUJI Hand
cut14 = load_img_fit("02_ces_hand.jpg", 2)
cut14 = add_overlay_text(cut14, "손가락 20개 다\n움직이는 손 됐고요", fontsize=48)
act2_clips.append(cut14)

# Cut 15: Investment + MOU
cut15 = load_img_fit("06_ceo_photo2.jpg", 2)
cut15 = add_overlay_text(cut15, "투자 됐고요\nMOU 됐고요", fontsize=52)
act2_clips.append(cut15)

# Cut 16: Pasto PoC
cut16 = load_img_fit("01_ces_picking.jpg", 2)
cut16 = add_overlay_text(cut16, "실전 배치 됐고요", fontsize=52)
act2_clips.append(cut16)

# Cut 17: "이 모든 걸..." pause
cut17 = text_card("이 모든 걸...", 2, fontsize=64, color="#FFFFFF")
act2_clips.append(cut17)

# Cut 18: FINALE
cut18 = text_card(
    "4년 만에\n다 했다고요!!!\n🎂",
    4, fontsize=80, color="#FFD700", bg_color=(180, 0, 40)
)
act2_clips.append(cut18)

# Cut 19: Ending card with logo
cut19_bg = ColorClip(size=(W, H), color=(0, 0, 0), duration=4)
logo = (
    ImageClip(os.path.join(IMG, "10_tommoro_logo.png"), duration=4)
    .resized(width=400)
)
end_text = TextClip(
    text="투모로 로보틱스\n창립 4주년 축하합니다\n\n2022.04 → 2026.04",
    font_size=44,
    color="white",
    font="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    text_align="center",
    size=(W - 80, None),
    method="caption",
    duration=4,
)
cut19 = CompositeVideoClip([
    cut19_bg,
    logo.with_position(("center", 0.3)),
    end_text.with_position(("center", 0.55)),
])
act2_clips.append(cut19)

act2 = concatenate_videoclips(act2_clips, method="compose")

# ============================================================
# COMBINE ALL
# ============================================================
print("Combining all clips...")
final = concatenate_videoclips([act1, transition, act2], method="compose")

output_path = os.path.join(OUT, "tommoro_4th_anniversary_v3.mp4")
print(f"Rendering to {output_path}...")
print(f"Total duration: {final.duration:.1f}s")

final.write_videofile(
    output_path,
    fps=FPS,
    codec="libx264",
    audio=False,  # No audio for now
    preset="medium",
    threads=4,
)

print(f"\nDone! Video saved to: {output_path}")
