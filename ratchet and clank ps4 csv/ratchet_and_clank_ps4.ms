--sleepyzay--

fn paddstring len instring = (
	instring=instring as string
	local str=""
	if instring.count <=len then (
		for i = 1 to (len-instring.count) do(
			str+="0"
		)
		str = (str+instring)
	)
	else (
		for i = 1 to len do(
			str+="0";str[i]=instring[i]
		)
	)
	str
)
fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)
fn ReadFixedString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str0 = ReadByte bstream #unsigned
      If str0!=0xFD AND str0!=0xFC do str+= bit.intAsChar str0
   )
   str
)
fn ReadFixedByteString bstream fixedLen var var2 = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   if var == 1 do fseek bstream -fixedLen #seek_cur
   if var2 == 1 do print str
)
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn getString bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn ReadHalfFloat fstream = (
    hf=readshort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
return bit.intasfloat outputasfloat*2
)
fn getVal bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newVal = readbelong f
	fseek bstream backJump #seek_set
	return newVal
)
fn signVal x size= (
	if (bit.get x size) do (
		bitMask = 0
		for i=1 to size do bitMask = bit.set bitMask i true
		
		x = bit.xor x bitMask
		x += 1	--because of 2's complement
		x *= -1
	)
	return x
)
fn readbits pos range num = (
	local i = 0, result = 0, c = 1
	local val = num
	for i = pos to ((pos - 1) + range) do (
		result = bit.set result c (bit.get val i);c+=1
		)
	result
)
fn unpackNormal format divisor val = (
	result = [0,0,0]
	pos = 1
	for x=1 to 3 do (
		result[x] = ((readBits pos format[x] val) / divisor) * 2 - 2
		pos+=format[x]
	)
	result
)

