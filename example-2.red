Red []

#include %qrcode.red
cloak: load %cloak.jpg

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/contrast "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3 1 cloak 1.2
end: now/time/precise
print [start end]
view [image test-image]

cloak: load %o_fun.jpg
start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3 1 cloak
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/scale "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3 1 cloak 4
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/contrast/brightness/scale "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3 1 cloak 1.2 -20 5
end: now/time/precise
print [start end]
view [image test-image]

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/monochrome/scale "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3 1 cloak 5
end: now/time/precise
print [start end]
view [image test-image]

