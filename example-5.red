Red []

#include %qrcode.red
cloak: load %64_red-logo.png

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/colorized/embedded/contrast/scale "https://www.red-lang.org/" 3 1 cloak 1.2 9
end: now/time/precise
print [start end]
view [image test-image]
