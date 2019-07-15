Red []
#include %image-lib.red

cloak: load %cloak.jpg
new-image: copy cloak
resize-img: copy cloak
view [
	image cloak
	img: image new-image
	return
	button "up brightness" [
		img/image: image-lib/brightness-enhance img/image 2
	]
	button "down brightness" [
		img/image: image-lib/brightness-enhance img/image -2
	]
	return
	button "up contrast" [
		img/image: image-lib/contrast-enhance img/image 1.2
	]
	button "down contrast" [
		img/image: image-lib/contrast-enhance img/image 0.8
	]
	return

	button "up width" [
		size: resize-img/size
		resize-img: image-lib/resize resize-img make pair! reduce [size/x + 5 size/y]
		view [image cloak image resize-img]
	]
	button "down width" [
		size: resize-img/size
		resize-img: image-lib/resize resize-img make pair! reduce [size/x - 5 size/y]
		view [image cloak image resize-img]
	]
	button "up height" [
		size: resize-img/size
		resize-img: image-lib/resize resize-img make pair! reduce [size/x size/y + 5]
		view [image cloak image resize-img]
	]
	button "down height" [
		size: resize-img/size
		resize-img: image-lib/resize resize-img make pair! reduce [size/x size/y - 5]
		view [image cloak image resize-img]
	]
]