fname = GetOpenFileName caption:"" types:" (*.model)|*.model" historyCategory:""
-- fname = @"C:\Users\Owner\Desktop\rnc\Image0\asset_archive\character\hero\hero_ratchet\hero_ratchet_preview.model"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct table (
	Type = readshort f #unsigned,	--max wont read this as a long so I just split it in to two shorts
	Type2 = readshort f #unsigned,
	Offset = readlong f #unsigned,
	Length = readlong f #unsigned
)
struct meshInfo (
	ukwFloat = readfloat f,
	ukwFloat2 = readfloat f,
	ukwFloat3 = readfloat f,
	ukwFloat4 = readfloat f,
	vertOffset = readlong f,
	faceOffset = readlong f,
	faceCount = readlong f,
	vertCount = readshort f,
	ukw = readshort f,							--starts from 0, increases by 0x10 / offset?
	ukw2 = readshort f,						--always 0x11 / 0x10
	matID = readshort f,
	bindTableOffset = readshort f,
	bindTableCount = readshort f,
	
	ukw6 = readshort f,						--count? / offset? / polyElm related?
	ukwByte = readbyte f,
	vertInfoTableCount = readbyte f,
	polyElmIndex = readshort f,
	vertInfoTableOffset = readshort f,
	
	ukwFloat5 = readfloat f,
	ukwFloat6 = readfloat f,
	ukwFloat7 = readfloat f,
	null = readlong f
)
struct boneInfo (
	parentID = readshort f,
	ukwID2 = readshort f,		--sibling / child
	ukwID3 = readshort f,		--sibling / child
	ukwID4 = readshort f,		--sibling / child
	boneHash = readlong f,
	boneName = getString f (readlong f)
)
struct polyElmInfo (
	ukwFloat = readfloat f,	--may not be float
	ukwFloat2 = readfloat f,
	ukwFloat3 = readfloat f,
	ukwFloat4 = readfloat f,
	ukwFloat5 = readfloat f,
	ukwFloat6 = readfloat f,
	ukwFloat7 = readfloat f,
	faceOffset = readlong f,
	faceCount = readlong f
)
struct matInfo (
	path =  (getString f (readlong f)),
	name =  (getString f (readlong f)),
	null = (fseek f 0x18 #seek_cur)
)
struct weight_data (
	boneids,weights
)
 
_1TAD = ReadFixedString f 4
fileTypeHash = readlong f
fileLength = readlong f
tableCount = readlong f

dataArray=#()
for x=1 to tableCount do (
	append dataArray(
		_table = table()
	)
)

vertBufferOffset = 0
uvBufferOffset = 0
bindDataTableOffset = 0
bindDataBufferOffset = 0
vertInfoTableOffset = 0
faceBufferOffset = 0
boneOffset = 0
boneCount = 0
matCount = 0

meshDataArray=#()
boneDataArray=#()
polyElmDataArray=#()
matDataArray=#()
for x=1 to tableCount do (--)
	data = dataArray[x]
	fseek f data.Offset #seek_set
	case data.type of (
		0x7efc:(	--unknown
-- 			format "0x7efc offset: %	length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length as integer))
			ReadFixedByteString f 0x10 0 0
		)
		0x863d:(	--faceBufferOffset
			faceBufferOffset = ftell f
-- 			format "faceBufferOffset: % faceBufferCount: % faceBufferLength: %\n" (bit.intashex((data.Offset) as integer)) (bit.intashex((data.Length / 2) as integer)) (bit.intashex((data.Length) as integer))
		)
		0xa708:(	--unknown table
			ukwTableCount = readlong f
-- 			format "0xa708 offset: % count: %	length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(ukwTableCount as integer)) (bit.intashex(ukwTableCount * 0x14 as integer))
			fseek f 0x0c #seek_cur	--might just be byte aligned
			for y=1 to ukwTableCount do (
				ReadFixedByteString f 0x14 1 0
				ukwFloat = readfloat f
				ukwFloat2 = readfloat f
				ukwFloat3 = readfloat f
				ukwFloat4 = readfloat f
				ukw = readlong f			--offset?
				
-- 				format "% % % %\n" ukwFloat ukwFloat2 ukwFloat3 ukwFloat4
			)
		)
		0x9d3b:(	--boneInfo
			boneCount = (data.Length / 0x10)
-- 			format "boneInfoCount: % boneInfoLength: %\n" (bit.intashex((data.Length / 0x10) as integer)) (bit.intashex(data.Length))
			for y=1 to data.Length / 0x10 do (
-- 				ReadFixedByteString f 0x10 1 0
				append boneDataArray (
					_bone = boneInfo()
				)
			)
		)
		0xba18:(	--uvBufferOffset
			uvBufferOffset = ftell f
-- 			format "uvBufferOffset: % uvBufferLength: %\n" (bit.intashex(data.Offset) as integer) (bit.intashex(data.Length) as integer)
		)
		0x0383:(	--unknown data / bunch of floats
-- 			format "0x0383 offset: % length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length))
		)
		0xbb80:(	--materialPath table
			matCount = (data.Length / 0x20)
-- 			format "matOffset: % matCount: % matLength: %\n" (bit.intashex((data.Offset) as integer)) (bit.intashex((data.Length / 0x20) as integer)) (bit.intashex((data.Length) as integer))
			for y=1 to matCount do (
				append matDataArray (
					_mat = matInfo()
				)
			)
		)
		0x6765:(	--unknown data / elmSize = 4?
-- 			format "0x6765 count: %	length: %\n" (bit.intashex((data.length / 0x04) as integer)) (bit.intashex(data.length as integer))
		)
		0x4273:(	--polyElmInfo
-- 			format "polyElmInfoOffset: % polyElmInfoCount: %	polyElmInfoLength: %\n" (bit.intashex((data.Offset) as integer)) (bit.intashex((data.Length / 0x24) as integer)) (bit.intashex(data.Length as integer))
			
			for y=1 to data.Length / 0x24 do (
				ReadFixedByteString f 0x24 1 0
				append polyElmDataArray (
					polyElm = polyElmInfo()
				)
			)
		)
		0xfef6:(	--unknownTable / tableSize = 0x10 / maybe related to collision model?
-- 			format "0xfef6 offset: count: %	length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length / 0x0a as integer)) (bit.intashex(data.Length as integer))
			for y=1 to data.Length / 0xa do (
				ReadFixedByteString f 0xa 0 0
			)
		)
		0x1b58:(	--skeleton or materials
-- 			format "0x1b58 offset: % length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length as integer))
		)
		0xbc2e:(	--4fab / igLoc related
-- 			format "0xbc2e offset: % count: %	length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length / 0x08 as integer)) (bit.intashex(data.Length as integer))
			
			for y=1 to data.Length / 8 do (
-- 				ReadFixedByteString f 0x08 1 1
				
				ukwHash = readlong f
				ukwID = readlong f	--parentID?
			)
		)
		0xcbde:(	--meshInfo
-- 			format "meshInfoCount: %	meshInfoLength: %\n" (bit.intashex(data.Length / 0x40 as integer)) (bit.intashex(data.Length as integer))
			
			for y=1 to data.Length / 0x40 do (
				ReadFixedByteString f 0x40 1 1
				
				append meshDataArray (
					_mesh = meshInfo()
				)
			)
		)
		0x4b29:(	--unknown data
-- 			format "0x4b29 offset:% length: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length as integer))
		)
		0x4fab:(	--igLoc table / bone or rig related?
-- 			format "igLocCount: % igLocLength: %\n" (bit.intashex((data.Length / 0x40) as integer)) (bit.intashex((data.Length) as integer))
			
			for y=1 to data.Length / 0x40 do (
				ukwHash = readlong f
				igLocString = getString f (readlong f)
				ukwID = readlong f	--parentID?
				fseek f 0x34 #seek_cur	--floats
			)
		)
		0xe69b:(	--vertBufferOffset
			vertBufferOffset = ftell f
-- 			format "vertBufferCount: % vertBufferLength: %\n" (bit.intashex((data.Length / 0x10) as integer)) (bit.intashex((data.Length) as integer))
		)
		0x4b60:(	--unknown elmSize = 2
-- 			format "0x4b60 offset : % count: %	length: %\n" (bit.intashex((data.Offset) as integer)) (bit.intashex((data.Length / 0x02) as integer)) (bit.intashex(data.Length as integer))
		)
		0x1ff5:(	--bindDataTableOffset
			bindDataTableOffset = ftell f
		)
		0x79a2:(	--bindDataBufferOffset
			bindDataBufferOffset = ftell f
		)
		0x8a19:(	--boneOffset
			boneOffset = ftell f
--  			format "boneBufferOffset: % boneBufferLength: %\n" (bit.intashex(boneOffset as integer)) (bit.intashex(data.Length as integer))
		)
		0x971c:(	--1b58 / bone related
-- 			format "0x971c offset: % count: %	length: %\n" (bit.intashex((data.Length / 0x08) as integer)) (bit.intashex((data.Offset) as integer)) (bit.intashex(data.Length as integer))
			for y=1 to data.Length / 0x08 do (	
				ReadFixedByteString f 0x08 1 0
				
				ukwHash = readlong f		--string related
				ukwIndex = readlong f
			)
		)
		0x2e68:(	--havok data
-- 			format "havokLataLength: %\n" (bit.intashex(data.Length as integer))
		)
		0x2f37:(	--collisionVertexBufferOffset
			collisionVertexBufferOffset = ftell f
-- 			format "collisionVertexBufferOffset: % collisionVertexBufferLength: %\n" (bit.intashex(data.Offset as integer)) (bit.intashex((data.Length) as integer))
			
			for y=1 to data.Length / 6 do (
				vx = readshort f
				vy = readshort f
				vz = readshort f
			)
		) 
		0x6a48:(	--ukwVertInfoTable
-- 			format "vertInfoTableCount: %	ukwVertInfoTableLength: %\n" (bit.intashex((data.Length / 0x10) as integer)) (bit.intashex(data.Length as integer))
			vertInfoTableOffset = ftell f
		)
		default:(
			format "%	%	%\n" (bit.intashex(data.Type )) (bit.intashex(data.Offset as integer)) (bit.intashex(data.Length as integer))
		)
	)
)


