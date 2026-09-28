#!/usr/bin/env python3
"""Refonte 3.2-3.3 : retire le ScrollContainer d'un écran (SafeArea/Scroll/Margin → SafeArea/Margin).

Usage : python3 tools/ui/unscroll.py scenes/ui/<écran>.tscn [largeur_max]
Les écrans tiennent sur une page, sans défilement (paysage).
"""
import re
import sys

path = sys.argv[1]
s = open(path).read()
scroll = re.search(r'\[node name="Scroll" type="ScrollContainer" parent="SafeArea"\]\n(?:[^\[\n][^\n]*\n|\n)*', s)
if scroll:
    s = s[:scroll.start()] + s[scroll.end():]
    s = s.replace('[node name="Margin" type="MarginContainer" parent="SafeArea/Scroll"]\nunique_name_in_owner = true\nlayout_mode = 2\n',
                  '[node name="Margin" type="MarginContainer" parent="SafeArea"]\nunique_name_in_owner = true\nlayout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2\n')
    s = s.replace('parent="SafeArea/Scroll/', 'parent="SafeArea/')
if len(sys.argv) > 2:
    s = re.sub(r'max_width = [0-9.]+', 'max_width = %s' % sys.argv[2], s, count=1)
open(path, 'w').write(s)
print(path, "ok")
