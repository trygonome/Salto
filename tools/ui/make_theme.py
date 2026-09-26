#!/usr/bin/env python3
"""Génère assets/ui/theme.tres, le thème unique de l'interface, avec la palette du prototype
(docs/prototype/salto-rpg.html) : Bungee pour les titres et les boutons forts, Nunito pour le
texte, pastilles violettes translucides, or, rose et cyan.

Usage : python3 tools/ui/make_theme.py (depuis la racine du projet).
"""

subs = []
props = []


def color(r, g, b, a=1.0):
    return "Color(%g, %g, %g, %g)" % (r, g, b, a)


INK = color(1, 0.973, 0.992)
SOFT = color(1, 0.973, 0.992, 0.82)
CHIP = color(0.133, 0.047, 0.227, 0.66)
LINE = color(1, 1, 1, 0.3)
HP = color(1, 0.31, 0.545)
XP = color(0.235, 0.91, 1)
GOLD = color(1, 0.824, 0.247)
PLUM = color(0.165, 0.039, 0.227)
PANEL = color(0.188, 0.063, 0.306, 0.97)
DEEP = color(0.118, 0.031, 0.204, 0.84)
DEEP2 = color(0.118, 0.031, 0.204, 0.92)
DEEP3 = color(0.118, 0.031, 0.204, 0.95)
PINK = color(1, 0.184, 0.706)
BOSS = color(0.69, 0.302, 1)
GREEN = color(0.49, 1, 0.698)
WHITE = color(1, 1, 1)
SHADOW = color(0, 0, 0, 0.6)
CLEAR = color(0, 0, 0, 0)


def box(id, bg, border=None, bw=0, radius=0, pad=(0, 0, 0, 0), shadow=None):
    lines = ['[sub_resource type="StyleBoxFlat" id="%s"]' % id]
    l, t, r, b = pad
    lines += ["content_margin_left = %g" % l, "content_margin_top = %g" % t, "content_margin_right = %g" % r, "content_margin_bottom = %g" % b]
    lines.append("bg_color = %s" % bg)
    if bw:
        lines += ["border_width_left = %d" % bw, "border_width_top = %d" % bw, "border_width_right = %d" % bw, "border_width_bottom = %d" % bw]
        lines.append("border_color = %s" % border)
    if radius:
        lines += ["corner_radius_top_left = %d" % radius, "corner_radius_top_right = %d" % radius,
                  "corner_radius_bottom_right = %d" % radius, "corner_radius_bottom_left = %d" % radius]
        lines.append("corner_detail = 12")
    if shadow:
        lines += ["shadow_color = %s" % shadow[0], "shadow_size = %d" % shadow[1], "shadow_offset = Vector2(0, %d)" % shadow[2]]
    lines.append("anti_aliasing = true")
    subs.append("\n".join(lines))
    return 'SubResource("%s")' % id


subs.append('[sub_resource type="StyleBoxEmpty" id="Empty"]')
EMPTY = 'SubResource("Empty")'

# Boutons.
ghost = box("Ghost", CLEAR, LINE, 2, 26, (20, 12, 20, 12))
ghost_hover = box("GhostHover", color(1, 1, 1, 0.08), GOLD, 2, 26, (20, 12, 20, 12))
ghost_pressed = box("GhostPressed", color(1, 1, 1, 0.16), GOLD, 2, 26, (20, 12, 20, 12))
cta = box("Cta", GOLD, None, 0, 30, (20, 15, 20, 15))
cta_pressed = box("CtaPressed", color(1, 0.9, 0.55), None, 0, 30, (20, 15, 20, 15))
buy = box("Buy", GOLD, None, 0, 20, (12, 9, 12, 9))
buy_pressed = box("BuyPressed", color(1, 0.9, 0.55), None, 0, 20, (12, 9, 12, 9))
buy_disabled = box("BuyDisabled", color(1, 0.824, 0.247, 0.38), None, 0, 20, (12, 9, 12, 9))
small = box("Small", CLEAR, LINE, 2, 20, (12, 9, 12, 9))
small_pressed = box("SmallPressed", color(1, 1, 1, 0.16), GOLD, 2, 20, (12, 9, 12, 9))
tile = box("Tile", PANEL, LINE, 2, 14, (6, 8, 6, 8))
tile_pressed = box("TilePressed", PANEL, GOLD, 2, 14, (6, 8, 6, 8))
tile_selected = box("TileSelected", PANEL, GOLD, 3, 14, (6, 8, 6, 8))
tile_can = box("TileCan", PANEL, GREEN, 3, 14, (6, 8, 6, 8))
icon_button = box("IconButton", CHIP, LINE, 2, 12)
icon_badge = box("IconBadge", CHIP, GOLD, 3, 12, (0, 0, 0, 0), (color(1, 0.824, 0.247, 0.7), 8, 0))

