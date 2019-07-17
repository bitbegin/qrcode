Red []
#include %qrcode.red

start: now/time/precise
test-image: qrcode-lib/encode/correctLevel "bitcoin:n4d8tkDrhF7PcDTPSuUckT927GHonewV7T" 3
end: now/time/precise
print [start end]
view [image test-image]