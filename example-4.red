Red []

#include %qrcode.red
cloak: load %red-logo.png

start: now/time/precise
test-image: qrcode-lib/encode/image/version "https://www.red-lang.org/" cloak 5
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode-lib/encode/correctLevel/version/image/contrast "https://www.red-lang.org/" 3 10 cloak 1.2
end: now/time/precise
print [start end]
view [image test-image]

cloak: load %64_red-logo.png
start: now/time/precise
test-image: qrcode-lib/encode/correctLevel/version/image/contrast "https://www.red-lang.org/" 3 10 cloak 1.2
end: now/time/precise
print [start end]
view [image test-image]