# Panneaux.
panel = box("Panel", PANEL, LINE, 2, 16, (14, 12, 14, 12))
chip = box("Chip", CHIP, LINE, 2, 12, (9, 9, 9, 9))
gold_chip = box("GoldChip", GOLD, None, 0, 12, (10, 9, 10, 9))
quest = box("Quest", DEEP, GOLD, 2, 16, (10, 8, 16, 8), (color(0, 0, 0, 0.3), 12, 4))
quest_flash = box("QuestFlash", DEEP, GOLD, 2, 16, (10, 8, 16, 8), (color(1, 0.824, 0.247, 0.35), 10, 0))
challenge = box("Challenge", CHIP, LINE, 2, 16, (12, 4, 12, 4))
challenge_done = box("ChallengeDone", CHIP, GREEN, 2, 16, (12, 4, 12, 4))
toast = box("Toast", DEEP2, LINE, 2, 14, (16, 10, 16, 10))
coach = box("Coach", WHITE, None, 0, 14, (16, 10, 16, 10), (color(0, 0, 0, 0.35), 16, 6))
bubble = box("Bubble", WHITE, None, 0, 14, (12, 8, 12, 8), (color(0, 0, 0, 0.3), 12, 4))
item_panel = box("ItemPanel", DEEP3, GOLD, 2, 16, (14, 10, 14, 10))
dim = box("Dim", color(0.114, 0.043, 0.2, 0.93))
saga = box("Saga", CHIP, LINE, 2, 16)
saga_done = box("SagaDone", GOLD, WHITE, 2, 16)
saga_current = box("SagaCurrent", CHIP, GOLD, 2, 16, (0, 0, 0, 0), (color(1, 0.824, 0.247, 0.28), 4, 0))
drum_off = box("DrumOff", CLEAR, LINE, 2, 4)
drum_on = box("DrumOn", GOLD, WHITE, 2, 4)
# Barres.
bar_back = box("BarBack", CHIP, LINE, 2, 9)
bar_hp = box("BarHp", HP, None, 0, 9)
bar_xp_back = box("BarXpBack", CHIP, LINE, 1, 4)
bar_xp = box("BarXp", XP, None, 0, 4)
bar_boss = box("BarBoss", BOSS, None, 0, 6)
bar_boss_back = box("BarBossBack", CHIP, LINE, 2, 6)

ext = [
    '[ext_resource type="FontFile" path="res://assets/fonts/Bungee-Regular.ttf" id="1_bungee"]',
    '[ext_resource type="FontFile" path="res://assets/fonts/Nunito-SemiBold.ttf" id="2_semibold"]',
    '[ext_resource type="FontFile" path="res://assets/fonts/Nunito-ExtraBold.ttf" id="3_extrabold"]',
]
BUNGEE = 'ExtResource("1_bungee")'
SEMI = 'ExtResource("2_semibold")'
BOLD = 'ExtResource("3_extrabold")'

P = props.append
P("default_font = %s" % SEMI)
P("default_font_size = 16")


