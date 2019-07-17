Red []

#include %image-lib.red

qrcode: context [
	system/catalog/errors/user: make system/catalog/errors/user [qrcode: ["qrcode [" :arg1 ": (" :arg2 " " :arg3 ")]"]]

	new-error: func [name [word!] arg2 arg3][
		cause-error 'user 'qrcode [name arg2 arg3]
	]

	default-scale: 3

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

	VERSION_MIN: 1
	VERSION_MAX: 40
	REED_SOLOMON_DEGREE_MAX: 30
	max-buffer: function [][
		len: buffer-len? VERSION_MAX
		res: make binary! len
		append/dup res 0 len
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
				if 10 > part-len: length? part-str [
					new-error 'encode-number 'part-len reduce [10 part-len]
				]
				begin: skip part-str part-len - 10
				append bits copy/part begin 10
				item: skip item 3
			][
				either len = 1 [
					part-bin: to binary! to integer! item
					part-str: enbase/base part-bin 2
					if 4 > part-len: length? part-str [
						new-error 'encode-number 'part-len reduce [4 part-len]
					]
					begin: skip part-str part-len - 4
					append bits copy/part begin 4
					item: skip item 1
				][
					part-bin: to binary! to integer! item
					part-str: enbase/base part-bin 2
					if 7 > part-len: length? part-str [
						new-error 'encode-number 'part-len reduce [7 part-len]
					]
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
				if 11 > part-len: length? part-str [
					new-error 'encode-alphanumber 'part-len reduce [11 part-len]
				]
				begin: skip part-str part-len - 11
				append bits copy/part begin 11
				item: skip item 2
			][
				part-bin: to binary! item/1
				part-str: enbase/base part-bin 2
				if 6 > part-len: length? part-str [
					new-error 'encode-alphanumber 'part-len reduce [6 part-len]
				]
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
		max-version		[integer!]
	][
		either string? str [
			bin: to binary! str
		][
			bin: copy str
		]
		if 0 = bin-len: length? bin [
			return reduce [
				'mode 'number
				'num-chars bin-len
				'data ""
			]
		]

		;-- buffer len
		buf-len: buffer-len? max-version
		case [
			number-mode? str [
				unless blen: get-segment-bits 'number bin-len [
					new-error 'get-segment-bits 'number bin-len
				]
				if ((blen + 7) / 8) > buf-len [
					new-error 'encode-data 'buf-len buf-len
				]
				seg: encode-number str
			]
			alphanumber-mode? str [
				unless blen: get-segment-bits 'alphanumber bin-len [
					new-error 'get-segment-bits 'alphanumber bin-len
				]
				if ((blen + 7) / 8) > buf-len [
					new-error 'encode-data 'buf-len buf-len
				]
				seg: encode-alphanumber str
			]
			true [
				if bin-len > buf-len [
					new-error 'encode-data 'buf-len buf-len
				]
				unless blen: get-segment-bits 'byte bin-len [
					new-error 'get-segment-bits 'byte bin-len
				]
				seg: reduce [
					'mode 'byte
					'num-chars bin-len
					'data enbase/base bin 2
				]
			]
		]
		seg
	]

	get-version-info: function [
		version			[integer!]
		ecl				[word!]
	][
		num-blocks: pick NUM_ERROR_CORRECTION_BLOCKS/(ecl) version
		block-ecc-bytes: pick ECC_CODEWORDS_PER_BLOCK/(ecl) version
		modules-bits: get-data-modules-bits version
		cap-bytes: modules-bits / 8 - (num-blocks * block-ecc-bytes)
		reduce [
			'num-blocks num-blocks
			'block-ecc-bytes block-ecc-bytes
			'modules-bits modules-bits
			'cap-bytes cap-bytes
		]
	]

	get-segments-info: function [
		segs			[block!]
		ecl				[word!]
		min-version		[integer!]
		max-version		[integer!]
		boost-ecl?		[logic!]
	][
		unless all [
			VERSION_MIN <= min-version
			min-version <= max-version
			max-version <= VERSION_MAX
		][new-error 'get-segments-info 'version "out of range"]
		unless find error-group ecl [
			new-error 'get-segments-info 'ecl ecl
		]
		version: min-version
		forever [
			cap-bits: 8 * get-data-code-words-bytes version ecl
			unless used-bits: total-bits segs version [
				new-error 'get-segments-info 'used-bits reduce [segs version]
			]
			if all [
				used-bits
				used-bits <= cap-bits
			][break]
			if version >= max-version [
				new-error 'get-segments-info 'version reduce [segs version]
			]
			version: version + 1
		]
		if boost-ecl? [
			ecls: [M Q H]
			forall ecls [
				if used-bits <= (8 * get-data-code-words-bytes version ecls/1) [
					ecl: ecls/1
				]
			]
		]
		res: reduce [
			'version version
			'ecl ecl
			'segments segs
			'used-bits used-bits
		]
		append res get-version-info version ecl
		res
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
			mask >= -1
			mask <= 7
		][new-error 'encode-segments 'mask mask]

		sinfo: get-segments-info segs ecl min-version max-version boost-ecl?
		version: sinfo/version
		ecl: sinfo/ecl
		data-str: build-data-code-words segs sinfo/used-bits version sinfo/cap-bytes
		data-bin: debase/base data-str 2
		code-words: build-code-words-with-ecc data-bin sinfo/modules-bits sinfo/num-blocks sinfo/block-ecc-bytes sinfo/cap-bytes
		code-words-str: enbase/base code-words 2

		;now start to draw
		img: init-func-modules version
		draw-code-words code-words-str img
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
		repend sinfo ['mask mask 'image img]
	]

	build-data-code-words: function [
		segs			[block!]
		used-bits		[integer!]
		version			[integer!]
		cap-bytes		[integer!]
	][
		res: make string! 200
		forall segs [
			mode: segs/1/mode
			data: segs/1/data
			num-chars: segs/1/num-chars
			num-bits: num-char-bits mode version
			part-bin: to binary! num-chars
			part-str: enbase/base part-bin 2
			if num-bits > part-len: length? part-str [
				new-error 'build-data-code-words 'length reduce [num-bits part-len]
			]
			begin: skip part-str part-len - num-bits
			append res rejoin [
				select mode-indicators mode
				copy/part begin num-bits
				segs/1/data
			]
		]
		if used-bits <> (bit-len: length? res) [
			new-error 'build-data-code-words 'used-bits reduce [used-bits bit-len]
		]
		cap-bits: cap-bytes * 8
		if bit-len > cap-bits [
			new-error 'build-data-code-words 'bit-len reduce [bit-len cap-bits]
		]
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
		if 0 <> (bit-len % 8) [
			new-error 'build-data-code-words 'bit-len bit-len
		]
		res-len: (length? res) / 8
		if res-len > cap-bytes [
			new-error 'build-data-code-words 'res-len reduce [res-len  cap-bytes]
		]
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

	build-code-words-with-ecc: function [
		data			[binary!]
		modules-bits	[integer!]
		num-blocks		[integer!]
		block-ecc-bytes	[integer!]
		cap-bytes		[integer!]
	][
		modules-bytes: modules-bits / 8
		num-short-blocks: num-blocks - (modules-bytes % num-blocks)
		short-block-data-len: modules-bytes / num-blocks - block-ecc-bytes
		res: make binary! modules-bytes
		append/dup res 0 modules-bytes

		generator: calc-reed-solomon-generator block-ecc-bytes
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
			j: 1 k: cap-bytes + i
			while [j <= block-ecc-bytes][
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
		][new-error 'calc-reed-solomon-generator 'degree degree]
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
		][new-error 'calc-reed-solomon-remainder 'degree degree]
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
		len: qrsize * qrsize
		data: make string! len
		append/dup data "0" len
		img: reduce [qrsize data]

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

	get-module: function [img [block!] x [integer!] y [integer!]][
		qrsize: img/1
		data: img/2
		index: y * qrsize + x + 1
		data/(index) = #"1"
	]

	get-bit: function [x [integer!] i [integer!]][
		(x >> i and 1) <> 0
	]

	set-module: function [img [block!] x [integer!] y [integer!] black? [logic!]][
		qrsize: img/1
		data: img/2
		index: y * qrsize + x + 1
		data/(index): either black? [#"1"][#"0"]
	]

	set-module-bounded: function [img [block!] x [integer!] y [integer!] black? [logic!]][
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
		img				[block!]
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

	draw-code-words: function [code-words [string!] img [block!]][
		qrsize: img/1
		len: length? code-words
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
						set-module img x y code-words/(i + 1) = #"1"
						i: i + 1
					]
					j: j + 1
				]
				vert: vert + 1
			]
			right: right - 2
		]
	]

	draw-white-func-modules: function [img [block!] version [integer!]][
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

	apply-mask: function [mask-img [block!] img [block!] mask [integer!]][
		qrsize: img/1
		y: 0
		while [y < qrsize][
			x: 0
			while [x < qrsize][
				if get-module mask-img x y [x: x + 1 continue]
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
				val: get-module img x y
				set-module img x y val xor invert
				x: x + 1
			]
			y: y + 1
		]
	]

	draw-format-bits: function [ecl [word!] mask [integer!] img [block!]][
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

	get-penalty-score: function [img [block!]][
		qrsize: img/1
		res: 0.0
		y: 0
		run-history: make binary! 7
		append/dup run-history 0 7
		while [y < qrsize][
			hist: run-history
			loop 7 [
				hist/1: 0
				hist: next hist
			]
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
			hist: run-history
			loop 7 [
				hist/1: 0
				hist: next hist
			]
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

	gen-image: function [img [block!]][
		qrsize: img/1
		len: qrsize * 3 * qrsize * 3
		bin: make binary! len
		x: 0
		while [x < qrsize][
			y: 0
			line: make binary! qrsize * 3
			while [y < qrsize][
				p: either get-module img x y [#{000000}][#{FFFFFF}]
				append line p
				y: y + 1
			]
			append bin line
			x: x + 1
		]
		make image! reduce [to pair! reduce [qrsize qrsize] bin]
	]

	embedded*: function [
		ver [integer!]
		qr-img [image!]
		img [image!]
		colorized? [logic!]
		contrast [float! logic!]
		brightness [integer! logic!]
		scale [integer!]
	][
		if ver >= 7 [
			new-error 'embedded 'version ver
		]
		bg0: img
		if contrast [
			bg0: image-lib/contrast-enhance bg0 contrast
		]
		if brightness [
			bg0: image-lib/brightness-enhance bg0 brightness
		]
		qr-size: qr-img/size
		bg0-size: bg0/size
		;print [qr-img/size bg0/size colorized?]
		new-size-x: either qr-size/x < (4 * either bg0-size/x < bg0-size/y [bg0-size/y][bg0-size/x])[
			qr-size/x - 1 / 4
		][
			either bg0-size/x < bg0-size/y [bg0-size/y][bg0-size/x]
		]
		new-size: either bg0-size/x < bg0-size/y [
			make pair! reduce [
				new-size-x
				new-size-x * (bg0-size/y / bg0-size/x)
			]
		][
			make pair! reduce [
				new-size-x * (bg0-size/x / bg0-size/y)
				new-size-x
			]
		]
		bg0: image-lib/resize bg0 new-size
		bg0-offset: qr-size/x - bg0/size/x / 2
		;print [qr-size bg0/size bg0-offset]

		bg: either colorized? [
			bg0
		][
			image-lib/grey2 bg0
		]

		i: 0
		while [i < qr-size/x][
			j: 0
			while [j < qr-size/y][
				if all [
					i >= bg0-offset
					j >= bg0-offset
					i < (bg0/size/x + bg0-offset)
					j < (bg0/size/x + bg0-offset)
				][
					qr-img/(make pair! reduce [i + 1 j + 1]):
						bg/(make pair! reduce [i - bg0-offset + 1 j - bg0-offset + 1])
				]
				j: j + 1
			]
			i: i + 1
		]
		qr-img
	]

	combine: function [
		ver [integer!]
		qr-img [image!]
		img [image!]
		colorized? [logic!]
		contrast [float! logic!]
		brightness [integer! logic!]
		scale [integer!]
	][
		bg0: img
		if contrast [
			bg0: image-lib/contrast-enhance bg0 contrast
		]
		if brightness [
			bg0: image-lib/brightness-enhance bg0 brightness
		]
		qr-size: qr-img/size
		bg0-size: bg0/size
		;print [qr-img/size bg0/size colorized?]
		new-size-x: either qr-size/x < either bg0-size/x < bg0-size/y [bg0-size/y][bg0-size/x][
			qr-size/x
		][
			either bg0-size/x < bg0-size/y [bg0-size/y][bg0-size/x]
		]
		
		new-size: either bg0-size/x < bg0-size/y [
			make pair! reduce [
				new-size-x
				new-size-x * (bg0-size/y / bg0-size/x)
			]
		][
			make pair! reduce [
				new-size-x * (bg0-size/x / bg0-size/y)
				new-size-x
			]
		]
		bg0: image-lib/resize bg0 new-size
		bg0-offset: qr-size/x - bg0/size/x / 2
		;print [qr-size bg0/size bg0-offset]

		bg: either colorized? [
			bg0
		][
			image-lib/grey2 bg0
		]

		aligns-pos: make block! 16
		if ver > 1 [
			aligns: get-align-pattern-pos ver
			num-align: length? aligns
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
						m: aligns/(i + 1) - 2 * scale
						loop 5 * scale [
							n: aligns/(j + 1) - 2 * scale
							loop 5 * scale [
								repend/only aligns-pos [m n]
								n: n + 1
							]
							m: m + 1
						]
					]
					j: j + 1
				]
				i: i + 1
			]
		]

		scale-mid: make block! scale
		t: scale / 2
		either scale % 2 = 0 [
			append scale-mid t - 1
			append scale-mid t
		][
			append scale-mid t
		]

		time-line: 6 * scale
		time-lines: make block! scale
		tl: time-line
		loop scale [
			append time-lines tl
			tl: tl + 1
		]
		loc-line: 8 * scale
		i: 0
		while [i < qr-size/x][
			j: 0
			while [j < qr-size/y][
				unless all [
					i >= bg0-offset
					j >= bg0-offset
					i < (bg0/size/x + bg0-offset)
					j < (bg0/size/x + bg0-offset)
				][
					j: j + 1
					continue
				]
				unless any [
					find time-lines i
					find time-lines j
					all [
						i < loc-line
						j < loc-line
					]
					all [
						i < loc-line
						j >= (qr-size/y - loc-line)
					]
					all [
						i >= (qr-size/x - loc-line)
						j < loc-line
					]
					all [
						ver >= 7
						any [
							all [
								i < time-line
								j >= (qr-size/y - loc-line - (3 * scale))
							]
							all [
								i >= (qr-size/x - loc-line - (3 * scale))
								j < time-line
							]
						]
					]
					find/only aligns-pos reduce [i j]
					all [
						find scale-mid i % scale
						find scale-mid j % scale
					]
					FFh = pick bg0/(make pair! reduce [i - bg0-offset + 1 j - bg0-offset + 1]) 4
				][
					qr-img/(make pair! reduce [i + 1 j + 1]):
						bg/(make pair! reduce [i - bg0-offset + 1 j - bg0-offset + 1])
				]
				j: j + 1
			]
			i: i + 1
		]
		qr-img
	]

	encode: function [
		data [string! binary!]		"utf8 string! or binary!"
		/correctLevel				"Error correction level (1 - 4)"
			ecc [integer!]
		/version					"QRCode version (1 - 40), min version"
			ver  [integer!]
		/image						"combine an image with the QRCode. The resulting image is black and white by default."
			img  [image!]
		/colorized					"make the resulting image colorized"
		/embedded					"make the image embedded in the qrcode"
		/contrast
			contrast-val [float!]
		/brightness
			brightness-val [integer!]
		/scale
			scale-val [integer!]
		/vector						"generate DRAW commands (TDB)"
		return: [image! block!]
	][
		min-version: 1
		max-version: 40
		if version [
			min-version: ver
		]
		ecc-int: 1 boost?: true
		if correctLevel [
			ecc-int: ecc
			boost?: false
		]
		ecc-word: switch/default ecc-int [
			1	['L]
			2	['M]
			3	['Q]
			4	['H]
		]['L]
		seg: encode-data data max-version
		qr-info: encode-segments reduce [seg] ecc-word min-version max-version -1 boost?
		scale-num: either scale [
			either scale-val < default-scale [default-scale][scale-val]
		][
			default-scale
		]
		qr-img: image-lib/enlarge gen-image qr-info/image make pair! reduce [scale-num scale-num]
		unless image [return qr-img]
		if contrast [
			contrast: contrast-val
		]
		if brightness [
			brightness: brightness-val
		]
		either embedded [
			embedded* qr-info/version qr-img img colorized contrast brightness scale-num
		][
			combine qr-info/version qr-img img colorized contrast brightness scale-num
		]
	]
]

