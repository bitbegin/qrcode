Red []

image-lib: context [
	system/catalog/errors/user: make system/catalog/errors/user [image-lib: ["image-lib [" :arg1 ": (" :arg2 " " :arg3 ")]"]]

	new-error: func [name [word!] arg2 arg3][
		cause-error 'user 'image-lib [name arg2 arg3]
	]

	contrast-enhance: function [img [image!] contrast [float!]][
		if any [
			contrast < 0
			contrast > 2
		][
			new-error 'contrast-enhance 'contrast contrast
		]
		size: img/size
		len: size/x * size/y
		bin: make binary! len
		i: 0
		while [i < size/y][
			j: 0
			while [j < size/x][
				p: i * size/x + j + 1
				append bin contrast-pixel img/(p) contrast
				j: j + 1
			]
			i: i + 1
		]
		make image! reduce [size bin]
	]

	contrast-pixel: function [pixel [tuple!] contrast [float!]][
		r: contrast-one pixel/1 contrast
		g: contrast-one pixel/2 contrast
		b: contrast-one pixel/3 contrast
		ret: make binary! 3
		append ret r
		append ret g
		append ret b
		ret
	]

	contrast-one: function [p [integer!] contrast [float!]][
		np: (to float! p) - 128 * contrast + 128
		case [
			np < 0 [np: 0]
			np > 255 [np: 255]
		]
		to integer! np
	]

	brightness-enhance: function [img [image!] brightness [integer!]][
		if any [
			contrast < 0
			contrast > 255
		][
			new-error 'brightness-enhance 'brightness brightness
		]
		size: img/size
		len: size/x * size/y
		bin: make binary! len
		i: 0
		while [i < size/y][
			j: 0
			while [j < size/x][
				p: i * size/x + j + 1
				append bin brightness-pixel img/(p) brightness
				j: j + 1
			]
			i: i + 1
		]
		make image! reduce [size bin]
	]

	brightness-pixel: function [pixel [tuple!] brightness [integer!]][
		r: brightness-one pixel/1 brightness
		g: brightness-one pixel/2 brightness
		b: brightness-one pixel/3 brightness
		ret: make binary! 3
		append ret r
		append ret g
		append ret b
		ret
	]

	brightness-one: function [p [integer!] brightness [integer!]][
		np: p + brightness
		case [
			np < 0 [np: 0]
			np > 255 [np: 255]
		]
		np
	]

	enlarge: function [img [image!] scale [pair!]][
		size: img/size
		if scale/x <= 0 [
			new-error 'enlarge 'scale scale
		]
		if scale/y <= 0 [
			new-error 'enlarge 'scale scale
		]
		if scale = 1x1 [return copy img]
		width: size/x * scale/x
		height: size/y * scale/y
		len: width * height
		bin: make binary! len
		y: 0
		while [y < size/y][
			x: 0
			line: make binary! width
			while [x < size/x][
				p: img/(make pair! reduce [x + 1 y + 1])
				t: make binary! 3
				append t p/1
				append t p/2
				append t p/3
				append/dup line t scale/x
				x: x + 1
			]
			append/dup bin line scale/y
			y: y + 1
		]
		make image! reduce [to pair! reduce [width height] bin]
	]

	;-- nearest
	resize: function [img [image!] new-size [pair!]][
		size: img/size
		if size = new-size [return copy imgg]
		bin: make binary! new-size/x * new-size/y
		scale-x: (to float! new-size/x) / size/x
		scale-y: (to float! new-size/y) / size/y
		i-scale-x: (to float! size/x) / new-size/x
		i-scale-y: (to float! size/y) / new-size/y

		x-offsets: make block! new-size/x
		i: 0
		while [i < new-size/x][
			x-pos: to integer! i * i-scale-x
			append x-offsets either x-pos < (size/x - 1) [
				x-pos
			][
				size/x - 1
			]
			i: i + 1
		]

		y: 0
		while [y < new-size/y][
			t: to integer! y * i-scale-y
			p: size/x * either t < (size/y - 1) [
				t
			][
				size/y - 1
			]
			x: 0
			while [x < new-size/x][
				t2: x-offsets/(x + 1)
				t3: t * size/x + t2 + 1
				v: img/(t3)
				append bin v/1
				append bin v/2
				append bin v/3
				x: x + 1
			]
			y: y + 1
		]
		make image! reduce [new-size bin]
	]

	grey2: function [img [image!]][
		size: img/size
		bin: make binary! size/x * size/y
		y: 0
		while [y < size/y][
			x: 0
			while [x < size/x][
				p: y * size/x + x
				append bin either 127 <= grey-pixel img/(p + 1) [#{FFFFFF}][#{000000}]
				x: x + 1
			]
			y: y + 1
		]
		make image! reduce [size bin]
	]

	grey: function [img [image!]][
		size: img/size
		bin: make binary! size/x * size/y
		y: 0
		while [y < size/y][
			x: 0
			while [x < size/x][
				p: y * size/x + x
				append/dup bin grey-pixel img/(p + 1) 3
				x: x + 1
			]
			y: y + 1
		]
		make image! reduce [size bin]
	]

	grey-pixel: function [p [tuple!]][
		(p/1 * 299 / 1000) + (p/2 * 587 / 1000) + (p/3 * 114 / 1000)
	]
]
