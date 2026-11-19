from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
W, H = 1206, 2622
BG = (14, 18, 16)
SURFACE = (28, 36, 32)
INK = (244, 241, 234)
MUTED = (168, 176, 168)
GREEN = (47, 143, 98)
GOLD = (226, 177, 90)
EMBER = (225, 90, 58)
LINE = (255, 255, 255, 28)
REGULAR = r"C:\Windows\Fonts\segoeui.ttf"
BOLD = r"C:\Windows\Fonts\segoeuib.ttf"


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else REGULAR, size)


def rounded(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def canvas():
    image = Image.new("RGB", (W, H), BG)
    return image, ImageDraw.Draw(image)


def status(draw):
    draw.text((56, 48), "9:41", font=font(34, True), fill=INK)
    draw.text((1040, 48), "5G", font=font(28, True), fill=INK)


def tabs(draw, selected):
    labels = [("Calendar", 0), ("Topics", 1), ("Athlete", 2)]
    y = 2460
    draw.rectangle((0, 2380, W, H), fill=(18, 24, 21))
    for name, index in labels:
        color = GREEN if index == selected else MUTED
        x = 120 + index * 380
        draw.text((x, y), name, font=font(32, True), fill=color)


def header(draw, eyebrow, title):
    draw.text((56, 130), eyebrow, font=font(28, True), fill=GREEN)
    draw.text((56, 180), title, font=font(64, True), fill=INK)


def chip_row(draw, y, items, selected):
    x = 56
    for item in items:
        on = item == selected
        tw = draw.textbbox((0, 0), item, font=font(30, True))[2]
        width = tw + 56
        rounded(draw, (x, y, x + width, y + 72), 36, GREEN if on else SURFACE)
        draw.text((x + 28, y + 16), item, font=font(30, True), fill=(255, 255, 255) if on else INK)
        x += width + 18


def screen_day():
    image, draw = canvas()
    status(draw)
    header(draw, "TATAMI DAY", "Tuesday 17 November")
    draw.text((56, 280), "40m done  ·  3h 20m planned", font=font(30), fill=MUTED)
    colors = [(232, 122, 46), (194, 59, 46), (226, 177, 90), (47, 143, 98)]
    x = 56
    for color in colors:
        rounded(draw, (x, 340, x + 250, 356), 8, color)
        x += 262
    days = [("M", "16"), ("T", "17"), ("W", "18"), ("T", "19"), ("F", "20"), ("S", "21"), ("S", "22")]
    for index, (name, num) in enumerate(days):
        x = 48 + index * 164
        if num == "17":
            rounded(draw, (x, 400, x + 140, 540), 28, GREEN)
            fill = (255, 255, 255)
        else:
            fill = INK
        draw.text((x + 48, 420), name, font=font(26, True), fill=fill)
        draw.text((x + 40, 468), num, font=font(34, True), fill=fill)
    chip_row(draw, 580, ["60", "30", "15", "10"], "15")
    sessions = [
        (700, "06:30", "Easy run", "06:30–07:10", (232, 122, 46), False),
        (920, "18:00", "Uchikomi", "18:00–18:45", (194, 59, 46), False),
        (1140, "18:45", "Randori", "18:45–19:30", (140, 47, 57), False),
        (1360, "19:30", "Hips", "19:30–19:50", (122, 111, 240), True),
    ]
    for y, hour, title, when, color, mark in sessions:
        draw.text((48, y), hour, font=font(26), fill=MUTED)
        rounded(draw, (190, y - 10, 1140, y + 150), 28, SURFACE)
        draw.rectangle((190, y + 16, 202, y + 124), fill=color)
        draw.text((230, y + 18), title, font=font(40, True), fill=INK)
        draw.text((230, y + 78), when, font=font(30), fill=MUTED)
        if mark:
            rounded(draw, (820, y + 40, 1100, y + 112), 28, (0, 0, 0))
            draw.text((850, y + 54), "Mark done", font=font(28, True), fill=EMBER)
    tabs(draw, 0)
    return image


def screen_week():
    image, draw = canvas()
    status(draw)
    header(draw, "TATAMI DAY", "16–22 November")
    chip_row(draw, 320, ["Day", "Week", "Month"], "Week")
    names = ["M", "T", "W", "T", "F", "S", "S"]
    for index, name in enumerate(names):
        x = 70 + index * 160
        draw.text((x, 450), name, font=font(28, True), fill=GREEN if index == 1 else MUTED)
    blocks = [
        (0, 560, 180, (232, 122, 46)),
        (0, 1100, 220, (194, 59, 46)),
        (1, 620, 160, (62, 111, 216)),
        (1, 1120, 260, (163, 59, 74)),
        (2, 560, 140, (47, 143, 98)),
        (2, 1080, 300, (224, 122, 47)),
        (3, 600, 150, (232, 122, 46)),
        (3, 1100, 280, (194, 59, 46)),
        (4, 640, 180, (62, 111, 216)),
        (4, 1180, 160, (196, 92, 38)),
        (5, 780, 340, (194, 59, 46)),
        (6, 700, 180, (47, 143, 98)),
        (6, 980, 160, (58, 175, 169)),
    ]
    for col, y, h, color in blocks:
        x = 48 + col * 164
        rounded(draw, (x, y, x + 146, y + h), 16, color)
    tabs(draw, 0)
    return image


def screen_month():
    image, draw = canvas()
    status(draw)
    header(draw, "TATAMI DAY", "November 2026")
    chip_row(draw, 320, ["Day", "Week", "Month"], "Month")
    labels = ["S", "M", "T", "W", "T", "F", "S"]
    for index, label in enumerate(labels):
        draw.text((70 + index * 164, 470), label, font=font(26, True), fill=MUTED)
    colors = [(194, 59, 46), (232, 122, 46), (47, 143, 98), (62, 111, 216)]
    for row in range(5):
        for col in range(7):
            day = row * 7 + col - 1
            x = 40 + col * 164
            y = 540 + row * 340
            if day == 17:
                rounded(draw, (x, y, x + 148, y + 310), 24, (32, 70, 52))
            else:
                rounded(draw, (x, y, x + 148, y + 310), 24, SURFACE)
            if 1 <= day <= 30:
                draw.text((x + 16, y + 16), str(day), font=font(32, True), fill=INK)
                for bar in range(3):
                    rounded(draw, (x + 16, y + 90 + bar * 28, x + 130, y + 108 + bar * 28), 6, colors[(day + bar) % 4])
    tabs(draw, 0)
    return image


def screen_topics():
    image, draw = canvas()
    status(draw)
    header(draw, "LIBRARY", "Topics")
    chip_row(draw, 340, ["All", "Combat", "Endurance", "Strength"], "Combat")
    rows = [
        ("Judo", "Uchikomi, kata, grip fighting", (194, 59, 46)),
        ("Randori", "Standing and ground rounds", (140, 47, 57)),
        ("Newaza", "Turnovers, pins, escapes", (163, 59, 74)),
        ("Technique", "Throws, combinations", (224, 122, 47)),
        ("Competition", "Match prep and review", (226, 177, 90)),
        ("Sparring", "Light and hard rounds", (212, 83, 126)),
    ]
    y = 480
    for name, detail, color in rows:
        rounded(draw, (48, y, 1158, y + 210), 32, SURFACE)
        draw.ellipse((84, y + 58, 164, y + 138), fill=color)
        draw.text((200, y + 48), name, font=font(44, True), fill=INK)
        draw.text((200, y + 114), detail, font=font(30), fill=MUTED)
        y += 236
    tabs(draw, 1)
    return image


def screen_done():
    image, draw = canvas()
    status(draw)
    header(draw, "TATAMI DAY", "Tuesday 17 November")
    rounded(draw, (48, 420, 1158, 760), 32, SURFACE)
    draw.rectangle((48, 470, 64, 710), fill=(140, 47, 57))
    draw.text((100, 480), "Randori", font=font(48, True), fill=INK)
    draw.text((100, 560), "Standing randori", font=font(32), fill=MUTED)
    draw.text((100, 630), "18:45–19:30  ·  Dojo", font=font(32), fill=MUTED)
    rounded(draw, (48, 860, 1158, 2480), 40, (22, 28, 25))
    draw.text((96, 940), "Close the session", font=font(52, True), fill=INK)
    draw.text((96, 1040), "This stays open until you mark it done.", font=font(32), fill=MUTED)
    rounded(draw, (96, 1180, 1110, 1320), 32, GREEN)
    label = "Mark done"
    box = draw.textbbox((0, 0), label, font=font(40, True))
    draw.text(((1206 - (box[2] - box[0])) // 2, 1218), label, font=font(40, True), fill=(255, 255, 255))
    draw.text((430, 1400), "Remind me later", font=font(32, True), fill=MUTED)
    return image


def screen_editor():
    image, draw = canvas()
    status(draw)
    draw.text((56, 140), "Cancel", font=font(34), fill=GREEN)
    draw.text((470, 140), "New session", font=font(36, True), fill=INK)
    draw.text((1040, 140), "Save", font=font(34, True), fill=GREEN)
    fields = [
        (260, "Title", "Randori"),
        (460, "Starts", "Tue 17 Nov, 18:45"),
        (660, "Duration", "45m"),
        (860, "Place", "Dojo"),
        (1060, "Remind me", "15 min before"),
    ]
    for y, label, value in fields:
        draw.text((56, y), label, font=font(28), fill=MUTED)
        rounded(draw, (56, y + 50, 1150, y + 160), 24, SURFACE)
        draw.text((88, y + 78), value, font=font(36, True), fill=INK)
    draw.text((56, 1320), "Topic", font=font(28), fill=MUTED)
    chip_row(draw, 1380, ["Judo", "Randori", "Run", "Strength"], "Randori")
    rounded(draw, (56, 1560, 1150, 1760), 24, SURFACE)
    draw.text((88, 1620), "Require mark as done", font=font(36, True), fill=INK)
    rounded(draw, (960, 1610, 1080, 1690), 40, GREEN)
    draw.ellipse((1010, 1618, 1072, 1680), fill=(255, 255, 255))
    return image


def screen_divide():
    image, draw = canvas()
    status(draw)
    draw.text((56, 140), "Cancel", font=font(34), fill=GREEN)
    draw.text((400, 140), "Divide the hour", font=font(36, True), fill=INK)
    draw.text((1040, 140), "Add", font=font(34, True), fill=GREEN)
    draw.text((56, 260), "18:00", font=font(72, True), fill=INK)
    draw.text((56, 360), "Four blocks, 15 minutes each.", font=font(32), fill=MUTED)
    slots = [("18:00", "Uchikomi"), ("18:15", "Grip fighting"), ("18:30", "Nagekomi"), ("18:45", "Randori")]
    y = 480
    for when, title in slots:
        rounded(draw, (56, y, 1150, y + 220), 28, SURFACE)
        draw.rectangle((56, y + 30, 72, y + 190), fill=(194, 59, 46))
        draw.text((110, y + 40), when, font=font(30), fill=MUTED)
        draw.text((110, y + 100), title, font=font(44, True), fill=INK)
        y += 250
    return image


def screen_athlete():
    image, draw = canvas()
    status(draw)
    header(draw, "THIS WEEK", "Idan")
    stats = [("6d", "Streak"), ("4h 20m", "Done"), ("2", "Open")]
    for index, (value, label) in enumerate(stats):
        x = 48 + index * 380
        rounded(draw, (x, 340, x + 350, 560), 28, SURFACE)
        draw.text((x + 28, 380), value, font=font(48, True), fill=INK)
        draw.text((x + 28, 460), label, font=font(30), fill=MUTED)
    draw.text((56, 620), "Completed minutes", font=font(32, True), fill=INK)
    heights = [80, 160, 120, 220, 140, 260, 90]
    labels = ["M", "T", "W", "T", "F", "S", "S"]
    for index, (height, label) in enumerate(zip(heights, labels)):
        x = 80 + index * 156
        color = GOLD if index == 1 else GREEN
        rounded(draw, (x, 1100 - height * 2, x + 90, 1100), 16, color)
        draw.text((x + 24, 1130), label, font=font(28, True), fill=MUTED)
    rows = [("Judo", "2h 15m", (194, 59, 46)), ("Run", "1h 15m", (232, 122, 46)), ("Strength", "50m", (62, 111, 216))]
    y = 1260
    for name, minutes, color in rows:
        draw.ellipse((70, y + 10, 110, y + 50), fill=color)
        draw.text((140, y), name, font=font(36, True), fill=INK)
        draw.text((900, y), minutes, font=font(36), fill=MUTED)
        y += 110
    tabs(draw, 2)
    return image


def screen_signin():
    image, draw = canvas()
    draw.rectangle((0, 0, W, 900), fill=(24, 70, 50))
    rounded(draw, (80, 220, 280, 420), 48, (18, 56, 42))
    for index, color in enumerate(((244, 236, 214), GOLD, (46, 158, 107))):
        y = 270 + index * 46
        rounded(draw, (116, y, 244, y + 28), 14, color)
    draw.text((72, 980), "TATAMI DAY", font=font(32, True), fill=GREEN)
    draw.text((72, 1060), "The private", font=font(84, True), fill=INK)
    draw.text((72, 1170), "training day.", font=font(84, True), fill=INK)
    body = "Every hour on the clock. Judo, running, lifting, recovery."
    draw.text((72, 1320), body, font=font(36), fill=MUTED)
    rounded(draw, (72, 1600, 1134, 1740), 28, (255, 255, 255))
    label = "Sign in with Apple"
    box = draw.textbbox((0, 0), label, font=font(40, True))
    draw.text(((W - (box[2] - box[0])) // 2, 1640), label, font=font(40, True), fill=(0, 0, 0))
    note = "Opens only for the registered Apple ID."
    draw.text((72, 1800), note, font=font(32), fill=MUTED)
    return image


def screen_overdue():
    image, draw = canvas()
    status(draw)
    header(draw, "STILL OPEN", "Mark done")
    draw.text((56, 320), "Each one stays open until you mark it done.", font=font(32), fill=MUTED)
    rows = [
        ("Easy run", "06:30–07:10", (232, 122, 46)),
        ("Uchikomi", "18:00–18:45", (194, 59, 46)),
        ("Randori", "18:45–19:30", (140, 47, 57)),
    ]
    y = 460
    for title, when, color in rows:
        rounded(draw, (48, y, 1158, y + 360), 32, SURFACE)
        draw.rectangle((48, y + 36, 64, y + 180), fill=color)
        draw.text((100, y + 40), title, font=font(48, True), fill=INK)
        draw.text((100, y + 120), when, font=font(32), fill=MUTED)
        rounded(draw, (100, y + 210, 460, y + 300), 28, GREEN)
        draw.text((160, y + 232), "Mark done", font=font(32, True), fill=(255, 255, 255))
        y += 400
    tabs(draw, 0)
    return image


def main():
    screens = [
        ("01-day", screen_day),
        ("02-week", screen_week),
        ("03-month", screen_month),
        ("04-topics", screen_topics),
        ("05-mark-done", screen_done),
        ("06-new-session", screen_editor),
        ("07-divide-hour", screen_divide),
        ("08-athlete", screen_athlete),
        ("09-sign-in", screen_signin),
        ("10-still-open", screen_overdue),
    ]
    for name, builder in screens:
        image = builder()
        if image.size != (W, H):
            raise SystemExit(f"{name} is {image.size}")
        path = OUT / f"{name}-1206x2622.jpg"
        image.save(path, "JPEG", quality=95, subsampling=0)
        print(path.name, image.size)


if __name__ == "__main__":
    main()
