#!/usr/bin/env python3
"""Refonte 3.3 : fabrique les scènes d'écran en paysage (sans défilement).

Chaque écran : CanvasLayer (script ScreenLayer), fond flou (ScreenBackdrop), zone sûre, marge, puis
un corps décrit en Python (nœuds Godot). Usage : importé par les scripts de la refonte.
"""

HEAD = '''[gd_scene load_steps={steps} format=3]

[ext_resource type="Script" path="{script}" id="1_screen"]
[ext_resource type="Script" path="res://scripts/ui/safe_area.gd" id="2_safe"]
[ext_resource type="Script" path="res://scripts/ui/neon_label.gd" id="3_neon"]
[ext_resource type="AudioStream" path="res://assets/audio/sfx/ui_click.wav" id="4_click"]
[ext_resource type="Script" path="res://scripts/ui/screen_backdrop.gd" id="90_backdrop"]
{extra_ext}
[node name="{name}" type="CanvasLayer"]
layer = {layer}
script = ExtResource("1_screen")
{exports}max_width = {max_width}
side_margin = 16.0
top_margin = 10.0
bottom_margin = 12.0
compact_height = 540.0
{rail}
[node name="Background" type="Control" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 0
script = ExtResource("90_backdrop")

[node name="SafeArea" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("2_safe")

[node name="Margin" type="MarginContainer" parent="SafeArea"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

'''

TAIL = '''[node name="ClickSound" type="AudioStreamPlayer" parent="."]
process_mode = 3
stream = ExtResource("4_click")
{extra_nodes}'''


def node(name, kind, parent, unique=False, **props):
    lines = ['[node name="%s" type="%s" parent="%s"]' % (name, kind, parent)]
    if unique:
        lines.append('unique_name_in_owner = true')
    lines.append('layout_mode = 2')
    for key, value in props.items():
        lines.append('%s = %s' % (key.replace('__', '/'), value))
    return '\n'.join(lines) + '\n\n'


def title(parent, name='Title'):
    return ('[node name="%s" type="Label" parent="%s"]\nunique_name_in_owner = true\nlayout_mode = 2\n'
            'theme_type_variation = &"ScreenTitle"\nhorizontal_alignment = 1\nautowrap_mode = 3\n'
            'script = ExtResource("3_neon")\necho_color = Color(0.086, 0.878, 1, 1)\necho_offset = Vector2(-3, -3)\n\n') % (name, parent)


def label(name, parent, variation, unique=True, align=1):
    return node(name, 'Label', parent, unique, theme_type_variation='&"%s"' % variation,
                horizontal_alignment=align, autowrap_mode=3)


def button(name, parent, variation=None, unique=True, expand=False):
    props = {'focus_mode': 0}
    if variation:
        props['theme_type_variation'] = '&"%s"' % variation
    if expand:
        props['size_flags_horizontal'] = 3
    return node(name, 'Button', parent, unique, **props)


def scene(name, script, body, layer=30, max_width=860.0, exports='', rail='', extra_ext='', extra_nodes='', extra_steps=0):
    rail_line = 'rail_tab = &"%s"\n' % rail if rail else ''
    head = HEAD.format(steps=6 + extra_steps, script=script, extra_ext=extra_ext, name=name, layer=layer,
                       exports=exports, max_width=max_width, rail=rail_line)
    return head + body + TAIL.format(extra_nodes=extra_nodes)
