Red []
#include %qrcode.red
system/catalog/errors/user: make system/catalog/errors/user [qrcode-test: ["qrcode-test [" :arg1 ": (" :arg2 " " :arg3 ")]"]]

new-error: func [name [word!] arg2 arg3][
	cause-error 'user 'qrcode-test [name arg2 arg3]
]

testFiniteFieldMultiply: function [][
	cases: [
		00h 00h 00h
		01h 01h 01h
		02h 02h 04h
		00h 6Eh 00h
		B2h DDh E6h
		41h 11h 25h
		B0h 1Fh 11h
		05h 75h BCh
		52h B5h AEh
		A8h 20h A4h
		0Eh 44h 9Fh
		D4h 13h A0h
		31h 10h 37h
		6Ch 58h CBh
		B6h 75h 3Eh
		FFh FFh E2h
	]
	while [not tail? cases][
		if cases/3 <> qrcode/finite-field-multiply cases/1 cases/2 [
			new-error 'testFiniteFieldMultiply cases/3 reduce [cases/1 cases/2]
		]
		cases: skip cases 3
	]
	true
]

either error? e: try [testFiniteFieldMultiply][
	print "testFiniteFieldMultiply failed!"
	print e
][
	print "testFiniteFieldMultiply ok"
]

testCalcReedSolomonGenerator: function [][
	test-mode: pick [none encode ecc] 3
	generator: qrcode/calc-reed-solomon-generator 1
	unless generator = c: #{01} [
		new-error 'testCalcReedSolomonGenerator 1 reduce [generator c]
	]
	generator: qrcode/calc-reed-solomon-generator 2
	unless generator = c: #{0302} [
		new-error 'testCalcReedSolomonGenerator 2 reduce [generator c]
	]
	generator: qrcode/calc-reed-solomon-generator 5
	unless generator = c: #{1FC63F9374} [
		new-error 'testCalcReedSolomonGenerator 5 reduce [generator c]
	]
	generator: qrcode/calc-reed-solomon-generator 30
	unless all [
		generator/1 = D4h
		generator/2 = F6h
		generator/6 = C0h
		generator/13 = 16h
		generator/14 = D9h
		generator/21 = 12h
		generator/28 = 6Ah
		generator/30 = 96h
	][
		new-error 'testCalcReedSolomonGenerator 30 generator
	]
	true
]

either error? e: try [testCalcReedSolomonGenerator][
	print "testCalcReedSolomonGenerator failed!"
	print e
][
	print "testCalcReedSolomonGenerator ok"
]

testCalcReedSolomonRemainder: function [][
	generator: qrcode/calc-reed-solomon-generator 3
	remainder: qrcode/calc-reed-solomon-remainder #{00} 0 generator
	unless remainder = c: #{000000} [
		new-error 'testCalcReedSolomonRemainder 3 reduce [remainder c]
	]
	generator: qrcode/calc-reed-solomon-generator 4
	remainder: qrcode/calc-reed-solomon-remainder #{0001} 2 generator
	unless remainder = c: generator [
		new-error 'testCalcReedSolomonRemainder 4 reduce [remainder c]
	]
	generator: qrcode/calc-reed-solomon-generator 5
	remainder: qrcode/calc-reed-solomon-remainder #{033A6012C7} 5 generator
	unless remainder = c: #{CB3616FA9D} [
		new-error 'testCalcReedSolomonRemainder 5 reduce [remainder c]
	]
	generator: qrcode/calc-reed-solomon-generator 30
	remainder: qrcode/calc-reed-solomon-remainder #{3871DBF9D728F68EFE5EE67D7DB2A558BC28235314D561C0206CDEDEFC79B08B786B49D01AADF3EF527D9A} 43 generator
	unless all [
		remainder/1 = CEh
		remainder/2 = F0h
		remainder/3 = 31h
		remainder/4 = DEh
		remainder/9 = E1h
		remainder/13 = CAh
		remainder/18 = E3h
		remainder/20 = 85h
		remainder/21 = 50h
		remainder/25 = BEh
		remainder/30 = B3h
	][
		new-error 'testCalcReedSolomonRemainder 30 remainder
	]
	true
]

either error? e: try [testCalcReedSolomonRemainder][
	print "testCalcReedSolomonRemainder failed!"
	print e
][
	print "testCalcReedSolomonRemainder ok"
]

testEncodeData: function [][
	set 'test-mode pick [none encode ecc] 2
	r: qrcode/encode-data data: "01234567" 'H 1 40 1 no
	unless r = c: "000100000010000000001100010101100110000110000000111011000001000111101100" [
		new-error 'testEncodeData data reduce [r c]
	]
	r: qrcode/encode-data data: "AC-42" 'H 1 40 1 no
	unless r = c: "001000000010100111001110111001110010000100000000111011000001000111101100" [
		new-error 'testEncodeData data reduce [r c]
	]
	r: qrcode/encode-data data: "HELLO WORLD" 'Q 1 40 1 no
	unless r = c: "00100000010110110000101101111000110100010111001011011100010011010100001101000000111011000001000111101100" [
		new-error 'testEncodeData data reduce [r c]
	]
	true
]

either error? e: try [testEncodeData][
	print "testEncodeData failed!"
	print e
][
	print "testEncodeData ok"
]


testEcc: function [][
	d: "0100001101010101010001101000011001010111001001100101010111000010011101110011001000000110000100100000011001100111001001101111011011110110010000100000011101110110100001101111001000000111001001100101011000010110110001101100011110010010000001101011011011100110111101110111011100110010000001110111011010000110010101110010011001010010000001101000011010010111001100100000011101000110111101110111011001010110110000100000011010010111001100100001000011101100000100011110110000010001111011000001000111101100"
	h: debase/base d 2
	result: qrcode/encode-ecc h 5 'Q
	ri: [67 246 182 70 85 246 230 247 70 66 247 118 134 7 119 86 87 118 50 194 38 134 7 6 85 242 118 151 194 7 134 50 119 38 87 16 50 86 38 236 6 22 82 17 18 198 6 236 6 199 134 17 103 146 151 236 38 6 50 17 7 236 213 87 148 235 199 204 116 159 11 96 177 5 45 60 212 173 115 202 76 24 247 182 133 147 241 124 75 59 223 157 242 33 229 200 238 106 248 134 76 40 154 27 195 255 117 129 230 172 154 209 189 82 111 17 10 2 86 163 108 131 161 163 240 32 111 120 192 178 39 133 141 236]
	len: length? ri
	rb: make binary! len
	i: 1
	while [i <= len][
		append rb ri/(i)
		i: i + 1
	]
	if result <> rb [
		new-error 'testEcc h reduce [result rb]
	]
	true
]

either error? e: try [testEcc][
	print "testEcc failed!"
	print e
][
	print "testEcc ok"
]
