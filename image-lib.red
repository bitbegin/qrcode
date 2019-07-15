Red []

image-lib: context [
	contrast-enhance: function [img [image!] brightness [integer!] contrast [integer!]][
		size: img/size
		len: size/x * size/y
		bin: make binary! len
		i: 0
		while [i < size/y][
			j: 0
			while [j < size/x][
				p: i * size/x + j + 1
				append bin contrast-pixel img/(p) brightness contrast
				j: j + 1
			]
			i: i + 1
		]
		make image! reduce [size bin]
	]

	contrast-pixel: function [pixel [tuple!] brightness [integer!] contrast [integer!]][
		r: pixel/1 g: pixel/2 b: pixel/3
		nr: r - 127  * contrast + 127 + brightness
		ng: g - 127  * contrast + 127 + brightness
		nb: b - 127  * contrast + 127 + brightness
		ret: make binary! 3
		append ret nr
		append ret ng
		append ret nb
		ret
	]
]
