;;; tty-colors.el --- color support for character terminals

;; Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.

;; Author: Eli Zaretskii <eliz@is.elta.co.il>
;; Maintainer: FSF
;; Keywords: terminals, faces

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Emacs support for colors evolved from the X Window System; color
;; support for character-based terminals came later.  Many Lisp
;; packages use color names defined by X and assume the availability
;; of certain functions that look up colors, convert them to pixel
;; values, etc.

;; This file provides a more or less useful emulation of the X color
;; functionality for character-based terminals, and thus relieves the
;; rest of Emacs from including special code for this case.

;; Here's how it works.  The support for terminal and MSDOS frames
;; maintains an alist, called `tty-defined-color-alist', which
;; associates colors supported by the terminal driver with small
;; integers.  (These small integers are passed to the library
;; functions which set the color, and are effectively indices of the
;; colors in the supported color palette.)  When Emacs needs to send a
;; color command to the terminal, the color name is first looked up in
;; `tty-defined-color-alist'.  If not found, functions from this file
;; can be used to map the color to one of the supported colors.
;; Specifically, the X RGB values of the requested color are extracted
;; from `color-name-rgb-alist' and then the supported color is found
;; with the minimal distance in the RGB space from the requested
;; color.

;; `tty-defined-color-alist' is created at startup by calling the
;; function `tty-color-define', defined below, passing it each
;; supported color, its index, and its RGB values.  The standard list
;; of colors supported by many Unix color terminals, including xterm,
;; FreeBSD, and GNU/Linux, is supplied below in `tty-standard-colors'.
;; If your terminal supports different or additional colors, call
;; `tty-color-define' from your `.emacs' or `site-start.el'.  For
;; more-or-less standard definitions of VGA text-mode colors, see the
;; beginning of lisp/term/pc-win.el.

;;; Code:

