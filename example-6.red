Red []

#include %qrcode.red
cloak: load %64_red-logo.png

start: now/time/precise
test-image: qrcode/correctLevel/version/image/scale "https://www.red-lang.org/" 3 1 cloak 9
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode/correctLevel/version/image "https://www.red-lang.org/" 3 7 cloak
end: now/time/precise
print [start end]
view [image test-image]

cloak: load %o_fun.jpg

start: now/time/precise
test-image: qrcode/correctLevel/version/image/scale "https://www.red-lang.org/" 3 1 cloak 9
end: now/time/precise
print [start end]
view [image test-image]
