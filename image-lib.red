Red []

image-lib: context [
	contrast-enhance: function [img [image!] contrast [float!]][
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
]