;; The following list is taken from rgb.txt distributed with X.
;;
;; WARNING: Some colors, such as "lightred", do not appear in this
;; list.  If you think it's a good idea to add them, don't!  The
;; problem is that the X-standard definition of "red" actually
;; corresponds to "lightred" on VGA (that's why pc-win.el and
;; w32-fns.el define "lightred" with the same RGB values as "red"
;; below).  Adding "lightred" here would therefore create confusing
;; and counter-intuitive results, like "red" and "lightred" being the
;; same color.  A similar situation exists with other "light*" colors.
;;
;; Nevertheless, "lightred" and other similar color names *are*
;; defined for the MS-DOS and MS-Windows consoles, because the users
;; on those systems expect these colors to be available.
;;
;; For these reasons, package maintaners are advised NOT to use color
;; names such as "lightred" or "lightblue", because they will have
;; different effect on different displays.  Instead, use "red1" and
;; "blue1", respectively.
(defvar color-name-rgb-alist
  '(("snow"		255 250 250)
    ("ghostwhite"	248 248 255)
    ("whitesmoke"	245 245 245)
    ("gainsboro"	220 220 220)
    ("floralwhite"	255 250 240)
    ("oldlace"		253 245 230)
    ("linen"		250 240 230)
    ("antiquewhite"	250 235 215)
    ("papayawhip"	255 239 213)
    ("blanchedalmond"	255 235 205)
    ("bisque"		255 228 196)
    ("peachpuff"	255 218 185)
    ("navajowhite"	255 222 173)
    ("moccasin"		255 228 181)
    ("cornsilk"		255 248 220)
    ("ivory"		255 255 240)
    ("lemonchiffon"	255 250 205)
    ("seashell"		255 245 238)
    ("honeydew"		240 255 240)
    ("mintcream"	245 255 250)
    ("azure"		240 255 255)
    ("aliceblue"	240 248 255)
    ("lavender"		230 230 250)
    ("lavenderblush"	255 240 245)
    ("mistyrose"	255 228 225)
    ("white"		255 255 255)
    ("black"		0 0 0)
    ("darkslategray"	47 79 79)
    ("darkslategrey"	47 79 79)
    ("dimgray"		105 105 105)
    ("dimgrey"		105 105 105)
    ("slategray"	112 128 144)
    ("slategrey"	112 128 144)
    ("lightslategray"	119 136 153)
    ("lightslategrey"	119 136 153)
    ("gray"		190 190 190)
    ("grey"		190 190 190)
    ("lightgrey"	211 211 211)
    ("lightgray"	211 211 211)
    ("midnightblue"	25 25 112)
    ("navy"		0 0 128)
    ("navyblue"		0 0 128)
    ("cornflowerblue"	100 149 237)
    ("darkslateblue"	72 61 139)
    ("slateblue"	106 90 205)
    ("mediumslateblue"	123 104 238)
    ("lightslateblue"	132 112 255)
    ("mediumblue"	0 0 205)
    ("royalblue"	65 105 225)
    ("blue"		0 0 255)
    ("dodgerblue"	30 144 255)
    ("deepskyblue"	0 191 255)
    ("skyblue"		135 206 235)
    ("lightskyblue"	135 206 250)
    ("steelblue"	70 130 180)
    ("lightsteelblue"	176 196 222)
    ("lightblue"	173 216 230)
    ("powderblue"	176 224 230)
    ("paleturquoise"	175 238 238)
    ("darkturquoise"	0 206 209)
    ("mediumturquoise"	72 209 204)
    ("turquoise"	64 224 208)
    ("cyan"		0 255 255)
    ("lightcyan"	224 255 255)
    ("cadetblue"	95 158 160)
    ("mediumaquamarine"	102 205 170)
    ("aquamarine"	127 255 212)
    ("darkgreen"	0 100 0)
    ("darkolivegreen"	85 107 47)
    ("darkseagreen"	143 188 143)
    ("seagreen"		46 139 87)
    ("mediumseagreen"	60 179 113)
    ("lightseagreen"	32 178 170)
    ("palegreen"	152 251 152)
    ("springgreen"	0 255 127)
    ("lawngreen"	124 252 0)
    ("green"		0 255 0)
    ("chartreuse"	127 255 0)
    ("mediumspringgreen"	0 250 154)
    ("greenyellow"	173 255 47)
    ("limegreen"	50 205 50)
    ("yellowgreen"	154 205 50)
    ("forestgreen"	34 139 34)
    ("olivedrab"	107 142 35)
    ("darkkhaki"	189 183 107)
    ("khaki"		240 230 140)
    ("palegoldenrod"	238 232 170)
    ("lightgoldenrodyellow"	250 250 210)
    ("lightyellow"	255 255 224)
    ("yellow"		255 255 0)
    ("gold"		255 215 0)
    ("lightgoldenrod"	238 221 130)
    ("goldenrod"	218 165 32)
    ("darkgoldenrod"	184 134 11)
    ("rosybrown"	188 143 143)
    ("indianred"	205 92 92)
    ("saddlebrown"	139 69 19)
    ("sienna"		160 82 45)
    ("peru"		205 133 63)
    ("burlywood"	222 184 135)
    ("beige"		245 245 220)
    ("wheat"		245 222 179)
    ("sandybrown"	244 164 96)
    ("tan"		210 180 140)
    ("chocolate"	210 105 30)
    ("firebrick"	178 34 34)
    ("brown"		165 42 42)
    ("darksalmon"	233 150 122)
    ("salmon"		250 128 114)
    ("lightsalmon"	255 160 122)
    ("orange"		255 165 0)
    ("darkorange"	255 140 0)
    ("coral"		255 127 80)
    ("lightcoral"	240 128 128)
    ("tomato"		255 99 71)
    ("orangered"	255 69 0)
    ("red"		255 0 0)
    ("hotpink"		255 105 180)
    ("deeppink"		255 20 147)
    ("pink"		255 192 203)
    ("lightpink"	255 182 193)
    ("palevioletred"	219 112 147)
    ("maroon"		176 48 96)
    ("mediumvioletred"	199 21 133)
    ("violetred"	208 32 144)
    ("magenta"		255 0 255)
    ("violet"		238 130 238)
    ("plum"		221 160 221)
    ("orchid"		218 112 214)
    ("mediumorchid"	186 85 211)
    ("darkorchid"	153 50 204)
    ("darkviolet"	148 0 211)
    ("blueviolet"	138 43 226)
    ("purple"		160 32 240)
    ("mediumpurple"	147 112 219)
    ("thistle"		216 191 216)
    ("snow1"		255 250 250)
    ("snow2"		238 233 233)
    ("snow3"		205 201 201)
    ("snow4"		139 137 137)
    ("seashell1"	255 245 238)
    ("seashell2"	238 229 222)
    ("seashell3"	205 197 191)
    ("seashell4"	139 134 130)
    ("antiquewhite1"	255 239 219)
    ("antiquewhite2"	238 223 204)
    ("antiquewhite3"	205 192 176)
    ("antiquewhite4"	139 131 120)
    ("bisque1"		255 228 196)
    ("bisque2"		238 213 183)
    ("bisque3"		205 183 158)
    ("bisque4"		139 125 107)
    ("peachpuff1"	255 218 185)
    ("peachpuff2"	238 203 173)
    ("peachpuff3"	205 175 149)
    ("peachpuff4"	139 119 101)
    ("navajowhite1"	255 222 173)
    ("navajowhite2"	238 207 161)
    ("navajowhite3"	205 179 139)
    ("navajowhite4"	139 121 94)
    ("lemonchiffon1"	255 250 205)
    ("lemonchiffon2"	238 233 191)
    ("lemonchiffon3"	205 201 165)
    ("lemonchiffon4"	139 137 112)
    ("cornsilk1"	255 248 220)
    ("cornsilk2"	238 232 205)
    ("cornsilk3"	205 200 177)
    ("cornsilk4"	139 136 120)
    ("ivory1"		255 255 240)
    ("ivory2"		238 238 224)
    ("ivory3"		205 205 193)
    ("ivory4"		139 139 131)
    ("honeydew1"	240 255 240)
    ("honeydew2"	224 238 224)
    ("honeydew3"	193 205 193)
    ("honeydew4"	131 139 131)
    ("lavenderblush1"	255 240 245)
    ("lavenderblush2"	238 224 229)
    ("lavenderblush3"	205 193 197)
    ("lavenderblush4"	139 131 134)
    ("mistyrose1"	255 228 225)
    ("mistyrose2"	238 213 210)
    ("mistyrose3"	205 183 181)
    ("mistyrose4"	139 125 123)
    ("azure1"		240 255 255)
    ("azure2"		224 238 238)
    ("azure3"		193 205 205)
    ("azure4"		131 139 139)
    ("slateblue1"	131 111 255)
    ("slateblue2"	122 103 238)
    ("slateblue3"	105 89 205)
    ("slateblue4"	71 60 139)
    ("royalblue1"	72 118 255)
    ("royalblue2"	67 110 238)
    ("royalblue3"	58 95 205)
    ("royalblue4"	39 64 139)
    ("blue1"		0 0 255)
    ("blue2"		0 0 238)
    ("blue3"		0 0 205)
    ("blue4"		0 0 139)
    ("dodgerblue1"	30 144 255)
    ("dodgerblue2"	28 134 238)
    ("dodgerblue3"	24 116 205)
    ("dodgerblue4"	16 78 139)
    ("steelblue1"	99 184 255)
    ("steelblue2"	92 172 238)
    ("steelblue3"	79 148 205)
    ("steelblue4"	54 100 139)
    ("deepskyblue1"	0 191 255)
    ("deepskyblue2"	0 178 238)
    ("deepskyblue3"	0 154 205)
    ("deepskyblue4"	0 104 139)
    ("skyblue1"		135 206 255)
    ("skyblue2"		126 192 238)
    ("skyblue3"		108 166 205)
    ("skyblue4"		74 112 139)
    ("lightskyblue1"	176 226 255)
    ("lightskyblue2"	164 211 238)
    ("lightskyblue3"	141 182 205)
    ("lightskyblue4"	96 123 139)
    ("slategray1"	198 226 255)
    ("slategray2"	185 211 238)
    ("slategray3"	159 182 205)
    ("slategray4"	108 123 139)
    ("lightsteelblue1"	202 225 255)
    ("lightsteelblue2"	188 210 238)
    ("lightsteelblue3"	162 181 205)
    ("lightsteelblue4"	110 123 139)
    ("lightblue1"	191 239 255)
    ("lightblue2"	178 223 238)
    ("lightblue3"	154 192 205)
    ("lightblue4"	104 131 139)
    ("lightcyan1"	224 255 255)
    ("lightcyan2"	209 238 238)
    ("lightcyan3"	180 205 205)
    ("lightcyan4"	122 139 139)
    ("paleturquoise1"	187 255 255)
    ("paleturquoise2"	174 238 238)
    ("paleturquoise3"	150 205 205)
    ("paleturquoise4"	102 139 139)
    ("cadetblue1"	152 245 255)
    ("cadetblue2"	142 229 238)
    ("cadetblue3"	122 197 205)
    ("cadetblue4"	83 134 139)
    ("turquoise1"	0 245 255)
    ("turquoise2"	0 229 238)
    ("turquoise3"	0 197 205)
    ("turquoise4"	0 134 139)
    ("cyan1"		0 255 255)
    ("cyan2"		0 238 238)
    ("cyan3"		0 205 205)
    ("cyan4"		0 139 139)
    ("darkslategray1"	151 255 255)
    ("darkslategray2"	141 238 238)
    ("darkslategray3"	121 205 205)
    ("darkslategray4"	82 139 139)
    ("aquamarine1"	127 255 212)
    ("aquamarine2"	118 238 198)
    ("aquamarine3"	102 205 170)
    ("aquamarine4"	69 139 116)
    ("darkseagreen1"	193 255 193)
    ("darkseagreen2"	180 238 180)
    ("darkseagreen3"	155 205 155)
    ("darkseagreen4"	105 139 105)
    ("seagreen1"	84 255 159)
    ("seagreen2"	78 238 148)
    ("seagreen3"	67 205 128)
    ("seagreen4"	46 139 87)
    ("palegreen1"	154 255 154)
    ("palegreen2"	144 238 144)
    ("palegreen3"	124 205 124)
    ("palegreen4"	84 139 84)
    ("springgreen1"	0 255 127)
    ("springgreen2"	0 238 118)
    ("springgreen3"	0 205 102)
    ("springgreen4"	0 139 69)
    ("green1"		0 255 0)
    ("green2"		0 238 0)
    ("green3"		0 205 0)
    ("green4"		0 139 0)
    ("chartreuse1"	127 255 0)
    ("chartreuse2"	118 238 0)
    ("chartreuse3"	102 205 0)
    ("chartreuse4"	69 139 0)
    ("olivedrab1"	192 255 62)
    ("olivedrab2"	179 238 58)
    ("olivedrab3"	154 205 50)
    ("olivedrab4"	105 139 34)
    ("darkolivegreen1"	202 255 112)
    ("darkolivegreen2"	188 238 104)
    ("darkolivegreen3"	162 205 90)
    ("darkolivegreen4"	110 139 61)
    ("khaki1"		255 246 143)
    ("khaki2"		238 230 133)
    ("khaki3"		205 198 115)
    ("khaki4"		139 134 78)
    ("lightgoldenrod1"	255 236 139)
    ("lightgoldenrod2"	238 220 130)
    ("lightgoldenrod3"	205 190 112)
    ("lightgoldenrod4"	139 129 76)
    ("lightyellow1"	255 255 224)
    ("lightyellow2"	238 238 209)
    ("lightyellow3"	205 205 180)
    ("lightyellow4"	139 139 122)
    ("yellow1"		255 255 0)
    ("yellow2"		238 238 0)
    ("yellow3"		205 205 0)
    ("yellow4"		139 139 0)
    ("gold1"		255 215 0)
    ("gold2"		238 201 0)
    ("gold3"		205 173 0)
    ("gold4"		139 117 0)
    ("goldenrod1"	255 193 37)
    ("goldenrod2"	238 180 34)
    ("goldenrod3"	205 155 29)
    ("goldenrod4"	139 105 20)
    ("darkgoldenrod1"	255 185 15)
    ("darkgoldenrod2"	238 173 14)
    ("darkgoldenrod3"	205 149 12)
    ("darkgoldenrod4"	139 101 8)
    ("rosybrown1"	255 193 193)
    ("rosybrown2"	238 180 180)
    ("rosybrown3"	205 155 155)
    ("rosybrown4"	139 105 105)
    ("indianred1"	255 106 106)
    ("indianred2"	238 99 99)
    ("indianred3"	205 85 85)
    ("indianred4"	139 58 58)
    ("sienna1"		255 130 71)
    ("sienna2"		238 121 66)
    ("sienna3"		205 104 57)
    ("sienna4"		139 71 38)
    ("burlywood1"	255 211 155)
    ("burlywood2"	238 197 145)
    ("burlywood3"	205 170 125)
    ("burlywood4"	139 115 85)
    ("wheat1"		255 231 186)
    ("wheat2"		238 216 174)
    ("wheat3"		205 186 150)
    ("wheat4"		139 126 102)
    ("tan1"		255 165 79)
    ("tan2"		238 154 73)
    ("tan3"		205 133 63)
    ("tan4"		139 90 43)
    ("chocolate1"	255 127 36)
    ("chocolate2"	238 118 33)
    ("chocolate3"	205 102 29)
    ("chocolate4"	139 69 19)
    ("firebrick1"	255 48 48)
    ("firebrick2"	238 44 44)
    ("firebrick3"	205 38 38)
    ("firebrick4"	139 26 26)
    ("brown1"		255 64 64)
    ("brown2"		238 59 59)
    ("brown3"		205 51 51)
    ("brown4"		139 35 35)
    ("salmon1"		255 140 105)
    ("salmon2"		238 130 98)
    ("salmon3"		205 112 84)
    ("salmon4"		139 76 57)
    ("lightsalmon1"	255 160 122)
    ("lightsalmon2"	238 149 114)
    ("lightsalmon3"	205 129 98)
    ("lightsalmon4"	139 87 66)
    ("orange1"		255 165 0)
    ("orange2"		238 154 0)
    ("orange3"		205 133 0)
    ("orange4"		139 90 0)
    ("darkorange1"	255 127 0)
    ("darkorange2"	238 118 0)
    ("darkorange3"	205 102 0)
    ("darkorange4"	139 69 0)
    ("coral1"		255 114 86)
    ("coral2"		238 106 80)
    ("coral3"		205 91 69)
    ("coral4"		139 62 47)
    ("tomato1"		255 99 71)
    ("tomato2"		238 92 66)
    ("tomato3"		205 79 57)
    ("tomato4"		139 54 38)
    ("orangered1"	255 69 0)
    ("orangered2"	238 64 0)
    ("orangered3"	205 55 0)
    ("orangered4"	139 37 0)
    ("red1"		255 0 0)
    ("red2"		238 0 0)
    ("red3"		205 0 0)
    ("red4"		139 0 0)
    ("deeppink1"	255 20 147)
    ("deeppink2"	238 18 137)
    ("deeppink3"	205 16 118)
    ("deeppink4"	139 10 80)
    ("hotpink1"		255 110 180)
    ("hotpink2"		238 106 167)
    ("hotpink3"		205 96 144)
    ("hotpink4"		139 58 98)
    ("pink1"		255 181 197)
    ("pink2"		238 169 184)
    ("pink3"		205 145 158)
    ("pink4"		139 99 108)
    ("lightpink1"	255 174 185)
    ("lightpink2"	238 162 173)
    ("lightpink3"	205 140 149)
    ("lightpink4"	139 95 101)
    ("palevioletred1"	255 130 171)
    ("palevioletred2"	238 121 159)
    ("palevioletred3"	205 104 137)
    ("palevioletred4"	139 71 93)
    ("maroon1"		255 52 179)
    ("maroon2"		238 48 167)
    ("maroon3"		205 41 144)
    ("maroon4"		139 28 98)
    ("violetred1"	255 62 150)
    ("violetred2"	238 58 140)
    ("violetred3"	205 50 120)
    ("violetred4"	139 34 82)
    ("magenta1"		255 0 255)
    ("magenta2"		238 0 238)
    ("magenta3"		205 0 205)
    ("magenta4"		139 0 139)
    ("orchid1"		255 131 250)
    ("orchid2"		238 122 233)
    ("orchid3"		205 105 201)
    ("orchid4"		139 71 137)
    ("plum1"		255 187 255)
    ("plum2"		238 174 238)
    ("plum3"		205 150 205)
    ("plum4"		139 102 139)
    ("mediumorchid1"	224 102 255)
    ("mediumorchid2"	209 95 238)
    ("mediumorchid3"	180 82 205)
    ("mediumorchid4"	122 55 139)
    ("darkorchid1"	191 62 255)
    ("darkorchid2"	178 58 238)
    ("darkorchid3"	154 50 205)
    ("darkorchid4"	104 34 139)
    ("purple1"		155 48 255)
    ("purple2"		145 44 238)
    ("purple3"		125 38 205)
    ("purple4"		85 26 139)
    ("mediumpurple1"	171 130 255)
    ("mediumpurple2"	159 121 238)
    ("mediumpurple3"	137 104 205)
    ("mediumpurple4"	93 71 139)
    ("thistle1"		255 225 255)
    ("thistle2"		238 210 238)
    ("thistle3"		205 181 205)
    ("thistle4"		139 123 139)
    ("gray0"		0 0 0)
    ("grey0"		0 0 0)
    ("gray1"		3 3 3)
    ("grey1"		3 3 3)
    ("gray2"		5 5 5)
    ("grey2"		5 5 5)
    ("gray3"		8 8 8)
    ("grey3"		8 8 8)
    ("gray4"		10 10 10)
    ("grey4"		10 10 10)
    ("gray5"		13 13 13)
    ("grey5"		13 13 13)
    ("gray6"		15 15 15)
    ("grey6"		15 15 15)
    ("gray7"		18 18 18)
    ("grey7"		18 18 18)
    ("gray8"		20 20 20)
    ("grey8"		20 20 20)
    ("gray9"		23 23 23)
    ("grey9"		23 23 23)
    ("gray10"		26 26 26)
    ("grey10"		26 26 26)
    ("gray11"		28 28 28)
    ("grey11"		28 28 28)
    ("gray12"		31 31 31)
    ("grey12"		31 31 31)
    ("gray13"		33 33 33)
    ("grey13"		33 33 33)
    ("gray14"		36 36 36)
    ("grey14"		36 36 36)
    ("gray15"		38 38 38)
    ("grey15"		38 38 38)
    ("gray16"		41 41 41)
    ("grey16"		41 41 41)
    ("gray17"		43 43 43)
    ("grey17"		43 43 43)
    ("gray18"		46 46 46)
    ("grey18"		46 46 46)
    ("gray19"		48 48 48)
    ("grey19"		48 48 48)
    ("gray20"		51 51 51)
    ("grey20"		51 51 51)
    ("gray21"		54 54 54)
    ("grey21"		54 54 54)
    ("gray22"		56 56 56)
    ("grey22"		56 56 56)
    ("gray23"		59 59 59)
    ("grey23"		59 59 59)
    ("gray24"		61 61 61)
    ("grey24"		61 61 61)
    ("gray25"		64 64 64)
    ("grey25"		64 64 64)
    ("gray26"		66 66 66)
    ("grey26"		66 66 66)
    ("gray27"		69 69 69)
    ("grey27"		69 69 69)
    ("gray28"		71 71 71)
    ("grey28"		71 71 71)
    ("gray29"		74 74 74)
    ("grey29"		74 74 74)
    ("gray30"		77 77 77)
    ("grey30"		77 77 77)
    ("gray31"		79 79 79)
    ("grey31"		79 79 79)
    ("gray32"		82 82 82)
    ("grey32"		82 82 82)
    ("gray33"		84 84 84)
    ("grey33"		84 84 84)
    ("gray34"		87 87 87)
    ("grey34"		87 87 87)
    ("gray35"		89 89 89)
    ("grey35"		89 89 89)
    ("gray36"		92 92 92)
    ("grey36"		92 92 92)
    ("gray37"		94 94 94)
    ("grey37"		94 94 94)
    ("gray38"		97 97 97)
    ("grey38"		97 97 97)
    ("gray39"		99 99 99)
    ("grey39"		99 99 99)
    ("gray40"		102 102 102)
    ("grey40"		102 102 102)
    ("gray41"		105 105 105)
    ("grey41"		105 105 105)
    ("gray42"		107 107 107)
    ("grey42"		107 107 107)
    ("gray43"		110 110 110)
    ("grey43"		110 110 110)
    ("gray44"		112 112 112)
    ("grey44"		112 112 112)
    ("gray45"		115 115 115)
    ("grey45"		115 115 115)
    ("gray46"		117 117 117)
    ("grey46"		117 117 117)
    ("gray47"		120 120 120)
    ("grey47"		120 120 120)
    ("gray48"		122 122 122)
    ("grey48"		122 122 122)
    ("gray49"		125 125 125)
    ("grey49"		125 125 125)
    ("gray50"		127 127 127)
    ("grey50"		127 127 127)
    ("gray51"		130 130 130)
    ("grey51"		130 130 130)
    ("gray52"		133 133 133)
    ("grey52"		133 133 133)
    ("gray53"		135 135 135)
    ("grey53"		135 135 135)
    ("gray54"		138 138 138)
    ("grey54"		138 138 138)
    ("gray55"		140 140 140)
    ("grey55"		140 140 140)
    ("gray56"		143 143 143)
    ("grey56"		143 143 143)
    ("gray57"		145 145 145)
    ("grey57"		145 145 145)
    ("gray58"		148 148 148)
    ("grey58"		148 148 148)
    ("gray59"		150 150 150)
    ("grey59"		150 150 150)
    ("gray60"		153 153 153)
    ("grey60"		153 153 153)
    ("gray61"		156 156 156)
    ("grey61"		156 156 156)
    ("gray62"		158 158 158)
    ("grey62"		158 158 158)
    ("gray63"		161 161 161)
    ("grey63"		161 161 161)
    ("gray64"		163 163 163)
    ("grey64"		163 163 163)
    ("gray65"		166 166 166)
    ("grey65"		166 166 166)
    ("gray66"		168 168 168)
    ("grey66"		168 168 168)
    ("gray67"		171 171 171)
    ("grey67"		171 171 171)
    ("gray68"		173 173 173)
    ("grey68"		173 173 173)
    ("gray69"		176 176 176)
    ("grey69"		176 176 176)
    ("gray70"		179 179 179)
    ("grey70"		179 179 179)
    ("gray71"		181 181 181)
    ("grey71"		181 181 181)
    ("gray72"		184 184 184)
    ("grey72"		184 184 184)
    ("gray73"		186 186 186)
    ("grey73"		186 186 186)
    ("gray74"		189 189 189)
    ("grey74"		189 189 189)
    ("gray75"		191 191 191)
    ("grey75"		191 191 191)
    ("gray76"		194 194 194)
    ("grey76"		194 194 194)
    ("gray77"		196 196 196)
    ("grey77"		196 196 196)
    ("gray78"		199 199 199)
    ("grey78"		199 199 199)
    ("gray79"		201 201 201)
    ("grey79"		201 201 201)
    ("gray80"		204 204 204)
    ("grey80"		204 204 204)
    ("gray81"		207 207 207)
    ("grey81"		207 207 207)
    ("gray82"		209 209 209)
    ("grey82"		209 209 209)
    ("gray83"		212 212 212)
    ("grey83"		212 212 212)
    ("gray84"		214 214 214)
    ("grey84"		214 214 214)
    ("gray85"		217 217 217)
    ("grey85"		217 217 217)
    ("gray86"		219 219 219)
    ("grey86"		219 219 219)
    ("gray87"		222 222 222)
    ("grey87"		222 222 222)
    ("gray88"		224 224 224)
    ("grey88"		224 224 224)
    ("gray89"		227 227 227)
    ("grey89"		227 227 227)
    ("gray90"		229 229 229)
    ("grey90"		229 229 229)
    ("gray91"		232 232 232)
    ("grey91"		232 232 232)
    ("gray92"		235 235 235)
    ("grey92"		235 235 235)
    ("gray93"		237 237 237)
    ("grey93"		237 237 237)
    ("gray94"		240 240 240)
    ("grey94"		240 240 240)
    ("gray95"		242 242 242)
    ("grey95"		242 242 242)
    ("gray96"		245 245 245)
    ("grey96"		245 245 245)
    ("gray97"		247 247 247)
    ("grey97"		247 247 247)
    ("gray98"		250 250 250)
    ("grey98"		250 250 250)
    ("gray99"		252 252 252)
    ("grey99"		252 252 252)
    ("gray100"		255 255 255)
    ("grey100"		255 255 255)
    ("darkgrey"		169 169 169)
    ("darkgray"		169 169 169)
    ("darkblue"		0 0 139)
    ("darkcyan"		0 139 139) ; no "lightmagenta", see the comment above
    ("darkmagenta"	139 0 139)
    ("darkred"		139 0 0)  ; but no "lightred", see the comment above
    ("lightgreen"	144 238 144))
  "An alist of X color names and associated 8-bit RGB values.")