def button(name, base, normal, hover, pressed, disabled, font, size, fg, fg_pressed=None, fg_disabled=None):
    if base:
        P('%s/base_type = &"%s"' % (name, base))
    for state in ("font_color", "font_focus_color", "font_hover_color"):
        P("%s/colors/%s = %s" % (name, state, fg))
    P("%s/colors/font_pressed_color = %s" % (name, fg_pressed or fg))
    P("%s/colors/font_hover_pressed_color = %s" % (name, fg_pressed or fg))
    P("%s/colors/font_disabled_color = %s" % (name, fg_disabled or fg))
    P("%s/fonts/font = %s" % (name, font))
    P("%s/font_sizes/font_size = %d" % (name, size))
    P("%s/styles/focus = %s" % (name, EMPTY))
    P("%s/styles/normal = %s" % (name, normal))
    P("%s/styles/hover = %s" % (name, hover))
    P("%s/styles/pressed = %s" % (name, pressed))
    P("%s/styles/hover_pressed = %s" % (name, pressed))
    P("%s/styles/disabled = %s" % (name, disabled))


button("Button", None, ghost, ghost_hover, ghost_pressed, ghost, BOLD, 16, INK)
button("CtaButton", "Button", cta, cta, cta_pressed, cta, BUNGEE, 20, PLUM)
button("BuyButton", "Button", buy, buy, buy_pressed, buy_disabled, BUNGEE, 13, PLUM, None, color(0.165, 0.039, 0.227, 0.6))
button("SmallButton", "Button", small, small, small_pressed, small, BOLD, 13, INK)
button("TextButton", "Button", EMPTY, EMPTY, EMPTY, EMPTY, SEMI, 14, SOFT, INK)
button("TileButton", "Button", tile, tile, tile_pressed, tile, SEMI, 13, INK)
button("TileSelected", "Button", tile_selected, tile_selected, tile_selected, tile_selected, SEMI, 13, INK)
button("TileCan", "Button", tile_can, tile_can, tile_selected, tile_can, SEMI, 13, INK)
button("IconButton", "Button", icon_button, icon_button, icon_badge, icon_button, BOLD, 16, INK)
button("IconBadge", "Button", icon_badge, icon_badge, icon_badge, icon_badge, BOLD, 16, INK)


def label(name, font, size, fg, shadow=None, offset=(0, 0), outline=0, outline_color=None):
    P('%s/base_type = &"Label"' % name)
    P("%s/fonts/font = %s" % (name, font))
    P("%s/font_sizes/font_size = %d" % (name, size))
    P("%s/colors/font_color = %s" % (name, fg))
    if shadow:
        P("%s/colors/font_shadow_color = %s" % (name, shadow))
        P("%s/constants/shadow_offset_x = %d" % (name, offset[0]))
        P("%s/constants/shadow_offset_y = %d" % (name, offset[1]))
    if outline:
        P("%s/constants/outline_size = %d" % (name, outline))
        P("%s/colors/font_outline_color = %s" % (name, outline_color))