BNArr=#()
fseek f boneOffset #seek_set
for x=1 to boneCount do (
	b = boneDataArray[x]
	float31 = readfloat f; float32 = readfloat f; float33 = readfloat f; float34 = readfloat f
	float11 = readfloat f; float12 = readfloat f; float13 = readfloat f; float14 = readfloat f
	float21 = readfloat f; float22 = readfloat f; float23 = readfloat f; float24 = readfloat f 
	tfm = inverse (quat float11 float12 float13 float14) as matrix3
	tfm.row4 = ([float21,float22,float23]*fscale)
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width  = 0.01
	newBone.height = 0.01
	newBone.transform = tfm
	newBone.setBoneEnable false 0
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.pos.controller      = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	newBone.name = b.boneName
	
	if (b.parentID != -1) then(
		newBone.parent = BNArr[b.parentID + 1]
		newBone.transform *= newBone.parent.transform
	)
	append BNArr newBone
)

-- fseek f 0x10 #seek_cur	--not always 10
-- for x=1 to boneCount do (
-- 	b = boneDataArray[x]
-- 	m11 = Readfloat f; m12 = Readfloat f; m13 = Readfloat f; m14 = Readfloat f
-- 	m21 = Readfloat f; m22 = Readfloat f; m23 = Readfloat f; m24 = Readfloat f
-- 	m31 = Readfloat f; m32 = Readfloat f; m33 = Readfloat f; m34 = Readfloat f
-- 	m41 = Readfloat f; m42 = Readfloat f; m43 = Readfloat f; m44 = Readfloat f
-- 	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
-- 	
-- 	newBone = bonesys.createbone	\
-- 	tfm.row4	\
-- 	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
-- 	(normalize tfm.row3)
-- 	newBone.width = 0.01
-- 	newBone.height = 0.01
-- 	newBone.wirecolor = yellow
-- 	newbone.showlinks = true
-- 	newBone.transform = tfm
-- 	newBone.name = b.boneName
-- 	
-- 	pos = [m41,m42,m43]
-- 	pos *= tfm
-- 	newBone.pos += ((fscale)*-pos)
-- 	
-- 	newBone.setBoneEnable false 0
-- 	newBone.pos.controller = TCB_position ()
-- 	newBone.rotation.controller = TCB_rotation ()
-- 	
-- 	if (b.parentID != -1) then(
-- 		newBone.parent = BNArr[b.parentID + 1]
-- 	)
-- 	append BNArr newBone
-- )

rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])



multiMat = MultiMaterial numsubs:matCount showInViewport:true
meditMaterials[1] = multiMat
for x=1 to multiMat.count do (
	multiMat[x].Diffuse = random black white
	multiMat[x].name = matDataArray[x].name
)

j=0
for x=1 to meshDataArray.count do (
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	MatID_Array=#()
	
	meshInfo = meshDataArray[x]
	j+=meshInfo.ukw6
	
	fseek f ((meshInfo.vertInfoTableOffset * 0x10) + vertInfoTableOffset) #seek_set
	for y=1 to meshInfo.vertInfoTableCount do (
-- 		ReadFixedByteString f 0x10 1 0
		
		ukw = readshort f		#unsigned		--might be read as 8 bytes
		ukw2 = readshort f	#unsigned
		ukw3 = readshort f	#unsigned
		ukw4 = readshort f	#unsigned
		vertIndex = readlong f					--doesn't reset per x
		vertCount = readlong f
	)
-- 	format "\n"
	
	--position/normals/tangents
	fseek f ((meshInfo.vertOffset * 0x10) + vertBufferOffset) #seek_set
	for y=1 to meshInfo.vertCount do (
		vx = readshort f / 4096.0
		vy = readshort f / 4096.0
		vz = readshort f / 4096.0
		vw = readshort f
		normals = unpackNormal [10,10,11] 511.0 (readlong f #unsigned)
		tangents = readlong f
		
		append Vert_Array([vx,vy,vz]*fscale)
		append Normal_Array (normals)
	)
	
	--uv's
	fseek f ((meshInfo.vertOffset * 0x04) + uvBufferOffset) #seek_set
	for y=1 to meshInfo.vertCount do (
		tu = ReadHalfFloat f
		tv = ReadHalfFloat f
		
		append UV_Array ([tu,1-tv,0])
	)
	
	--bindIDs/bindWeights
	fseek f ((meshInfo.bindTableOffset * 0x10) + bindDataTableOffset) #seek_set
	format "bindTableCount: % bindTableOffset: %\n" meshInfo.bindTableCount meshInfo.bindTableOffset
	for y=1 to meshInfo.bindTableCount do (	
-- 		ReadFixedByteString f 0x10 1 1
		
		bindDataOffset = readlong f			--relative to 0x79a2
		fseek f 0x06 #seek_cur					--null
		bindIndexCount = readshort f #unsigned
		bindVertCount = readshort f #unsigned
		bindVertIndex = readshort f #unsigned + 1
		backJump = ftell f
		
		--format "bindIndexCount: %\n" (bindIndexCount)
		fseek f (bindDataOffset + bindDataBufferOffset) #seek_set
		for z = bindVertIndex to (bindVertCount + bindVertIndex - 1) do (	
			w = (weight_data boneids:#() weights:#())
			bone1 = bone2 = bone3 = bone4 = bone5 = bone6 = bone7 = bone8 = 0xFF
			weight1 = weight2 = weight3 = weight4 = weight5 = weight6 = weight7 = weight8 = 0
			
			case bindIndexCount of (
				0:(
					bone1 = readbyte f #unsigned + 1
					weight1 = 256.0
				)
				1:(
					bone1 = readbyte f #unsigned + 1
					bone2 = readbyte f #unsigned + 1
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
				)
				2:(
					bone1 = readbyte f #unsigned + 1
					bone2 = readbyte f #unsigned + 1
					bone3 = readbyte f #unsigned + 1
					bone4 = readbyte f #unsigned + 1
					
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
					weight3 = readbyte f #unsigned
					weight4 = readbyte f #unsigned
				)
				3:(
					bone1 = readbyte f #unsigned + 1
					bone2 = readbyte f #unsigned + 1
					bone3 = readbyte f #unsigned + 1
					bone4 = readbyte f #unsigned + 1
					bone5 = readbyte f #unsigned + 1
					bone6 = readbyte f #unsigned + 1
					bone7 = readbyte f #unsigned + 1
					bone8 = readbyte f #unsigned + 1
					
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
					weight3 = readbyte f #unsigned
					weight4 = readbyte f #unsigned
					weight5 = readbyte f #unsigned
					weight6 = readbyte f #unsigned
					weight7 = readbyte f #unsigned
					weight8 = readbyte f #unsigned
				)
				default:(
					format "unknown bindIndexCount: %\n" bindIndexCount
					exit
				)
			)
			
			maxweight = 0
			if(bone1 != 0xFF) then
				maxweight = maxweight + weight1
			if(bone2 != 0xFF) then
				maxweight = maxweight + weight2
			if(bone3 != 0xFF) then
				maxweight = maxweight + weight3
			if(bone4 != 0xFF) then
				maxweight = maxweight + weight4
			if(bone5 != 0xFF) then
				maxweight = maxweight + weight5
			if(bone6 != 0xFF) then
				maxweight = maxweight + weight6
			if(bone7 != 0xFF) then
				maxweight = maxweight + weight7
			if(bone8 != 0xFF) then
				maxweight = maxweight + weight8
			
			if(maxweight != 0) then (
				mxw = 256.0
				if(bone1 != 0xFF) then
				(
					w1 = weight1 as float
					append w.boneids (bone1)
					append w.weights (w1 / mxw)
				)
				if(bone2 != 0xFF) then
				(
					w2 = weight2 as float
					append w.boneids (bone2)
					append w.weights (w2 / mxw)
				)
				if(bone3 != 0xFF) then
				(
					w3 = weight3 as float
					append w.boneids (bone3)
					append w.weights (w3 / mxw)
				)
				if(bone4 != 0xFF) then
				(
					w4 = weight4 as float
					append w.boneids (bone4)
					append w.weights (w4 / mxw)
				)
				if(bone5 != 0xFF) then
				(
					w5 = weight5 as float
					append w.boneids (bone5)
					append w.weights (w5 / mxw)
				)
				if(bone6 != 0xFF) then
				(
					w6 = weight6 as float
					append w.boneids (bone6)
					append w.weights (w6 / mxw)
				)
				if(bone7 != 0xFF) then
				(
					w7 = weight7 as float
					append w.boneids (bone7)
					append w.weights (w7 / mxw)
				)
				if(bone8 != 0xFF) then
				(
					w8 = weight8 as float
					append w.boneids (bone8)
					append w.weights (w8 / mxw)
				)
			)
			
			append Weight_array w
		)
		
		fseek f backJump #seek_set
	)
	
	(
	--faces
-- 	polyElmCount = if x < meshDataArray.count then polyElmCount = (meshDataArray[x+1].polyElmIndex - meshDataArray[x].polyElmIndex)
-- 	else polyElmCount = polyElmDataArray.count - meshDataArray[x].polyElmIndex
-- 	format "% %\n" (bit.intashex (meshInfo.polyElmIndex as integer)) (bit.intashex (polyElmCount as integer))
-- 	polyInfo = polyElmDataArray[meshInfo.polyElmIndex + 1]
-- 	format "% % % %\n" polyInfo.ukwFloat polyInfo.ukwFloat2 polyInfo.ukwFloat3 polyInfo.ukwFloat4
-- 	
-- 	for y = (meshInfo.polyElmIndex + 1)  to ((meshInfo.polyElmIndex ) + polyElmCount) do (	--divides the mesh into a checkered pattern
-- 		polyInfo = polyElmDataArray[y]
-- 		Face_Array=#()
-- 		
-- 		fseek f ((polyInfo.faceOffset * 2) + faceBufferOffset) #seek_set
-- 		
-- 		for a=1 to (polyInfo.faceCount/3) do (
-- 			fa = readshort f #unsigned + 1
-- 			fb = readshort f #unsigned + 1
-- 			fc = readshort f #unsigned + 1
-- 			
-- 			append Face_Array[fa,fb,fc]
-- 		)
-- 		
-- 		msh = mesh vertices:Vert_array faces:Face_Array
-- 		msh.numTVerts = UV_array.count
-- 		msh.wirecolor = random black white
-- 		buildTVFaces msh
-- 		for j = 1 to UV_array.count do setTVert msh j UV_array[j]
-- 		for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
-- 		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
-- 		msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
-- 	)
	)
	
	fseek f ((meshInfo.faceOffset * 0x02) + faceBufferOffset) #seek_set
	for b=1 to (meshInfo.faceCount/3) do (
		fa = readshort f #unsigned + 1
		fb = readshort f #unsigned + 1
		fc = readshort f #unsigned + 1
		
		append MatID_array meshInfo.matID
		append Face_Array[fa,fb,fc]
	)
 	
	msh = mesh vertices:Vert_array faces:Face_Array materialIDs:MatID_array
	msh.numTVerts = UV_array.count
	msh.wirecolor = random black white
	msh.mat = multiMat
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
-- 	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	
	
	--skinning
	max modify mode
	select msh
	skinMod = skin ()
	addModifier msh skinMod
	for i = 1 to BNArr.count do (
		maxbone = getnodebyname BNArr[i].name
		if i != BNArr.count then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
	)
	
	modPanel.setCurrentObject skinMod
	for i = 1 to Weight_array.count do (
		w = Weight_array[i]
		bi = #() --bone index array
		wv = #() --weight value array
		
		for j = 1 to w.boneids.count do (
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)	
		
		skinOps.ReplaceVertexWeights skinMod i bi wv
	)
	
)
printHex j


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