(defvar tty-standard-colors
  '(("white"	7 65535 65535 65535)
    ("cyan"	6     0 65535 65535)
    ("magenta"	5 65535     0 65535)
    ("blue"	4     0     0 65535)
    ("yellow"	3 65535 65535     0)
    ("green"	2     0 65535     0)
    ("red"	1 65535     0     0)
    ("black"	0     0     0     0))
  "An alist of 8 standard tty colors, their indices and RGB values.")

;; This is used by term.c
(defvar tty-color-mode-alist
  '((never . -1)
    (no . -1)
    (default . 0)
    (auto . 0)
    (ansi8 . 8)
    (always . 8)
    (yes . 8))
  "An alist of supported standard tty color modes and their aliases.")

(defvar tty-defined-color-alist nil
  "An alist of defined terminal colors and their RGB values.

See the docstring of `tty-color-alist' for the details.")

(defun tty-color-alist (&optional frame)
  "Return an alist of colors supported by FRAME's terminal.
FRAME defaults to the selected frame.
Each element of the returned alist is of the form:
 \(NAME INDEX R G B\)
where NAME is the name of the color, a string;
INDEX is the index of this color to be sent to the terminal driver
when the color should be displayed; it is typically a small integer;
R, G, and B are the intensities of, accordingly, red, green, and blue
components of the color, represented as numbers between 0 and 65535.
The file `etc/rgb.txt' in the Emacs distribution lists the standard
RGB values of the X colors.  If RGB is nil, this color will not be
considered by `tty-color-translate' as an approximation to another
color."
  tty-defined-color-alist)

(defun tty-modify-color-alist (elt &optional frame)
  "Put the association ELT int the alist of terminal colors for FRAME.
ELT should be of the form  \(NAME INDEX R G B\) (see `tty-color-alist'
for details).
If FRAME is unspecified or nil, it defaults to the selected frame.
Value is the modified color alist for FRAME."
  (let* ((entry (assoc (car elt) (tty-color-alist frame))))
    (if entry
	(setcdr entry (cdr elt))
      (setq tty-defined-color-alist (cons elt tty-defined-color-alist)))
    tty-defined-color-alist))

