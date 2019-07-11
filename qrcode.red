Red []

qrcode: context [
	buffer-len?: function [ver [integer!]][
		temp: ver * 4 + 17
		temp: temp * temp / 8 + 1
		temp
	]
	mode-indicators: [
		terminator		{0000}
		fnc1-first		{0101}
		fnc1-second		{1001}
		struct			{0011}
		kanji			{1000}
		byte			{0100}
		alphanumber		{0010}
		number			{0001}
		eci				{0111}
		chinese			{1101}
	]
	padding-bin: [
		{11101100}
		{00010001}
	]
	version-base: 21x21
	version-step: 4x4
	version-end: 40
	VERSION_MIN: 1
	VERSION_MAX: 40
	REED_SOLOMON_DEGREE_MAX: 30
	max-buffer: function [][
		len: buffer-len? VERSION_MAX
		res: make binary! len
		append/dup res 0 len
	]

	get-version-size: function [version [integer!]][
		if version > version-end [return none]
		(version - 1) * version-step + version-base
	]

	error-group: [
		L	7%
		M	15%
		Q	25%
		H	30%
	]

	ECC_CODEWORDS_PER_BLOCK: [
		L	[ 7 10 15 20 26 18 20 24 30 18 20 24 26 30 22 24 28 30 28 28 28 28 30 30 26 28 30 30 30 30 30 30 30 30 30 30 30 30 30 30]
		M	[10 16 26 18 24 16 18 22 22 26 30 22 22 24 24 28 28 26 26 26 26 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28]
		Q	[13 22 18 26 18 24 18 22 20 24 28 26 24 20 30 24 28 28 26 30 28 30 30 30 30 28 30 30 30 30 30 30 30 30 30 30 30 30 30 30]
		H	[17 28 22 16 22 28 26 26 24 28 24 28 22 24 24 30 28 28 26 28 30 24 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30]
	]

	NUM_ERROR_CORRECTION_BLOCKS: [
		L	[ 1  1  1  1  1  2  2  2  2  4  4  4  4  4  6  6  6  6  7  8  8  9  9 10 12 12 12 13 14 15 16 17 18 19 19 20 21 22 24 25]
		M	[ 1  1  1  2  2  4  4  4  5  5  5  8  9  9 10 10 11 13 14 16 17 17 18 20 21 23 25 26 28 29 31 33 35 37 38 40 43 45 47 49]
		Q	[ 1  1  2  2  4  4  6  6  8  8  8 10 12 16 12 17 16 18 21 20 23 23 25 27 29 34 34 35 38 40 43 45 48 51 53 56 59 62 65 68]
		H	[ 1  1  2  4  4  4  5  6  8  8 11 11 16 16 18 16 19 21 25 25 25 34 30 32 35 37 40 42 45 48 51 54 57 60 63 66 70 74 77 81]
	]

	alphanumber: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"

	number-mode?: function [str [string!]][
		forall str [
			int: to integer! str/1
			if any [
				int < 30h
				int > 39h
			][return false]
		]
		true
	]

	alphanumber-mode?: function [str [string!]][
		forall str [
			unless find/case alphanumber str/1 [return false]
		]
		true
	]

	get-data-modules-bits: function [ver [integer!]][
		res: (16 * ver + 128) * ver + 64
		if ver >= 2 [
			align: ver / 7 + 2
			res: res - ((25 * align - 10) * align - 55)
			if ver >= 7 [
				res: res - 36
			]
		]
		res
	]

	get-data-code-words-bytes: function [ver [integer!] ecc-level [word!]][
		ecc-code-words: pick ECC_CODEWORDS_PER_BLOCK/(ecc-level) ver
		num-ecc: pick NUM_ERROR_CORRECTION_BLOCKS/(ecc-level) ver
		res: get-data-modules-bits ver
		res: res / 8 - (ecc-code-words * num-ecc)
		res
	]

	get-segment-bits: function [mode [word!] num-chars [integer!]][
		if num-chars > 32767 [return none]
		res: num-chars
		case [
			mode = 'number [
				res: res * 10 + 2 / 3
			]
			mode = 'alphanumber [
				res: res * 11 + 1 / 2
			]
			mode = 'byte [
				res: res * 8
			]
			mode = 'kanji [
				res: res * 13
			]
			all [
				mode = 'eci
				num-chars = 0
			][
				res: 3 * 8
			]
			true [
				return none
			]
		]
		if res > 32767 [return none]
		res
	]

	encode-number: function [str [string!]][
		str-len: length? str
		item: str
		bits: make string! 64
		while [0 < len: length? item][
			either len >= 3 [
				part: copy/part item 3
				part-bin: to binary! to integer! part
				part-str: enbase/base part-bin 2
				if 10 > part-len: length? part-str [return none]
				begin: skip part-str part-len - 10
				append bits copy/part begin 10
				item: skip item 3
			][
				either len = 1 [
					part-bin: to binary! to integer! item
					part-str: enbase/base part-bin 2
					if 4 > part-len: length? part-str [return none]
					begin: skip part-str part-len - 4
					append bits copy/part begin 4
					item: skip item 1
				][
					part-bin: to binary! to integer! item
					part-str: enbase/base part-bin 2
					if 7 > part-len: length? part-str [return none]
					begin: skip part-str part-len - 7
					append bits copy/part begin 7
					item: skip item 2
				]
			]
		]
		reduce [
			'mode 'number
			'num-chars str-len
			'data bits
		]
	]

	encode-alphanumber: function [str [string!]][
		str-len: length? str
		table: make block! str-len
		forall str [
			index: index? find alphanumber str/1
			append table index - 1
		]
		item: table
		bits: make string! 64
		while [0 < len: length? item][
			either len >= 2 [
				part-bin: to binary! (item/1 * 45 + item/2)
				part-str: enbase/base part-bin 2
				if 11 > part-len: length? part-str [return none]
				begin: skip part-str part-len - 11
				append bits copy/part begin 11
				item: skip item 2
			][
				part-bin: to binary! item/1
				part-str: enbase/base part-bin 2
				if 6 > part-len: length? part-str [return none]
				begin: skip part-str part-len - 6
				append bits copy/part begin 6
				item: skip item 1
			]
		]
		reduce [
			'mode 'alphanumber
			'num-chars str-len
			'data bits
		]
	]

	encode-data: function [
		str				[string! binary!]
		ecl				[word!]
		min-version		[integer!]
		max-version		[integer!]
		mask			[integer!]
		boost-ecl?		[logic!]
	][
		either string? str [
			bin: to binary! str
		][
			bin: copy str
		]
		bin-len: length? bin
		;-- TODO: len 0

		;-- buffer len
		buf-len: buffer-len? max-version
		case [
			number-mode? str [
				unless blen: get-segment-bits 'number bin-len [return none]
				if ((blen + 7) / 8) > buf-len [return none]
				seg: encode-number str
			]
			alphanumber-mode? str [
				unless blen: get-segment-bits 'alphanumber bin-len [return none]
				if ((blen + 7) / 8) > buf-len [return none]
				seg: encode-alphanumber str
			]
			true [
				if bin-len > buf-len [return none]
				unless blen: get-segment-bits 'byte bin-len [return none]
				seg: reduce [
					'mode 'byte
					'num-chars bin-len
					'data enbase/base bin 2
				]
			]
		]
		encode-segments reduce [seg] ecl min-version max-version mask boost-ecl?
	]

	encode-segments: function [
		segs			[block!]
		ecl				[word!]
		min-version		[integer!]
		max-version		[integer!]
		mask			[integer!]
		boost-ecl?		[logic!]
	][
		unless all [
			VERSION_MIN <= min-version
			min-version <= max-version
			max-version <= VERSION_MAX
		][return none]
		unless find error-group ecl [return none]
		unless all [
			mask >= -1
			mask <= 7
		][return none]

		version: min-version
		forever [
			cap-bits: 8 * get-data-code-words-bytes version ecl
			unless used-bits: total-bits segs version [
				return none
			]
			if all [
				used-bits
				used-bits <= cap-bits
			][break]
			if version >= max-version [return none]
			version: version + 1
		]
		if boost-ecl? [
			ecls: [M Q H]
			forall ecls [
				if used-bits <= 8 * get-data-code-words-bytes version ecls/1 [
					ecl: ecls/1
				]
			]
		]
		unless qrcode: encode-padding segs used-bits version ecl [
			return none
		]
		if test-mode = 'encode [return qrcode]
		qrcode: debase/base qrcode 2
		code-words: encode-ecc qrcode version ecl
		if test-mode = 'ecc [return code-words]

		;now start to draw
		img: init-func-modules version
		;draw-code-words code-words (get-data-modules-bits version) / 8 img
		draw-code-words code-words img
		draw-white-func-modules img version
		mask-img: init-func-modules version
		if mask = -1 [
			min-penalty: none
			i: 0
			while [i < 8][
				msk: i
				apply-mask mask-img img msk
				draw-format-bits ecl msk img
				penalty: get-penalty-score img
				if any [
					min-penalty = none
					penalty < min-penalty
				][
					mask: msk
					min-penalty: penalty
				]
				apply-mask mask-img img msk
				i: i + 1
			]
		]
		apply-mask mask-img img mask
		draw-format-bits ecl mask img
		img
	]

	encode-padding: function [
		segs			[block!]
		used-bits		[integer!]
		version			[integer!]
		ecl				[word!]
	][
		res: make string! 200
		forall segs [
			mode: segs/1/mode
			data: segs/1/data
			num-chars: segs/1/num-chars
			num-bits: num-char-bits mode version
			part-bin: to binary! num-chars
			part-str: enbase/base part-bin 2
			if num-bits > part-len: length? part-str [return none]
			begin: skip part-str part-len - num-bits
			append res rejoin [
				select mode-indicators mode
				copy/part begin num-bits
				segs/1/data
			]
		]
		if used-bits <> (bit-len: length? res) [return none]
		cap-bytes: get-data-code-words-bytes version ecl
		cap-bits: 8 * cap-bytes
		if bit-len > cap-bits [return none]
		if 4 < terminator-bits: cap-bits - bit-len [
			terminator-bits: 4
		]
		append/dup res "0" terminator-bits
		res-len: length? res
		m: res-len % 8
		if m <> 0 [
			append/dup res "0" 8 - m
		]
		bit-len: length? res
		if 0 <> (bit-len % 8) [return none]
		res-len: (length? res) / 8
		if res-len > cap-bytes [return none]
		if res-len = cap-bytes [return res]
		pad-index: 1
		loop cap-bytes - res-len [
			append res padding-bin/(pad-index)
			either pad-index = 1 [
				pad-index: 2
			][
				pad-index: 1
			]
		]
		res
	]

	encode-ecc: function [
		data			[binary!]
		version			[integer!]
		ecl				[word!]
	][
		num-blocks: pick NUM_ERROR_CORRECTION_BLOCKS/(ecl) version
		block-ecc-len: pick ECC_CODEWORDS_PER_BLOCK/(ecl) version
		raw-code-words: (get-data-modules-bits version) / 8
		data-len: get-data-code-words-bytes version ecl
		num-short-blocks: num-blocks - (raw-code-words % num-blocks)
		short-block-data-len: raw-code-words / num-blocks - block-ecc-len
		res: make binary! raw-code-words
		append/dup res 0 raw-code-words

		generator: calc-reed-solomon-generator block-ecc-len
		dat: data
		i: 1
		while [i <= num-blocks][
			dlen: short-block-data-len + either i <= num-short-blocks [0][1]
			ecc: calc-reed-solomon-remainder dat dlen generator
			j: 1 k: i
			while [j <= dlen][
				if j = (short-block-data-len + 1) [
					k: k - num-short-blocks
				]
				res/(k): dat/(j)
				j: j + 1
				k: k + num-blocks
			]
			j: 1 k: data-len + i
			while [j <= block-ecc-len][
				res/(k): ecc/(j)
				j: j + 1
				k: k + num-blocks
			]
			dat: skip dat dlen
			i: i + 1
		]
		res
	]

	calc-reed-solomon-generator: function [degree [integer!]][
		unless all [
			degree >= 1
			degree <= REED_SOLOMON_DEGREE_MAX
		][return none]
		res: make binary! degree
		append/dup res 0 degree
		res/(degree): 1

		root: 1
		i: 1
		while [i <= degree][
			j: 1
			while [j <= degree][
				res/(j): finite-field-multiply res/(j) root
				if j < degree [
					res/(j): res/(j) xor res/(j + 1)
				]
				j: j + 1
			]
			root: finite-field-multiply root 2
			i: i + 1
		]
		res
	]

	calc-reed-solomon-remainder: function [data [binary!] data-len [integer!] generator [binary!]][
		degree: length? generator
		unless all [
			degree >= 1
			degree <= REED_SOLOMON_DEGREE_MAX
		][return none]
		res: make binary! degree
		append/dup res 0 degree
		i: 1
		while [i <= data-len][
			factor: data/(i) xor res/1
			res: skip res 1
			append res 0
			j: 1
			while [j <= degree][
				res/(j): res/(j) xor finite-field-multiply generator/(j) factor
				j: j + 1
			]
			i: i + 1
		]
		res
	]

	finite-field-multiply: function [x [integer!] y [integer!]][
		z: 0
		i: 7
		while [i >= 0][
			z: (z << 1 and FFh) xor ((z >> 7) * 11Dh and FFh)
			z: z xor ((y >> i and 1) * x)
			i: i - 1
		]
		z and FFh
	]

	total-bits: function [
		segs			[block!]
		version			[integer!]
	][
		len: length? segs
		res: 0
		forall segs [
			num-chars: segs/1/num-chars
			bit-len: length? segs/1/data
			unless cc-bits: num-char-bits segs/1/mode version [
				return none
			]
			if num-chars >= (1 << cc-bits) [
				return none
			]
			res: res + 4 + cc-bits + bit-len
			if res > 32767 [return none]
		]
		res
	]
	num-char-bits: function [
		mode			[word!]
		ver				[integer!]
	][
		if mode = 'number [
			if ver <= 9 [return 10]
			if ver <= 26 [return 12]
			if ver <= 40 [return 14]
			return none
		]
		if mode = 'alphanumber [
			if ver <= 9 [return 9]
			if ver <= 26 [return 11]
			if ver <= 40 [return 13]
			return none
		]
		if mode = 'byte [
			if ver <= 9 [return 8]
			if ver <= 26 [return 16]
			if ver <= 40 [return 16]
			return none
		]
		if mode = 'kanji [
			if ver <= 9 [return 8]
			if ver <= 26 [return 10]
			if ver <= 40 [return 12]
			return none
		]
		none
	]

	init-func-modules: function [version [integer!]][
		qrsize: version * 4 + 17
		len: qrsize * qrsize + 7 / 8 + 1
		img: make binary! len
		append/dup img 0 len
		img/1: qrsize

		;-- timing patterns
		fill-rect 6 0 1 qrsize img
		fill-rect 0 6 qrsize 1 img

		;-- finder patterns
		fill-rect 0 0 9 9 img
		fill-rect qrsize - 8 0 8 9 img
		fill-rect 0 qrsize - 8 9 8 img

		aligns: get-align-pattern-pos version
		num-align: either aligns [length? aligns][0]
		i: 0
		while [i < num-align][
			j: 0
			while [j < num-align][
				unless any [
					all [
						i = 0
						j = 0
					]
					all [
						i = 0
						j = (num-align - 1)
					]
					all [
						i = (num-align - 1)
						j = 0
					]
				][
					fill-rect aligns/(i + 1) - 2 aligns/(j + 1) - 2 5 5 img
				]
				j: j + 1
			]
			i: i + 1
		]

		;-- version block
		if version >= 7 [
			fill-rect qrsize - 11 0 3 6 img
			fill-rect 0 qrsize - 11 6 3 img
		]
		img
	]

	get-module: function [img [binary!] x [integer!] y [integer!]][
		qrsize: img/1
		index: y * qrsize + x
		get-bit img/(index >> 3 + 1 + 1) index and 7
	]

	get-bit: function [x [integer!] i [integer!]][
		(x >> i and 1) <> 0
	]

	set-module: function [img [binary!] x [integer!] y [integer!] black? [logic!]][
		qrsize: img/1
		index: y * qrsize + x
		bit-index: index and 7
		byte-index: index >> 3 + 1
		either black? [
			img/(byte-index + 1): img/(byte-index + 1) or (1 << bit-index)
		][
			img/(byte-index + 1): img/(byte-index + 1) and (1 << bit-index xor FFh)
		]
	]

	set-module-bounded: function [img [binary!] x [integer!] y [integer!] black? [logic!]][
		qrsize: img/1
		if all [
			x >= 0
			x < qrsize
			y >= 0
			y < qrsize
		][
			set-module img x y black?
		]
	]

	fill-rect: function [
		left			[integer!]
		top				[integer!]
		width			[integer!]
		heigth			[integer!]
		img				[binary!]
	][
		dy: 0
		while [dy < heigth][
			dx: 0
			while [dx < width][
				set-module img left + dx top + dy true
				dx: dx + 1
			]
			dy: dy + 1
		]
	]

	get-align-pattern-pos: function [version [integer!]][
		if version = 1 [return none]
		num-align: version / 7 + 2
		res: make binary! num-align
		append/dup res 0 num-align
		step: either version = 32 [26][
			(version * 4 + (num-align * 2) + 1) / (num-align * 2 - 2) * 2
		]
		i: num-align - 1
		pos: version * 4 + 10
		while [i >= 1][
			res/(i + 1): pos
			i: i - 1
			pos: pos - step
		]
		res/1: 6
		res
	]

	draw-code-words: function [data [binary!] img [binary!]][
		qrsize: img/1
		len: length? data
		i: 0
		right: qrsize - 1
		while [right >= 1][
			if right = 6 [right: 5]
			vert: 0
			while [vert < qrsize][
				j: 0
				while [j < 2][
					x: right - j
					upward: (right + 1 and 2) = 0
					y: either upward [qrsize - 1 - vert][vert]
					if all [
						not get-module img x y
						i < (len * 8)
					][
						black?: get-bit data/(i >> 3 + 1) 7 - (i and 7)
						set-module img x y black?
						i: i + 1
					]
					j: j + 1
				]
				vert: vert + 1
			]
			right: right - 2
		]
	]

	draw-white-func-modules: function [img [binary!] version [integer!]][
		qrsize: img/1
		i: 7
		;-- timing patterns
		while [i < (qrsize - 7)][
			set-module img 6 i false
			set-module img i 6 false
			i: i + 2
		]

		;-- finder patterns
		dy: -4
		while [dy <= 4][
			dx: -4
			while [dx <= 4][
				dist: absolute dx
				if (absolute dy) > dist [
					dist: absolute dy
				]
				if any [
					dist = 2
					dist = 4
				][
					set-module-bounded img 3 + dx 3 + dy false
					set-module-bounded img qrsize - 4 + dx 3 + dy false
					set-module-bounded img 3 + dx qrsize - 4 + dy false
				]
				dx: dx + 1
			]
			dy: dy + 1
		]

		;-- align patterns
		aligns: get-align-pattern-pos version
		num-align: either aligns [length? aligns][0]
		i: 0
		while [i < num-align][
			j: 0
			while [j < num-align][
				if any [
					all [
						i = 0
						j = 0
					]
					all [
						i = 0
						j = (num-align - 1)
					]
					all [
						i = (num-align - 1)
						j = 0
					]
				][
					j: j + 1
					continue
				]
				dy: -1
				while [dy <= 1][
					dx: -1
					while [dx <= 1][
						black?: either all [dx = 0 dy = 0][true][false]
						set-module img aligns/(i + 1) + dx aligns/(j + 1) + dy black?
						dx: dx + 1
					]
					dy: dy + 1
				]
				j: j + 1
			]
			i: i + 1
		]

		;-- version blocks
		if version >= 7 [
			rem: version
			i: 0
			while [i < 12][
				rem: (rem << 1) xor (rem >> 11 * 1F25h)
				i: i + 1
			]
			bits: version << 12 or rem
			i: 0
			while [i < 6][
				j: 0
				while [j < 3][
					k: qrsize - 11 + j
					black?: (bits and 1) <> 0
					set-module img k i black?
					set-module img i k black?
					bits: bits >> 1
					j: j + 1
				]
				i: i + 1
			]
		]
	]

	apply-mask: function [func-modules [binary!] mask-img [binary!] mask [integer!]][
		qrsize: mask-img/1
		y: 0
		while [y < qrsize][
			x: 0
			while [x < qrsize][
				if get-module func-modules x y [x: x + 1 continue]
				invert: true
				switch mask [
					0	[invert: (x + y % 2) = 0]
					1	[invert: (y % 2) = 0]
					2	[invert: (x % 3) = 0]
					3	[invert: (x + y % 3) = 0]
					4	[invert: (x / 3 + (y / 2) % 2) = 0]
					5	[invert: (x * y % 2 + (x * y % 3)) = 0]
					6	[invert: (x * y % 2 + (x * y % 3) % 2) = 0]
					7	[invert: (x + y % 2 + (x * y % 3) % 2) = 0]
				]
				val:  get-module mask-img x y
				set-module mask-img x y val xor invert
				x: x + 1
			]
			y: y + 1
		]
	]

	draw-format-bits: function [ecl [word!] mask [integer!] img [binary!]][
		table: [L 1 M 0 Q 3 H 2]
		data: table/(ecl) << 3 or mask
		rem: data
		loop 10 [
			rem: (rem << 1) xor (rem >> 9 * 0537h)
		]
		bits: (data << 10 or rem) xor 5412h
		i: 0
		while [i <= 5][
			set-module img 8 i get-bit bits i
			i: i + 1
		]
		set-module img 8 7 get-bit bits 6
		set-module img 8 8 get-bit bits 7
		set-module img 7 8 get-bit bits 8
		i: 9
		while [i < 15][
			set-module img 14 - i 8 get-bit bits i
			i: i + 1
		]
		qrsize: img/1
		i: 0
		while [i < 8][
			set-module img qrsize - 1 - i 8 get-bit bits i
			i: i + 1
		]
		i: 8
		while [i < 15][
			set-module img 8 qrsize - 15 + i get-bit bits i
			i: i + 1
		]
		set-module img 8 qrsize - 8 true
	]

	PENALTY_N1:  3
	PENALTY_N2:  3
	PENALTY_N3: 40
	PENALTY_N4: 10

	get-penalty-score: function [img [binary!]][
		qrsize: img/1
		res: 0.0
		y: 0
		while [y < qrsize][
			run-history: make binary! 7
			append/dup run-history 0 7
			color: false
			run-x: 0
			x: 0
			while [x < qrsize][
				either color = get-module img x y [
					run-x: run-x + 1
					either run-x = 5 [
						res: res + PENALTY_N1
					][
						if run-x > 5 [
							res: res + 1
						]
					]
				][
					add-run-to-history run-x run-history
					if all [
						not color
						has-finder-like-pattern run-history
					][
						res: res + PENALTY_N3
					]
					color: get-module img x y
					run-x: 1
				]
				x: x + 1
			]
			add-run-to-history run-x run-history
			if color [
				add-run-to-history 0 run-history
			]
			if has-finder-like-pattern run-history [
				res: res + PENALTY_N3
			]
			y: y + 1
		]

		x: 0
		while [x < qrsize][
			run-history: make binary! 7
			append/dup run-history 0 7
			color: false
			run-y: 0
			y: 0
			while [y < qrsize][
				either color = get-module img x y [
					run-y: run-y + 1
					either run-y = 5 [
						res: res + PENALTY_N1
					][
						if run-y > 5 [
							res: res + 1
						]
					]
				][
					add-run-to-history run-y run-history
					if all [
						not color
						has-finder-like-pattern run-history
					][
						res: res + PENALTY_N3
					]
					color: get-module img x y
					run-y: 1
				]
				y: y + 1
			]
			add-run-to-history run-y run-history
			if color [
				add-run-to-history 0 run-history
			]
			if has-finder-like-pattern run-history [
				res: res + PENALTY_N3
			]
			x: x + 1
		]

		y: 0
		while [y < (qrsize - 1)][
			x: 0
			while [x < (qrsize - 1)][
				color: get-module img x y
				if all [
					color = get-module img x + 1 y
					color = get-module img x y + 1
					color = get-module img x + 1 y + 1
				][
					res: res + PENALTY_N2
				]
				x: x + 1
			]
			y: y + 1
		]

		black: 0
		y: 0
		while [y < qrsize][
			x: 0
			while [x < qrsize][
				if get-module img x y [
					black: black + 1
				]
				x: x + 1
			]
			y: y + 1
		]
		total: to float! qrsize * qrsize
		k: (absolute ((to float! black) * 20 - (total * 10))) + total - 1 / total - 1
		res: res + (k * PENALTY_N4)
		res
	]

	add-run-to-history: function [run [integer!] history [binary!]][
		insert history run
		remove back tail history
	]

	has-finder-like-pattern: function [history [binary!]][
		n: history/2
		either all [
			n > 0
			history/3 = n
			history/5 = n
			history/6 = n
			history/4 = (n * 3)
			any [
				history/1 >= (n * 4)
				history/7 >= (n * 4)
			]
		][true][false]
	]

	to-image: function [img [binary!] scale [integer!]][
		qrsize: img/1
		len: qrsize * 3 * qrsize * 3
		bin: make binary! len
		;append/dup bin 0 len
		x: 0
		while [x < qrsize][
			y: 0
			line: make binary! qrsize * 3 * scale
			while [y < qrsize][
				p: either get-module img x y [#{000000}][#{FFFFFF}]
				append/dup line p scale
				y: y + 1
			]
			append/dup bin line scale
			x: x + 1
		]
		make image! reduce [to pair! reduce [qrsize * scale qrsize * scale] bin]
	]
]

set 'test-mode pick [none encode ecc] 1
start: now/time/precise
img: qrcode/encode-data data: "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 'H 1 40 -1 no
test-image: qrcode/to-image img 4
end: now/time/precise
print [start end]
view [image test-image]