P("Label/colors/font_color = %s" % INK)
label("DisplayTitle", BUNGEE, 110, INK, PINK, (5, 5))
label("ScreenTitle", BUNGEE, 42, INK, PINK, (3, 3))
# Écrans bas (paysage) : titres plus petits, comme dans le prototype.
label("DisplayTitleSmall", BUNGEE, 56, INK, PINK, (4, 4))
label("ScreenTitleSmall", BUNGEE, 30, INK, PINK, (3, 3))
label("SubLabel", SEMI, 17, SOFT)
label("SmallLabel", SEMI, 14, SOFT)
label("TinyLabel", SEMI, 12, SOFT)
label("ChapterLabel", BOLD, 17, INK)
label("GainLabel", BUNGEE, 18, GOLD)
label("LevelChip", BUNGEE, 14, PLUM)
label("BarText", BOLD, 12, INK, SHADOW, (0, 1))
label("QuestTitle", BOLD, 15, INK)
label("QuestSub", SEMI, 13, SOFT)
label("ChallengeLabel", SEMI, 13, INK)
label("ChallengeDoneLabel", SEMI, 13, GREEN)
label("BossName", BUNGEE, 13, INK, SHADOW, (0, 2))
label("ComboNumber", BUNGEE, 32, INK, PINK, (2, 2))
label("ComboHot", BUNGEE, 32, GOLD, PINK, (2, 2))
label("ComboLabel", BUNGEE, 13, INK, PINK, (2, 2))
label("MarkerLabel", BOLD, 12, INK, color(0, 0, 0, 0.9), (0, 1), 4, color(0, 0, 0, 0.5))
label("BannerSmall", BOLD, 13, GOLD, color(0, 0, 0, 0.8), (0, 2), 4, color(0, 0, 0, 0.35))
label("BannerTitle", BUNGEE, 28, INK, PINK, (2, 2))
label("BannerDetail", BOLD, 15, INK, color(0, 0, 0, 0.9), (0, 2), 5, color(0, 0, 0, 0.35))
label("CoachLabel", BOLD, 15, PLUM)
label("ToastLabel", SEMI, 15, INK)
label("BubbleLabel", SEMI, 14, PLUM)
label("PadLarge", BUNGEE, 15, WHITE, color(0, 0, 0, 0.35), (0, 2))
label("PadMedium", BUNGEE, 13, WHITE, color(0, 0, 0, 0.35), (0, 2))
label("PadSmall", BUNGEE, 11, WHITE, color(0, 0, 0, 0.35), (0, 2))
label("StatName", SEMI, 16, SOFT)
label("StatValue", BOLD, 16, INK)
label("BranchTitle", BUNGEE, 13, INK)
label("TileTitle", BOLD, 13, INK)
label("TileSmall", SEMI, 11, SOFT)
label("ItemTitle", BOLD, 16, INK)
label("ItemLine", SEMI, 14, INK)
label("NewTag", BOLD, 10, GOLD)
label("SagaNumber", BUNGEE, 13, INK)
label("SagaNumberDone", BUNGEE, 13, PLUM)
label("CompareUp", SEMI, 14, GREEN)
label("CompareDown", SEMI, 14, color(1, 0.561, 0.682))


def panel_type(name, style):
    P('%s/base_type = &"PanelContainer"' % name)
    P("%s/styles/panel = %s" % (name, style))


P("PanelContainer/styles/panel = %s" % panel)
panel_type("ChipPanel", chip)
panel_type("GoldChip", gold_chip)
panel_type("QuestPanel", quest)
panel_type("QuestFlash", quest_flash)
panel_type("ChallengePanel", challenge)
panel_type("ChallengeDone", challenge_done)
panel_type("ToastPanel", toast)
panel_type("CoachPanel", coach)
panel_type("BubblePanel", bubble)
panel_type("ItemPanel", item_panel)
panel_type("DimPanel", dim)
panel_type("SagaDot", saga)
panel_type("SagaDone", saga_done)
panel_type("SagaCurrent", saga_current)
panel_type("DrumOff", drum_off)
panel_type("DrumOn", drum_on)


def bar(name, back, fill):
    P('%s/base_type = &"ProgressBar"' % name)
    P("%s/styles/background = %s" % (name, back))
    P("%s/styles/fill = %s" % (name, fill))


bar("HpBar", bar_back, bar_hp)
bar("XpBar", bar_xp_back, bar_xp)
bar("BossBar", bar_boss_back, bar_boss)

P("VScrollBar/styles/scroll = %s" % EMPTY)
subs.append('[sub_resource type="StyleBoxFlat" id="Grabber"]\nbg_color = Color(1, 0.824, 0.247, 0.5)\n'
            'corner_radius_top_left = 3\ncorner_radius_top_right = 3\ncorner_radius_bottom_right = 3\ncorner_radius_bottom_left = 3')
for state in ("grabber", "grabber_highlight", "grabber_pressed"):
    P('VScrollBar/styles/%s = SubResource("Grabber")' % state)

text = '[gd_resource type="Theme" load_steps=%d format=3]\n\n' % (len(ext) + len(subs) + 1)
text += "\n".join(ext) + "\n\n" + "\n\n".join(subs) + "\n\n[resource]\n" + "\n".join(props) + "\n"
with open("assets/ui/theme.tres", "w") as out:
    out.write(text)
print("assets/ui/theme.tres : %d styles" % (len(subs) - 1))
