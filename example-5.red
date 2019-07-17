Red [
	Needs: 'View
]

#include %qrcode.red
cloak: load %64_red-logo.png

start: now/time/precise
test-image: qrcode-lib/encode/correctLevel/version/image/embedded/contrast/scale "https://www.red-lang.org/" 3 1 cloak 1.2 9
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode-lib/encode/correctLevel/version/image/embedded/contrast/scale/color "https://www.red-lang.org/" 3 1 cloak 1.2 9 255.0.0
end: now/time/precise
print [start end]
view [image test-image]
