Red []

#include %qrcode.red
cloak: load %red-logo.png

start: now/time/precise
test-image: qrcode/encode/image/version/colorized "https://www.red-lang.org/" cloak 5
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/colorized/contrast "https://www.red-lang.org/" 3 10 cloak 1.2
end: now/time/precise
print [start end]
view [image test-image]

#include %qrcode.red
cloak: load %64_red-logo.png

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/colorized/contrast "https://www.red-lang.org/" 3 10 cloak 1.2
end: now/time/precise
print [start end]
view [image test-image]

