Red []

#include %qrcode.red
cloak: load %cloak.jpg

start: now/time/precise
test-image: qrcode/encode/correctLevel/version/image/colorized/contrast "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3 20 cloak 1.2
end: now/time/precise
print [start end]
view [image test-image]
