#!/usr/bin/env python3
"""Génère assets/ui/theme.tres, le thème unique de l'interface, avec la palette du prototype
(docs/prototype/salto-rpg.html) : Bungee pour les titres et les boutons forts, Nunito pour le
texte, pastilles violettes translucides, or, rose et cyan (le jeu).
Écrans (version 2.2) : bois sculpté en cubes (VoxelBox, scripts/ui/voxel_box.gd), planches
dorées pour l'action principale, peaux de tambour lacées pour les cartes, bandeau tissé aux
couleurs de la jungle, fond de feuilles en cubes (ScreenBackdrop).

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


# Bois, or, peau de tambour, tissage (écrans).
WOOD = color(0.353, 0.224, 0.141)
WOOD_GRAIN = color(0.302, 0.188, 0.118)
WOOD_LIGHT = color(0.522, 0.345, 0.22)
WOOD_DARK = color(0.231, 0.141, 0.086)
WOOD_RIM = color(0.098, 0.051, 0.035)
WOOD_DEEP = color(0.192, 0.118, 0.075)
WOOD_PRESSED = color(0.302, 0.192, 0.118)
GOLD_LIGHT = color(1, 0.953, 0.678)
GOLD_DARK = color(0.851, 0.565, 0.125)
GOLD_GRAIN = color(0.965, 0.749, 0.2)
GOLD_PRESSED = color(0.94, 0.75, 0.2)
SKIN = color(0.961, 0.902, 0.769)
SKIN_LIGHT = color(1, 0.98, 0.93)
SKIN_DARK = color(0.851, 0.745, 0.557)
SKIN_PRESSED = color(0.925, 0.851, 0.69)
SKIN_OFF = color(0.745, 0.71, 0.643)
LACE = color(0.722, 0.271, 0.192)
LACE_OFF = color(0.545, 0.463, 0.42)
CYAN = color(0.235, 0.91, 1)
DROP = color(0, 0, 0, 0.42)
CARD_INK = color(0.2, 0.078, 0.141)
CARD_SOFT = color(0.357, 0.235, 0.259)
CARD_TAG = color(0.776, 0.137, 0.459)
BAND = [PINK, GOLD, CYAN, GREEN]
BLOCK = 3

subs.append('[sub_resource type="StyleBoxEmpty" id="Empty"]')
EMPTY = 'SubResource("Empty")'


def vbox(id, fill, rim, light, dark, pad, corner=1, shadow=DROP, sink=0, grain=None, band=None, lacing=None, studs=None):
    """Cadre en cubes (VoxelBox) : voir scripts/ui/voxel_box.gd."""
    lines = ['[sub_resource type="StyleBox" id="%s"]' % id, 'script = ExtResource("4_voxel")']
    l, t, r, b = pad
    lines += ["content_margin_left = %g" % l, "content_margin_top = %g" % t, "content_margin_right = %g" % r, "content_margin_bottom = %g" % b]
    lines += ["block = %g" % BLOCK, "corner = %d" % corner, "fill = %s" % fill, "rim = %s" % rim, "light = %s" % light, "dark = %s" % dark]
    if shadow:
        lines += ["shadow = %s" % shadow, "shadow_blocks = 1"]
    if sink:
        lines.append("sink = %d" % sink)
    if grain:
        lines.append("grain = %s" % grain)
    if band:
        lines.append("band_colors = PackedColorArray(%s)" % ", ".join(c[len("Color("):-1] for c in band))
    if lacing:
        lines.append("lacing = %s" % lacing)
    if studs:
        lines.append("studs = %s" % studs)
    subs.append("\n".join(lines))
    return 'SubResource("%s")' % id


def pressed_pad(pad):
    """Enfoncé : le contenu descend d'un cube avec le cadre."""
    l, t, r, b = pad
    return (l, t + BLOCK, r, b - BLOCK)

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
icon_button = None
icon_badge = None

