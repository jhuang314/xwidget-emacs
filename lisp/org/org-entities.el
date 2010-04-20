;;; org-entities.el --- Support for special entities in Org-mode

;; Copyright (C) 2010 Free Software Foundation, Inc.

;; Author: Carsten Dominik <carsten at orgmode dot org>,
;;         Ulf Stegemann <ulf at zeitform dot de>
;; Keywords: outlines, calendar, wp
;; Homepage: http://orgmode.org
;; Version: 6.35i
;;
;; This file is part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

(require 'org-macs)

(declare-function org-table-align "org-table" ())

(eval-when-compile
  (require 'cl))

(defgroup org-entities nil
  "Options concerning entities in Org-mode."
  :tag "Org Entities"
  :group 'org)

(defcustom org-entities-ascii-explanatory nil
  "Non-nil means replace special entities in ASCII.
For example, this will replace \"\\nsup\" with \"[not a superset of]\"
in backends where the corresponding character is not available."
  :group 'org-entities
  :type 'boolean)

(defcustom org-entities-user nil
  "User-defined entities used in Org-mode to preduce special characters.
Each entry in this list is a list of strings.  It associate the name
of the entity that can be inserted into an Org file as \\name with the
appropriate replacements for the different export backends.  The order
of the fields is he following

name                 As a string, without the leading backslash
LaTeX replacement    In ready LaTeX, no further processing will take place
LaTeX mathp          A Boolean, either t or nil.  t if this entity needs
                     to be in math mode.
HTML replacement     In ready HTML, no further processing will take place.
                     Usually this will be an &...; entity.
ASCII replacement    Plain ASCII, no extensions.  Symbols that cannot be
                     represented will be written out as an explanatory text.
                     But see the variable `org-entities-ascii-keep-macro-form'.
Latin1 replacement   Use the special characters available in latin1.
utf-8 replacement    Use special character available in utf-8.

If you define new entities here that require specific LaTeX packages to be
loaded, add these packages to `org-export-latex-packages-alist'."
  :group 'org-entities
  :type '(repeat
	  (list
	   (string :tag "name  ")
	   (string :tag "LaTeX ")
	   (boolean :tag "Require LaTeX math?")
	   (string :tag "HTML  ")
	   (string :tag "ASCII ")
	   (string :tag "Latin1")
	   (string :tag "utf-8 "))))

(defconst org-entities
  '(("nbsp" "~" nil "&nbsp;" " " " " " ")
    ("iexcl" "!`" nil "&iexcl;" "!" "¡" "¡")
    ("cent" "\\textcent{}" nil "&cent;" "cent" "¢" "¢")
    ("pound" "\\pounds{}" nil "&pound;" "pound" "£" "£")
    ("curren" "\\textcurrency{}" nil "&curren;" "curr." "¤" "¤")
    ("yen" "\\textyen{}" nil "&yen;" "yen" "¥" "¥")
    ("brvbar" "\\textbrokenbar{}" nil "&brvbar;" "|" "¦" "¦")
    ("vert" "\\vert{}" t "&#124;" "|" "|" "|")
    ("sect" "\\S" nil "&sect;" "paragraph" "§" "§")
    ("uml" "\\textasciidieresis{}" nil "&uml;" "[diaeresis]" "¨" "¨")
    ("copy" "\\textcopyright{}" nil "&copy;" "(c)" "©" "©")
    ("ordf" "\\textordfeminine{}" nil "&ordf;" "_a_" "ª" "ª")
    ("laquo" "\\guillemotleft{}" nil "&laquo;" "<<" "«" "«")
    ("not" "\\textlnot{}" nil "&not;" "[angled dash]" "¬" "¬")
    ("shy" "\\-" nil "&shy;" "" "" "")
    ("reg" "\\textregistered{}" nil "&reg;" "(r)" "®" "®")
    ("macr" "\\textasciimacron{}" nil "&macr;" "[macron]" "¯" "¯")
    ("deg" "\\textdegree{}" nil "deg" "degree" "°" "°")
    ("pm" "\\textpm{}" nil "&plusmn;" "+-" "±" "±")
    ("plusmn" "\\textpm{}" nil "&plusmn;" "+-" "±" "±")
    ("sup2" "\\texttwosuperior{}" nil "&sup2;" "^2" "²" "²")
    ("sup3" "\\textthreesuperior{}" nil "&sup3;" "^3" "³" "³")
    ("acutex" "\\acute x" t "&acute;x" "'x" "'x" "𝑥́")
    ("micro" "\\textmu{}" nil "&micro;" "micro" "µ" "µ")
    ("para" "\\P{}" nil "&para;" "[pilcrow]" "¶" "¶")
    ("middot" "\\textperiodcentered{}" nil "&middot;" "." "·" "·")
    ("odot" "\\odot" t "o" "[circled dot]" "[circled dot]" "ʘ")
    ("star" "\\star" t "*" "*" "*" "⋆")
    ("cedil" "\\c{}" nil "&cedil;" "[cedilla]" "¸" "¸")
    ("sup1" "\\textonesuperior{}" nil "&sup1;" "^1" "¹" "¹")
    ("ordm" "\\textordmasculine{}" nil "&ordm;" "_o_" "º" "º")
    ("raquo" "\\guillemotright{}" nil "&raquo;" ">>" "»" "»")
    ("iquest" "?`" nil "&iquest;" "?" "¿" "¿")
    ("Agrave" "\\`{A}" nil "&Agrave;" "A" "À" "À")
    ("Aacute" "\\'{A}" nil "&Aacute;" "A" "Á" "Á")
    ("Acirc" "\\^{A}" nil "&Acirc;" "A" "Â" "Â")
    ("Atilde" "\\~{A}" nil "&Atilde;" "A" "Ã" "Ã")
    ("Auml" "\\\"{A}" nil "&Auml;" "Ae" "Ä" "Ä")
    ("Aring" "\\AA{}" nil "&Aring;" "A" "Å" "Å")
    ("AA" "\\AA{}" nil "&Aring;" "A" "Å" "Å")
    ("AElig" "\\AE{}" nil "&AElig;" "AE" "Æ" "Æ")
    ("Ccedil" "\\c{C}" nil "&Ccedil;" "C" "Ç" "Ç")
    ("Egrave" "\\`{E}" nil "&Egrave;" "E" "È" "È")
    ("Eacute" "\\'{E}" nil "&Eacute;" "E" "É" "É")
    ("Ecirc" "\\^{E}" nil "&Ecirc;" "E" "Ê" "Ê")
    ("Euml" "\\\"{E}" nil "&Euml;" "E" "Ë" "Ë")
    ("Igrave" "\\`{I}" nil "&Igrave;" "I" "Ì" "Ì")
    ("Iacute" "\\'{I}" nil "&Iacute;" "I" "Í" "Í")
    ("Icirc" "\\^{I}" nil "&Icirc;" "I" "Î" "Î")
    ("Iuml" "\\\"{I}" nil "&Iuml;" "I" "Ï" "Ï")
    ("ETH" "\\DH{}" nil "&ETH;" "D" "Ð" "Ð")
    ("Ntilde" "\\~{N}" nil "&Ntilde;" "N" "Ñ" "Ñ")
    ("Ograve" "\\`{O}" nil "&Ograve;" "O" "Ò" "Ò")
    ("Oacute" "\\'{O}" nil "&Oacute;" "O" "Ó" "Ó")
    ("Ocirc" "\\^{O}" nil "&Ocirc;" "O" "Ô" "Ô")
    ("Otilde" "\\~{O}" nil "&Otilde;" "O" "Õ" "Õ")
    ("Ouml" "\\\"{O}" nil "&Ouml;" "Oe" "Ö" "Ö")
    ("times" "\\texttimes{}" nil "&times;" "*" "×" "×")
    ("Oslash" "\\O" nil "&Oslash;" "O" "Ø" "Ø")
    ("Ugrave" "\\`{U}" nil "&Ugrave;" "U" "Ù" "Ù")
    ("Uacute" "\\'{U}" nil "&Uacute;" "U" "Ú" "Ú")
    ("Ucirc" "\\^{U}" nil "&Ucirc;" "U" "Û" "Û")
    ("Uuml" "\\\"{U}" nil "&Uuml;" "Ue" "Ü" "Ü")
    ("Yacute" "\\'{Y}" nil "&Yacute;" "Y" "Ý" "Ý")
    ("THORN" "\\TH{}" nil "&THORN;" "TH" "Þ" "Þ")
    ("szlig" "\\ss{}" nil "&szlig;" "ss" "ß" "ß")
    ("agrave" "\\`{a}" nil "&agrave;" "a" "à" "à")
    ("aacute" "\\'{a}" nil "&aacute;" "a" "á" "á")
    ("acirc" "\\^{a}" nil "&acirc;" "a" "â" "â")
    ("atilde" "\\~{a}" nil "&atilde;" "a" "ã" "ã")
    ("auml" "\\\"{a}" nil "&auml;" "ae" "ä" "ä")
    ("aring" "\\aa{}" nil "&aring;" "a" "å" "å")
    ("aelig" "\\ae{}" nil "&aelig;" "ae" "æ" "æ")
    ("ccedil" "\\c{c}" nil "&ccedil;" "c" "ç" "ç")
    ("checkmark" "\\checkmark" t "&#10003;" "[checkmark]" "[checkmark]" "✓")
    ("egrave" "\\`{e}" nil "&egrave;" "e" "è" "è")
    ("eacute" "\\'{e}" nil "&eacute;" "e" "é" "é")
    ("ecirc" "\\^{e}" nil "&ecirc;" "e" "ê" "ê")
    ("euml" "\\\"{e}" nil "&euml;" "e" "ë" "ë")
    ("igrave" "\\`{i}" nil "&igrave;" "i" "ì" "ì")
    ("iacute" "\\'{i}" nil "&iacute;" "i" "í" "í")
    ("icirc" "\\^{i}" nil "&icirc;" "i" "î" "î")
    ("iuml" "\\\"{i}" nil "&iuml;" "i" "ï" "ï")
    ("eth" "\\dh{}" nil "&eth;" "dh" "ð" "ð")
    ("ntilde" "\\~{n}" nil "&ntilde;" "n" "ñ" "ñ")
    ("ograve" "\\`{o}" nil "&ograve;" "o" "ò" "ò")
    ("oacute" "\\'{o}" nil "&oacute;" "o" "ó" "ó")
    ("ocirc" "\\^{o}" nil "&ocirc;" "o" "ô" "ô")
    ("otilde" "\\~{o}" nil "&otilde;" "o" "õ" "õ")
    ("ouml" "\\\"{o}" nil "&ouml;" "oe" "ö" "ö")
    ("oslash" "\\o{}" nil "&oslash;" "o" "ø" "ø")
    ("ugrave" "\\`{u}" nil "&ugrave;" "u" "ù" "ù")
    ("uacute" "\\'{u}" nil "&uacute;" "u" "ú" "ú")
    ("ucirc" "\\^{u}" nil "&ucirc;" "u" "û" "û")
    ("uuml" "\\\"{u}" nil "&uuml;" "ue" "ü" "ü")
    ("yacute" "\\'{y}" nil "&yacute;" "y" "ý" "ý")
    ("thorn" "\\th{}" nil "&thorn;" "th" "þ" "þ")
    ("yuml" "\\\"{y}" nil "&yuml;" "y" "ÿ" "ÿ")
    ("fnof" "\\textit{f}" nil "&fnof;" "f" "f" "ƒ")
    ("Alpha" "A" nil "&Alpha;" "Alpha" "Alpha" "Α")
    ("Beta" "B" nil "&Beta;" "Beta" "Beta" "Β")
    ("Gamma" "\\Gamma" t "&Gamma;" "Gamma" "Gamma" "Γ")
    ("Delta" "\\Delta" t "&Delta;" "Delta" "Gamma" "Δ")
    ("Epsilon" "E" nil "&Epsilon;" "Epsilon" "Epsilon" "Ε")
    ("Zeta" "Z" nil "&Zeta;" "Zeta" "Zeta" "Ζ")
    ("Eta" "H" nil "&Eta;" "Eta" "Eta" "Η")
    ("Theta" "\\Theta" t "&Theta;" "Theta" "Theta" "Θ")
    ("Iota" "I" nil "&Iota;" "Iota" "Iota" "Ι")
    ("Kappa" "K" nil "&Kappa;" "Kappa" "Kappa" "Κ")
    ("Lambda" "\\Lambda" t "&Lambda;" "Lambda" "Lambda" "Λ")
    ("Mu" "M" nil "&Mu;" "Mu" "Mu" "Μ")
    ("Nu" "N" nil "&Nu;" "Nu" "Nu" "Ν")
    ("Xi" "\\Xi" t "&Xi;" "Xi" "Xi" "Ξ")
    ("Omicron" "O" nil "&Omicron;" "Omicron" "Omicron" "Ο")
    ("Pi" "\\Pi" t "&Pi;" "Pi" "Pi" "Π")
    ("Rho" "P" nil "&Rho;" "Rho" "Rho" "Ρ")
    ("Sigma" "\\Sigma" t "&Sigma;" "Sigma" "Sigma" "Σ")
    ("Tau" "T" nil "&Tau;" "Tau" "Tau" "Τ")
    ("Upsilon" "\\Upsilon" t "&Upsilon;" "Upsilon" "Upsilon" "Υ")
    ("Phi" "\\Phi" t "&Phi;" "Phi" "Phi" "Φ")
    ("Chi" "X" nil "&Chi;" "Chi" "Chi" "Χ")
    ("Psi" "\\Psi" t "&Psi;" "Psi" "Psi" "Ψ")
    ("Omega" "\\Omega" t "&Omega;" "Omega" "Omega" "Ω")
    ("alpha" "\\alpha" t "&alpha;" "alpha" "alpha" "α")
    ("beta" "\\beta" t "&beta;" "beta" "beta" "β")
    ("gamma" "\\gamma" t "&gamma;" "gamma" "gamma" "γ")
    ("delta" "\\delta" t "&delta;" "delta" "delta" "δ")
    ("epsilon" "\\epsilon" t "&epsilon;" "epsilon" "epsilon" "ε")
    ("varepsilon" "\\varepsilon" t "&epsilon;" "varepsilon" "varepsilon" "ε")
    ("zeta" "\\zeta" t "&zeta;" "zeta" "zeta" "ζ")
    ("eta" "\\eta" t "&eta;" "eta" "eta" "η")
    ("theta" "\\theta" t "&theta;" "theta" "theta" "θ")
    ("iota" "\\iota" t "&iota;" "iota" "iota" "ι")
    ("kappa" "\\kappa" t "&kappa;" "kappa" "kappa" "κ")
    ("lambda" "\\lambda" t "&lambda;" "lambda" "lambda" "λ")
    ("mu" "\\mu" t "&mu;" "mu" "mu" "μ")
    ("nu" "\\nu" t "&nu;" "nu" "nu" "ν")
    ("xi" "\\xi" t "&xi;" "xi" "xi" "ξ")
    ("omicron" "\\textit{o}" nil "&omicron;" "omicron" "omicron" "ο")
    ("pi" "\\pi" t "&pi;" "pi" "pi" "π")
    ("rho" "\\rho" t "&rho;" "rho" "rho" "ρ")
    ("sigmaf" "\\varsigma" t "&sigmaf;" "sigmaf" "sigmaf" "ς")
    ("varsigma" "\\varsigma" t "&sigmaf;" "varsigma" "varsigma" "ς")
    ("sigma" "\\sigma" t "&sigma;" "sigma" "sigma" "σ")
    ("tau" "\\tau" t "&tau;" "tau" "tau" "τ")
    ("upsilon" "\\upsilon" t "&upsilon;" "upsilon" "upsilon" "υ")
    ("phi" "\\phi" t "&phi;" "phi" "phi" "φ")
    ("chi" "\\chi" t "&chi;" "chi" "chi" "χ")
    ("psi" "\\psi" t "&psi;" "psi" "psi" "ψ")
    ("omega" "\\omega" t "&omega;" "omega" "omega" "ω")
    ("thetasym" "\\vartheta" t "&thetasym;" "theta" "theta" "ϑ")
    ("vartheta" "\\vartheta" t "&thetasym;" "theta" "theta" "ϑ")
    ("upsih" "\\Upsilon" t "&upsih;" "upsilon" "upsilon" "ϒ")
    ("piv" "\\varpi" t "&piv;" "omega-pi" "omega-pi" "ϖ")
    ("bull" "\\textbullet{}" nil "&bull;" "*" "*" "•")
    ("bullet" "\\textbullet{}" nil "&bull;" "*" "*" "•")
    ("hellip" "\\dots{}" nil "&hellip;" "..." "..." "…")
    ("dots" "\\dots{}" nil "&hellip;" "..." "..." "…")
    ("prime" "\\prime" t "&prime;" "'" "'" "′")
    ("Prime" "\\prime{}\\prime" t "&Prime;" "''" "''" "″")
    ("oline" "\\overline{~}" t "&oline;" "[overline]" "¯" "‾")
    ("frasl" "/" nil "&frasl;" "/" "/" "⁄")
    ("weierp" "\\wp" t "&weierp;" "P" "P" "℘")
    ("image" "\\Im" t "&image;" "I" "I" "ℑ")
    ("real" "\\Re" t "&real;" "R" "R" "ℜ")
    ("trade" "\\texttrademark{}" nil "&trade;" "TM" "TM" "™")
    ("alefsym" "\\aleph" t "&alefsym;" "aleph" "aleph" "ℵ")
    ("larr" "\\leftarrow" t "&larr;" "<-" "<-" "←")
    ("leftarrow" "\\leftarrow" t "&larr;"  "<-" "<-" "←")
    ("gets" "\\gets" t "&larr;"  "<-" "<-" "←")
    ("uarr" "\\uparrow" t "&uarr;" "[uparrow]" "[uparrow]" "↑")
    ("uparrow" "\\uparrow" t "&uarr;" "[uparrow]" "[uparrow]" "↑")
    ("rarr" "\\rightarrow" t "&rarr;" "->" "->" "→")
    ("to" "\\to" t "&rarr;" "->" "->" "→")
    ("rightarrow" "\\rightarrow" t "&rarr;"  "->" "->" "→")
    ("darr" "\\downarrow" t "&darr;" "[downarrow]" "[downarrow]" "↓")
    ("downarrow" "\\downarrow" t "&darr;" "[downarrow]" "[downarrow]" "↓")
    ("harr" "\\leftrightarrow" t "&harr;" "<->" "<->" "↔")
    ("leftrightarrow" "\\leftrightarrow" t "&harr;"  "<->" "<->" "↔")
    ("crarr" "\\hookleftarrow" t "&crarr;" "<-'" "<-'" "↵")
    ("hookleftarrow" "\\hookleftarrow" t "&crarr;"  "<-'" "<-'" "↵")
    ("lArr" "\\Leftarrow" t "&lArr;" "<=" "<=" "⇐")
    ("Leftarrow" "\\Leftarrow" t "&lArr;" "<=" "<=" "⇐")
    ("uArr" "\\Uparrow" t "&uArr;" "[dbluparrow]" "[dbluparrow]" "⇑")
    ("Uparrow" "\\Uparrow" t "&uArr;" "[dbluparrow]" "[dbluparrow]" "⇑")
    ("rArr" "\\Rightarrow" t "&rArr;" "=>" "=>" "⇒")
    ("Rightarrow" "\\Rightarrow" t "&rArr;" "=>" "=>" "⇒")
    ("dArr" "\\Downarrow" t "&dArr;" "[dbldownarrow]" "[dbldownarrow]" "⇓")
    ("Downarrow" "\\Downarrow" t "&dArr;" "[dbldownarrow]" "[dbldownarrow]" "⇓")
    ("hArr" "\\Leftrightarrow" t "&hArr;" "<=>" "<=>" "⇔")
    ("Leftrightarrow" "\\Leftrightarrow" t "&hArr;" "<=>" "<=>" "⇔")
    ("forall" "\\forall" t "&forall;" "[for all]" "[for all]" "∀")
    ("partial" "\\partial" t "&part;" "[partial differential]" "[partial differential]" "∂")
    ("exist" "\\exists" t "&exist;" "[there exists]" "[there exists]" "∃")
    ("exists" "\\exists" t "&exist;" "[there exists]" "[there exists]" "∃")
    ("empty" "\\empty" t "&empty;" "[empty set]" "[empty set]" "∅")
    ("emptyset" "\\emptyset" t "&empty;" "[empty set]" "[empty set]" "∅")
    ("nabla" "\\nabla" t "&nabla;" "[nabla]" "[nabla]" "∇")
    ("isin" "\\in" t "&isin;" "[element of]" "[element of]" "∈")
    ("in" "\\in" t "&isin;" "[element of]" "[element of]" "∈")
    ("notin" "\\notin" t "&notin;" "[not an element of]" "[not an element of]" "∉")
    ("ni" "\\ni" t "&ni;" "[contains as member]" "[contains as member]" "∋")
    ("prod" "\\prod" t "&prod;" "[product]" "[n-ary product]" "∏")
    ("sum" "\\sum" t "&sum;" "[sum]" "[sum]" "∑")
;   ("minus" "\\minus" t "&minus;" "-" "-" "−")
    ("minus" "-" t "&minus;" "-" "-" "−")
    ("lowast" "\\ast" t "&lowast;" "*" "*" "∗")
    ("ast" "\\ast" t "&lowast;" "*" "*" "*")
    ("radic" "\\sqrt{\\,}" t "&radic;" "[square root]" "[square root]" "√")
    ("prop" "\\propto" t "&prop;" "[proportional to]" "[proportional to]" "∝")
    ("proptp" "\\propto" t "&prop;" "[proportional to]" "[proportional to]" "∝")
    ("infin" "\\propto" t "&infin;" "[infinity]" "[infinity]" "∞")
    ("infty" "\\infty" t "&infin;" "[infinity]" "[infinity]" "∞")
    ("ang" "\\angle" t "&ang;" "[angle]" "[angle]" "∠")
    ("angle" "\\angle" t "&ang;" "[angle]" "[angle]" "∠")
    ("and" "\\wedge" t "&and;" "[logical and]" "[logical and]" "∧")
    ("wedge" "\\wedge" t "&and;" "[logical and]" "[logical and]" "∧")
    ("or" "\\vee" t "&or;" "[logical or]" "[logical or]" "∨")
    ("vee" "\\vee" t "&or;" "[logical or]" "[logical or]" "∨")
    ("cap" "\\cap" t "&cap;" "[intersection]" "[intersection]" "∩")
    ("cup" "\\cup" t "&cup;" "[union]" "[union]" "∪")
    ("int" "\\int" t "&int;" "[integral]" "[integral]" "∫")
;   ("there4" "\\uptherefore" t "&there4;" "[therefore]" "[therefore]" "∴")
    ("there4" "\\therefore" t "&there4;" "[therefore]" "[therefore]" "∴")
    ("sim" "\\sim" t "&sim;" "~" "~" "∼")
    ("cong" "\\cong" t "&cong;" "[approx. equal to]" "[approx. equal to]" "≅")
    ("simeq" "\\simeq" t "&cong;"  "[approx. equal to]" "[approx. equal to]" "≅")
    ("asymp" "\\asymp" t "&asymp;" "[almost equal to]" "[almost equal to]" "≈")
    ("approx" "\\approx" t "&asymp;" "[almost equal to]" "[almost equal to]" "≈")
    ("ne" "\\ne" t "&ne;" "[not equal to]" "[not equal to]" "≠")
    ("neq" "\\neq" t "&ne;" "[not equal to]" "[not equal to]" "≠")
    ("equiv" "\\equiv" t "&equiv;" "[identical to]" "[identical to]" "≡")
    ("le" "\\le" t "&le;" "<=" "<=" "≤")
    ("ge" "\\ge" t "&ge;" ">=" ">=" "≥")
    ("sub" "\\subset" t "&sub;" "[subset of]" "[subset of]" "⊂")
    ("subset" "\\subset" t "&sub;" "[subset of]" "[subset of]" "⊂")
    ("sup" "\\supset" t "&sup;" "[superset of]" "[superset of]" "⊃")
    ("supset" "\\supset" t "&sup;" "[superset of]" "[superset of]" "⊃")
    ("nsub" "\\not\\subset" t "&nsub;" "[not a subset of]" "[not a subset of" "⊄")
    ("sube" "\\subseteq" t "&sube;" "[subset of or equal to]" "[subset of or equal to]" "⊆")
    ("supe" "\\supseteq" t "&supe;" "[superset of or equal to]" "[superset of or equal to]" "⊇")
    ("oplus" "\\oplus" t "&oplus;" "[circled plus]" "[circled plus]" "⊕")
    ("otimes" "\\otimes" t "&otimes;" "[circled times]" "[circled times]" "⊗")
    ("perp" "\\perp" t "&perp;" "[up tack]" "[up tack]" "⊥")
    ("sdot" "\\cdot" t "&sdot;" "[dot]" "[dot]" "⋅")
    ("cdot" "\\cdot" t "&sdot;" "[dot]" "[dot]" "⋅")
    ("lceil" "\\lceil" t "&lceil;" "[left ceiling]" "[left ceiling]" "⌈")
    ("rceil" "\\rceil" t "&rceil;" "[right ceiling]" "[right ceiling]" "⌉")
    ("lfloor" "\\lfloor" t "&lfloor;" "[left floor]" "[left floor]" "⌊")
    ("rfloor" "\\rfloor" t "&rfloor;" "[right floor]" "[right floor]" "⌋")
    ("lang" "\\langle" t "&lang;" "<" "<" "⟨")
    ("rang" "\\rangle" t "&rang;" ">" ">" "⟩")
    ("loz" "\\diamond" t "&loz;" "[lozenge]" "[lozenge]" "◊")
    ("Diamond" "\\diamond" t "&diamond;" "[diamond]" "[diamond]" "⋄")
    ("spades" "\\spadesuit" t "&spades;" "[spades]" "[spades]" "♠")
    ("spadesuit" "\\spadesuit" t "&spades;" "[spades]" "[spades]" "♠")
    ("clubs" "\\clubsuit" t "&clubs;" "[clubs]" "[clubs]" "♣")
    ("clubsuit" "\\clubsuit" t "&clubs;" "[clubs]" "[clubs]" "♣")
    ("hearts" "\\heartsuit" t "&hearts;" "[hearts]" "[hearts]" "♥")
    ("heartsuit" "\\heartsuit" t "&heartsuit;" "[hearts]" "[hearts]" "♥")
    ("diamondsuit" "\\diamondsuit" t "&diams;" "[diamonds]" "[diamonds]" "♦")
    ("diams" "\\diamondsuit" t "&diams;" "[diamonds]" "[diamonds]" "♦")
    ("smile" "\\smile" t "&#9786;" ":-)" ":-)" "⌣")
    ("blacksmile" "\\blacksmiley{}" nil "&#9787;" ":-)" ":-)" "☻")
    ("sad" "\\frownie{}" nil "&#9785;" ":-(" ":-(" "☹")
    ("quot" "\\textquotedbl{}" nil "&quot;" "\"" "\"" "\"")
    ("amp" "\\&" nil "&amp;" "&" "&" "&")
    ("lt" "\\textless{}" nil "&lt;" "<" "<" "<")
    ("gt" "\\textgreater{}" nil "&gt;" ">" ">" ">")
    ("OElig" "\\OE{}" nil "&OElig;" "OE" "OE" "Œ")
    ("oelig" "\\oe{}" nil "&oelig;" "oe" "oe" "œ")
    ("Scaron" "\\v{S}" nil "&Scaron;" "S" "S" "Š")
    ("scaron" "\\v{s}" nil "&scaron;" "s" "s" "š")
    ("Yuml" "\\\"{Y}" nil "&Yuml;" "Y" "Y" "Ÿ")
    ("circ" "\\circ" t "&circ;" "^" "^" "ˆ")
    ("tilde" "\\~{}" nil "&tilde;" "~" "~" "~")
    ("ensp" "\\hspace*{.5em}" nil "&ensp;" " " " " " ")
    ("emsp" "\\hspace*{1em}" nil "&emsp;" " " " " " ")
    ("thinsp" "\\hspace*{.2em}" nil "&thinsp;" " " " " " ")
    ("zwnj" "\\/{}" nil "&zwnj;" "" "" "‌")
    ("zwj" "" nil "&zwj;" "" "" "‍")
    ("lrm" "" nil "&lrm;" "" "" "‎")
    ("rlm" "" nil "&rlm;" "" "" "‏")
    ("ndash" "--" nil "&ndash;" "-" "-" "–")
    ("mdash" "---" nil "&mdash;" "--" "--" "—")
    ("lsquo" "\\textquoteleft{}" nil "&lsquo;" "`" "`" "‘")
    ("rsquo" "\\textquoteright{}" nil "&rsquo;" "'" "'" "’")
    ("sbquo" "\\quotesinglbase{}" nil "&sbquo;" "," "," "‚")
    ("ldquo" "\\textquotedblleft{}" nil "&ldquo;" "\"" "\"" "“")
    ("rdquo" "\\textquotedblright{}" nil "&rdquo;" "\"" "\"" "”")
    ("bdquo" "\\quotedblbase{}" nil "&bdquo;" "\"" "\"" "„")
    ("dagger" "\\textdagger{}" nil "&dagger;" "[dagger]" "[dagger]" "†")
    ("Dagger" "\\textdaggerdbl{}" nil "&Dagger;" "[doubledagger]" "[doubledagger]" "‡")
    ("permil" "\\textperthousand{}" nil "&permil;" "per thousand" "per thousand" "‰")
    ("lsaquo" "\\guilsinglleft{}" nil "&lsaquo;" "<" "<" "‹")
    ("rsaquo" "\\guilsinglright{}" nil "&rsaquo;" ">" ">" "›")
    ("euro" "\\texteuro{}" nil "&euro;" "EUR" "EUR" "€")
    ("EUR" "\\EUR{}" nil "&euro;" "EUR" "EUR" "€")
    ("EURdig" "\\EURdig{}" nil "&euro;" "EUR" "EUR" "€")
    ("EURhv" "\\EURhv{}" nil "&euro;" "EUR" "EUR" "€")
    ("EURcr" "\\EURcr{}" nil "&euro;" "EUR" "EUR" "€")
    ("EURtm" "\\EURtm{}" nil "&euro;" "EUR" "EUR" "€")
    ("arccos" "\\arccos" t "arccos" "arccos" "arccos" "arccos")
    ("arcsin" "\\arcsin" t "arcsin" "arcsin" "arcsin" "arcsin")
    ("arctan" "\\arctan" t "arctan" "arctan" "arctan" "arctan")
    ("arg" "\\arg" t "arg" "arg" "arg" "arg")
    ("cos" "\\cos" t "cos" "cos" "cos" "cos")
    ("cosh" "\\cosh" t "cosh" "cosh" "cosh" "cosh")
    ("cot" "\\cot" t "cot" "cot" "cot" "cot")
    ("coth" "\\coth" t "coth" "coth" "coth" "coth")
    ("csc" "\\csc" t "csc" "csc" "csc" "csc")
    ("deg" "\\deg" t "&deg;" "deg" "deg" "deg")
    ("det" "\\det" t "det" "det" "det" "det")
    ("dim" "\\dim" t "dim" "dim" "dim" "dim")
    ("exp" "\\exp" t "exp" "exp" "exp" "exp")
    ("gcd" "\\gcd" t "gcd" "gcd" "gcd" "gcd")
    ("hom" "\\hom" t "hom" "hom" "hom" "hom")
    ("inf" "\\inf" t "inf" "inf" "inf" "inf")
    ("ker" "\\ker" t "ker" "ker" "ker" "ker")
    ("lg" "\\lg" t "lg" "lg" "lg" "lg")
    ("lim" "\\lim" t "lim" "lim" "lim" "lim")
    ("liminf" "\\liminf" t "liminf" "liminf" "liminf" "liminf")
    ("limsup" "\\limsup" t "limsup" "limsup" "limsup" "limsup")
    ("ln" "\\ln" t "ln" "ln" "ln" "ln")
    ("log" "\\log" t "log" "log" "log" "log")
    ("max" "\\max" t "max" "max" "max" "max")
    ("min" "\\min" t "min" "min" "min" "min")
    ("Pr" "\\Pr" t "Pr" "Pr" "Pr" "Pr")
    ("sec" "\\sec" t "sec" "sec" "sec" "sec")
    ("sin" "\\sin" t "sin" "sin" "sin" "sin")
    ("sinh" "\\sinh" t "sinh" "sinh" "sinh" "sinh")
    ("sup" "\\sup" t "&sup;" "sup" "sup" "sup")
    ("tan" "\\tan" t "tan" "tan" "tan" "tan")
    ("tanh" "\\tanh" t "tanh" "tanh" "tanh" "tanh")
    ("frac12" "\\textonehalf{}" nil "&frac12;" "1/2" "½" "½")
    ("frac14" "\\textonequarter{}" nil "&frac14;" "1/4" "¼" "¼")
    ("frac34" "\\textthreequarters{}" nil "&frac34;" "3/4" "¾" "¾")
    ("div" "\\textdiv{}" nil "&divide;" "/" "÷" "÷")
    ("acute" "\\textasciiacute{}" nil "&acute;" "'" "´" "´")
    ("nsup" "\\not\\supset" t "&nsup;" "[not a superset of]" "[not a superset of]" "⊅")
    ("smiley" "\\smiley{}" nil "&#9786;" ":-)" ":-)" "☺")
    )
  "Default entities used in Org-mode to preduce special characters.
For details see `org-entities-user'.")

(defsubst org-entity-get (name)
  "Get the proper association for NAME from the entity lists.
This first checks the user list, then the built-in list."
  (or (assoc name org-entities-user)
      (assoc name org-entities)))

(defun org-entity-get-representation (name kind)
  "Get the correct representation of entity NAME for export type KIND.
Kind can be any of `latex', `html', `ascii', `latin1', or `utf8'."
  (let* ((e (org-entity-get name))
	 (n (cdr (assq kind '((latex . 1) (html . 3) (ascii . 4)
			      (latin1 . 5) (utf8 . 6)))))
	 (r (and e n (nth n e))))
    (if (and e r
	     (not org-entities-ascii-explanatory)
	     (memq kind '(ascii latin1 utf8))
	     (= (string-to-char r) ?\[))
	(concat "\\" name)
      r)))

(defsubst org-entity-latex-math-p (name)
  "Does entity NAME require math mode in LaTeX?"
  (nth 2 (org-entity-get name)))

;; Helpfunctions to create a table for orgmode.org/worg/org-symbols.org

(defun org-entities-create-table ()
  "Create an org-mode table with all entities."
  (interactive)
  (let ((ll org-entities)
	(pos (point))
	e latex mathp html latin utf8 name ascii)
    (insert "|Name|LaTeX code|LaTeX|HTML code |HTML|ASCII|Latin1|UTF-8\n|-\n")
    (while ll
      (setq e (pop ll))
      (setq name (car e)
	    latex (nth 1 e)
	    mathp (nth 2 e)
	    html (nth 3 e)
	    ascii (nth 4 e)
	    latin (nth 5 e)
	    utf8 (nth 6 e))
      (if (equal ascii "|") (setq ascii "\\vert"))
      (if (equal latin "|") (setq latin "\\vert"))
      (if (equal utf8  "|") (setq utf8  "\\vert"))
      (if (equal ascii "=>") (setq ascii "= >"))
      (if (equal latin "=>") (setq latin "= >"))
      (insert "|" name
	      "|" (format "=%s=" latex)
	      "|" (format (if mathp "$%s$" "$\\mbox{%s}$")
			  latex)
	      "|" (format "=%s=" html) "|" html
	      "|" ascii "|" latin "|" utf8
	      "|\n"))
    (goto-char pos)
    (org-table-align)))

(defun replace-amp ()
  "Postprocess HTML file to unescape the ampersant."
  (interactive)
  (while (re-search-forward "<td>&amp;\\([^<;]+;\\)" nil t)
    (replace-match (concat "<td>&" (match-string 1)) t t)))

(provide 'org-entities)

;; arch-tag: e6bd163f-7419-4009-9c93-a74623016424

;;; org-entities.el ends here