(defun tty-color-canonicalize (color)
  "Return COLOR in canonical form.
A canonicalized color name is all-lower case, with any blanks removed."
  (let ((color (downcase color)))
    (while (string-match " +" color)
      (setq color (replace-match "" nil nil color)))
    color))

(defun tty-color-define (name index &optional rgb frame)
  "Specify a tty color by its NAME, terminal INDEX and RGB values.
NAME is a string, INDEX is typically a small integer used to send to
the terminal driver a command to switch this color on, and RGB is a
list of 3 numbers that specify the intensity of red, green, and blue
components of the color.
If specified, each one of the RGB components must be a number between
0 and 65535.  If RGB is omitted, the specified color will never be used
by `tty-color-translate' as an approximation to another color.
FRAME is the frame where the defined color should be used.
If FRAME is not specified or is nil, it defaults to the selected frame."
  (if (or (not (stringp name))
	  (not (integerp index))
	  (and rgb (or (not (listp rgb)) (/= (length rgb) 3))))
      (error "Invalid specification for tty color \"%s\"" name))
  (tty-modify-color-alist
   (append (list (tty-color-canonicalize name) index) rgb) frame))

(defun tty-color-clear (&optional frame)
  "Clear the list of supported tty colors for frame FRAME.
If FRAME is unspecified or nil, it defaults to the selected frame."
  (setq tty-defined-color-alist nil))

(defun tty-color-off-gray-diag (r g b)
  "Compute the angle between the color given by R,G,B and the gray diagonal.
The gray diagonal is the diagonal of the 3D cube in RGB space which
connects the points corresponding to the black and white colors.  All the
colors whose RGB coordinates belong to this diagonal are various shades
of gray, thus the name."
  (let ((mag (sqrt (* 3 (+ (* r r) (* g g) (* b b))))))
    (if (< mag 1) 0 (acos (/ (+ r g b) mag)))))

(defun tty-color-approximate (rgb &optional frame)
  "Given a list of 3 rgb values in RGB, find the color in `tty-color-alist'
which is the best approximation in the 3-dimensional RGB space,
and return the index associated with the approximating color.
Each value of the RGB triplet has to be scaled to the 0..255 range.
FRAME defaults to the selected frame."
  (let* ((color-list (tty-color-alist frame))
	 (candidate (car color-list))
	 (best-distance 195076)	;; 3 * 255^2 + 15
	 best-color)
    (while candidate
      (let* ((try-rgb (cddr candidate))
	     (r (car rgb))
	     (g (cadr rgb))
	     (b (nth 2 rgb))
	     ;; If the approximated color is not close enough to the
	     ;; gray diagonal of the RGB cube, favor non-gray colors.
	     ;; (The number 0.065 is an empirical ad-hoc'ery.)
	     (favor-non-gray (>= (tty-color-off-gray-diag r g b) 0.065))
	     try-r try-g try-b
	     dif-r dif-g dif-b dist)
	;; If the RGB values of the candidate color are unknown, we
	;; never consider it for approximating another color.
	(if try-rgb
	    (progn
	      (setq try-r (lsh (car try-rgb) -8)
		    try-g (lsh (cadr try-rgb) -8)
		    try-b (lsh (nth 2 try-rgb) -8))
	      (setq dif-r (- (car rgb) try-r)
		    dif-g (- (cadr rgb) try-g)
		    dif-b (- (nth 2 rgb) try-b))
	      (setq dist (+ (* dif-r dif-r) (* dif-g dif-g) (* dif-b dif-b)))
	      (if (and (< dist best-distance)
		       ;; The candidate color is on the gray diagonal
		       ;; if its RGB components are all equal.
		       (or (/= try-r try-g) (/= try-g try-b)
			   (not favor-non-gray)))
		  (setq best-distance dist
			best-color candidate)))))
      (setq color-list (cdr color-list))
      (setq candidate (car color-list)))
    (cadr best-color)))

(defun tty-color-translate (color &optional frame)
  "Given a color COLOR, return the index of the corresponding TTY color.

COLOR must be a string that is either the color's name, or its X-style
specification like \"#RRGGBB\" or \"RGB:rr/gg/bb\", where each primary.
color can be given with 1 to 4 hex digits.

If COLOR is a color name that is found among supported colors in
`tty-color-alist', the associated index is returned.  Otherwise, the
RGB values of the color, either as given by the argument or from
looking up the name in `color-name-rgb-alist', are used to find the
supported color that is the best approximation for COLOR in the RGB
space.
If COLOR is neither a valid X RGB specification of the color, nor a
name of a color in `color-name-rgb-alist', the returned value is nil.

If FRAME is unspecified or nil, it defaults to the selected frame."
  (and (stringp color)
       (let* ((color (tty-color-canonicalize color))
	      (idx (cadr (assoc color (tty-color-alist frame)))))
	 (or idx
	     (let* ((len (length color))
		    (maxval 256)
		    (rgb
		     (cond
		      ((and (>= len 4)  ;; X-style "#XXYYZZ" color spec
			    (eq (aref color 0) ?#)
			    (member (aref color 1)
				    '(?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9
					 ?a ?b ?c ?d ?e ?f)))
		       ;; Translate the string "#XXYYZZ" into a list
		       ;; of numbers (XX YY ZZ).  If the primary colors
		       ;; are specified with less than 4 hex digits,
		       ;; the used digits represent the most significant
		       ;; bits of the value (e.g. #XYZ = #X000Y000Z000).
		       (let* ((ndig (/ (- len 1) 3))
			      (i1 1)
			      (i2 (+ i1 ndig))
			      (i3 (+ i2 ndig)))
			 (list
			  (lsh
			   (string-to-number (substring color i1 i2) 16)
			   (* 4 (- 2 ndig)))
			  (lsh
			   (string-to-number (substring color i2 i3) 16)
			   (* 4 (- 2 ndig)))
			  (lsh
			   (string-to-number (substring color i3) 16)
			   (* 4 (- 2 ndig))))))
		      ((and (>= len 9)  ;; X-style RGB:xx/yy/zz color spec
			    (string= (substring color 0 4) "rgb:"))
		       ;; Translate the string "RGB:XX/YY/ZZ" into a list
		       ;; of numbers (XX YY ZZ).  If fewer than 4 hex
		       ;; digits are used, they represent the fraction
		       ;; of the maximum value (RGB:X/Y/Z = #XXXXYYYYZZZZ).
		       (let* ((ndig (/ (- len 3) 3))
			      (maxval (1- (expt 16 (- ndig 1))))
			      (i1 4)
			      (i2 (+ i1 ndig))
			      (i3 (+ i2 ndig)))
			 (list
			  (/ (* (string-to-number
				 (substring color i1 (- i2 1)) 16)
				255)
			     maxval)
			  (/ (* (string-to-number
				 (substring color i2 (- i3 1)) 16)
				255)
			     maxval)
			  (/ (* (string-to-number
				 (substring color i3) 16)
				255)
			     maxval))))
		      (t
		       (cdr (assoc color color-name-rgb-alist))))))
	       (and rgb (tty-color-approximate rgb frame)))))))

(defun tty-color-by-index (idx &optional frame)
  "Given a numeric index of a tty color, return its description.

FRAME, if unspecified or nil, defaults to the selected frame.
Value is a list of the form \(NAME INDEX R G B\)."
  (and idx
       (let ((colors (tty-color-alist frame))
	     desc found)
	 (while colors
	   (setq desc (car colors))
	   (if (eq idx (car (cdr desc)))
	       (setq found desc))
	   (setq colors (cdr colors)))
	 found)))

(defun tty-color-values (color &optional frame)
  "Return RGB values of the color COLOR on a termcap frame FRAME.

If COLOR is not directly supported by the display, return the RGB
values for a supported color that is its best approximation.
The value is a list of integer RGB values--\(RED GREEN BLUE\).
These values range from 0 to 65535; white is (65535 65535 65535).
If FRAME is omitted or nil, use the selected frame."
  (let* ((frame (or frame (selected-frame)))
	 (color (tty-color-canonicalize color))
	 (supported (assoc color (tty-color-alist frame))))
    (or (and supported (cddr supported)) ; full spec in tty-color-alist
	(and supported	; no RGB values in tty-color-alist: use X RGB values
	     (assoc color color-name-rgb-alist)
	     (cddr
	      (tty-color-by-index
	       (tty-color-approximate
		(cdr (assoc color color-name-rgb-alist)) frame) frame)))
	(cddr (tty-color-by-index (tty-color-translate color frame) frame)))))

(defun tty-color-desc (color &optional frame)
  "Return the description of the color COLOR for a character terminal.

FRAME, if unspecified or nil, defaults to the selected frame.
Value is a list of the form \(NAME INDEX R G B\).  Note that the returned
NAME is not necessarily the same string as the argument COLOR, because
the latter might need to be approximated if it is not supported directly."
  (let ((idx (tty-color-translate color frame)))
    (tty-color-by-index idx frame)))

(defun tty-color-gray-shades (&optional display)
  "Return the number of gray colors supported by DISPLAY's terminal.
A color is considered gray if the 3 components of its RGB value are equal."
  (let* ((frame (if (framep display) display
		  ;; FIXME: this uses an arbitrary frame from DISPLAY!
		  (car (frames-on-display-list display))))
	 (colors (tty-color-alist frame))
	 (count 0)
	 desc r g b)
    (while colors
      (setq desc (cddr (car colors))
	    r (car desc)
	    g (cadr desc)
	    b (car (cddr desc)))
      (and (numberp r)
	   (eq r g) (eq g b)
	   (setq count (1+ count)))
      (setq colors (cdr colors)))
    count))

;;; tty-colors.el ends here