# Écrans : planches de bois, planche dorée, tuiles, peaux de tambour, panneaux.
PLANK_PAD = (18, 12, 18, 14)
plank = vbox("Plank", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, PLANK_PAD, grain=WOOD_GRAIN)
plank_pressed = vbox("PlankPressed", WOOD_PRESSED, WOOD_RIM, WOOD_DARK, WOOD_LIGHT, pressed_pad(PLANK_PAD), shadow=None, sink=1, grain=WOOD_GRAIN)
plank_off = vbox("PlankOff", WOOD_DEEP, WOOD_RIM, WOOD_DARK, WOOD_DARK, PLANK_PAD)
GOLD_PAD = (20, 15, 20, 17)
gold_plank = vbox("GoldPlank", GOLD, WOOD_RIM, GOLD_LIGHT, GOLD_DARK, GOLD_PAD, grain=GOLD_GRAIN, studs=WOOD_DARK)
gold_plank_pressed = vbox("GoldPlankPressed", GOLD_PRESSED, WOOD_RIM, GOLD_DARK, GOLD_LIGHT, pressed_pad(GOLD_PAD), shadow=None, sink=1, grain=GOLD_GRAIN, studs=WOOD_DARK)
SMALL_PAD = (13, 9, 13, 11)
small_plank = vbox("SmallPlank", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, SMALL_PAD)
small_plank_pressed = vbox("SmallPlankPressed", WOOD_PRESSED, WOOD_RIM, WOOD_DARK, WOOD_LIGHT, pressed_pad(SMALL_PAD), shadow=None, sink=1)
small_gold = vbox("SmallGold", GOLD, WOOD_RIM, GOLD_LIGHT, GOLD_DARK, SMALL_PAD)
small_gold_pressed = vbox("SmallGoldPressed", GOLD_PRESSED, WOOD_RIM, GOLD_DARK, GOLD_LIGHT, pressed_pad(SMALL_PAD), shadow=None, sink=1)
small_gold_off = vbox("SmallGoldOff", color(0.6, 0.5, 0.3), WOOD_RIM, color(0.68, 0.58, 0.36), color(0.5, 0.4, 0.24), SMALL_PAD)
TILE_PAD = (10, 11, 10, 12)
wood_tile = vbox("WoodTile", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, TILE_PAD)
wood_tile_pressed = vbox("WoodTilePressed", WOOD_PRESSED, WOOD_RIM, WOOD_DARK, WOOD_LIGHT, pressed_pad(TILE_PAD), shadow=None, sink=1)
wood_tile_selected = vbox("WoodTileSelected", WOOD, GOLD, GOLD_LIGHT, GOLD_DARK, TILE_PAD)
wood_tile_can = vbox("WoodTileCan", WOOD, GREEN, color(0.7, 1, 0.82), color(0.2, 0.62, 0.38), TILE_PAD)
CARD_PAD = (18, 22, 18, 22)
drum_card = vbox("DrumCard", SKIN, WOOD_RIM, SKIN_LIGHT, SKIN_DARK, CARD_PAD, lacing=LACE)
drum_card_pressed = vbox("DrumCardPressed", SKIN_PRESSED, WOOD_RIM, SKIN_DARK, SKIN_LIGHT, pressed_pad(CARD_PAD), shadow=None, sink=1, lacing=LACE)
drum_card_off = vbox("DrumCardOff", SKIN_OFF, WOOD_RIM, SKIN_OFF, SKIN_DARK, CARD_PAD, lacing=LACE_OFF)
wood_panel = vbox("WoodPanel", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, (18, 16, 18, 16), corner=2, grain=WOOD_GRAIN, studs=GOLD)
page_panel = vbox("PagePanel", SKIN, WOOD_RIM, SKIN_LIGHT, SKIN_DARK, (18, 14, 18, 16), band=BAND)
slot_panel = vbox("SlotPanel", WOOD_DEEP, WOOD_RIM, WOOD_DARK, WOOD, (18, 12, 18, 12), shadow=None)

# Panneaux.
panel = box("Panel", PANEL, LINE, 2, 16, (14, 12, 14, 12))
chip = box("Chip", CHIP, LINE, 2, 12, (9, 9, 9, 9))
gold_chip = box("GoldChip", GOLD, None, 0, 12, (10, 9, 10, 9))
# HUD : petites plaques de bois (l'objectif s'éclaire d'or quand il change).
quest = vbox("Quest", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, (12, 9, 16, 10))
quest_flash = vbox("QuestFlash", WOOD, GOLD, GOLD_LIGHT, GOLD_DARK, (12, 9, 16, 10))
toast = vbox("Toast", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, (16, 10, 16, 12))
icon_button = vbox("IconButton", WOOD, WOOD_RIM, WOOD_LIGHT, WOOD_DARK, (0, 0, 0, 0))
icon_badge = vbox("IconBadge", WOOD, GOLD, GOLD_LIGHT, GOLD_DARK, (0, 0, 0, 0))
coach = box("Coach", WHITE, None, 0, 14, (16, 10, 16, 10), (color(0, 0, 0, 0.35), 16, 6))
bubble = box("Bubble", WHITE, None, 0, 14, (12, 8, 12, 8), (color(0, 0, 0, 0.3), 12, 4))
item_panel = wood_panel
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
    '[ext_resource type="Script" path="res://scripts/ui/voxel_box.gd" id="4_voxel"]',
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


button("Button", None, plank, plank, plank_pressed, plank_off, BOLD, 16, INK, None, SOFT)
button("CtaButton", "Button", gold_plank, gold_plank, gold_plank_pressed, gold_plank, BUNGEE, 20, PLUM)
button("BuyButton", "Button", small_gold, small_gold, small_gold_pressed, small_gold_off, BUNGEE, 13, PLUM, None, color(0.165, 0.039, 0.227, 0.6))
button("SmallButton", "Button", small_plank, small_plank, small_plank_pressed, small_plank, BOLD, 13, INK)
button("TextButton", "Button", EMPTY, EMPTY, EMPTY, EMPTY, SEMI, 14, SOFT, INK)
button("TileButton", "Button", wood_tile, wood_tile, wood_tile_pressed, wood_tile, SEMI, 13, INK)
button("TileSelected", "Button", wood_tile_selected, wood_tile_selected, wood_tile_pressed, wood_tile_selected, SEMI, 13, INK)
button("TileCan", "Button", wood_tile_can, wood_tile_can, wood_tile_pressed, wood_tile_can, SEMI, 13, INK)
button("DrumCard", "Button", drum_card, drum_card, drum_card_pressed, drum_card_off, SEMI, 13, CARD_INK)
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
label("DisplayTitle", BUNGEE, 110, INK, PINK, (5, 5), 14, WOOD_RIM)
label("ScreenTitle", BUNGEE, 42, INK, PINK, (3, 3), 9, WOOD_RIM)
# Écrans bas (paysage) : titres plus petits, comme dans le prototype.
label("DisplayTitleSmall", BUNGEE, 56, INK, PINK, (4, 4), 10, WOOD_RIM)
label("ScreenTitleSmall", BUNGEE, 30, INK, PINK, (3, 3), 7, WOOD_RIM)
label("SubLabel", SEMI, 17, SOFT)
label("SmallLabel", SEMI, 14, SOFT)
label("TinyLabel", SEMI, 12, SOFT)
label("ChapterLabel", BOLD, 17, INK)
label("GainLabel", BUNGEE, 18, GOLD)
label("LevelChip", BUNGEE, 14, PLUM)
label("BarText", BOLD, 12, INK, SHADOW, (0, 1))
label("QuestTitle", BOLD, 15, INK)
label("QuestSub", SEMI, 13, SOFT)
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
# Sur une peau de tambour ou une page (clair) : encre sombre.
label("CardTitle", BUNGEE, 16, CARD_INK)
label("CardTag", BOLD, 11, CARD_TAG)
label("CardLine", SEMI, 14, CARD_SOFT)
label("PageTitle", BUNGEE, 14, CARD_INK)
label("PageLine", SEMI, 14, CARD_INK)


def panel_type(name, style):
    P('%s/base_type = &"PanelContainer"' % name)
    P("%s/styles/panel = %s" % (name, style))


P("PanelContainer/styles/panel = %s" % panel)
panel_type("ChipPanel", chip)
panel_type("GoldChip", gold_chip)
panel_type("QuestPanel", quest)
panel_type("QuestFlash", quest_flash)
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
panel_type("WoodPanel", wood_panel)
panel_type("PagePanel", page_panel)
panel_type("SlotPanel", slot_panel)


def colors(name, entries):
    for key, value in entries:
        P("%s/colors/%s = %s" % (name, key, value))


def constants(name, entries):
    for key, value in entries:
        P("%s/constants/%s = %d" % (name, key, value))


# Fond des écrans (jeu flou et teinté, feuilles, cubes qui montent) ; l'écran titre montre le camp.
LEAVES = [("leaf_dark", color(0.043, 0.157, 0.098)), ("leaf_mid", color(0.09, 0.29, 0.165)),
          ("leaf_light", color(0.176, 0.455, 0.235)), ("leaf_vein", color(0.035, 0.118, 0.075))]
MOTES = [("mote_%d" % i, c) for i, c in enumerate([color(1, 0.184, 0.706, 0.8), color(1, 0.824, 0.247, 0.8),
                                                   color(0.235, 0.91, 1, 0.8), color(0.49, 1, 0.698, 0.8), color(0.69, 0.302, 1, 0.8)])]
colors("ScreenBackdrop", [("tint", color(0.035, 0.078, 0.063, 0.8)), ("edge", color(0.012, 0.031, 0.024, 0.75))] + LEAVES + MOTES)
constants("ScreenBackdrop", [("block", 4), ("blur", 3), ("motes", 14)])
P('TitleBackdrop/base_type = &"ScreenBackdrop"')
colors("TitleBackdrop", [("tint", CLEAR), ("edge", CLEAR)] + LEAVES + MOTES)
constants("TitleBackdrop", [("block", 4), ("blur", 0), ("motes", 10)])
# Bandeau tissé sous les titres.
colors("WovenBand", [("edge", WOOD_RIM)] + [("color_%d" % i, c) for i, c in enumerate(BAND)])
constants("WovenBand", [("block", BLOCK), ("rows", 3), ("percent", 62)])


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
