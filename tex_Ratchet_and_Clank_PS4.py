from inc_noesis import *

def registerNoesisTypes():
    handle = noesis.register("Ratchet and Clank [PS4]", ".texture")
    noesis.setHandlerTypeCheck(handle, noepyCheckType)
    noesis.setHandlerLoadRGBA(handle, noepyLoadRGBA)
    #noesis.logPopup()
    return 1

def noepyCheckType(data):
    return 1
    
def noepyLoadRGBA(data, texList):
    

    texture = None
    streamFile = None
    manualSearch = False

    streamExists = rapi.checkFileExists(rapi.getInputName() + ".stream")
    if streamExists == 0:
        print("Stream file not found.")
        if manualSearch == True:
            streamFile = rapi.loadPairedFileOptional("stream file", ".stream")  #already loaded as byte array
    if streamExists == 1:
        print("Stream file found.")
        streamFile = rapi.loadIntoByteArray(rapi.getInputName() + ".stream")
    
    bs = NoeBitStream(data)
    bs2 = NoeBitStream(streamFile)

    magic = bs.readUInt()
    ukw = bs.readUInt()             #hash?
    textureOffset = bs.readUInt()   #headerLength?
    ukw2 = bs.readUInt()            #1
    ukw3 = bs.readUInt()            #hash?
    subHeaderOffset = bs.readUInt()
    subHeaderLength = bs.readUInt()
    fileTypeString = bs.readString()
    
    #getting textureType and dimensions
    bs.seek(subHeaderOffset, NOESEEK_ABS)
    textureSize = bs.readUInt()     #size of uncompressed built texture data
    textureSize2 = bs.readUInt()    #size of uncompressed stream texture data
    imgWidth = bs.readUShort()      #stream
    imgHeight = bs.readUShort()     #stream
    imgWidth2 = bs.readUShort()     #built
    imgHeight2 = bs.readUShort()    #built
    ukw4 = bs.readUShort()          #always 1
    ukw5 = bs.readUShort()
    textureType = bs.readUShort()
    ukw6 = bs.readUInt()            #may be two shorts
    ukw7 = bs.readUShort()          #always null
    ukw8 = bs.readUShort()
    ukw9 = bs.readUShort()
    ukw10 = bs.readUShort()
    ukw11 = bs.readUShort()

    textureFormat = None
    print("textureType:", hex(textureType))
    if textureType == 0x1C:
        textureFormat = noesis.NOESISTEX_RGBA32 #dosent seem to work
    elif textureType == 0x53:
        textureFormat = noesis.FOURCC_BC5   
        #textureFormat = noesis.FOURCC_ATI2
    else:
        textureFormat = noesis.FOURCC_BC7   #there are others but they all seem to work with BC7
    

    if streamFile == None:
        #parsing built texture data
        print("No stream file selected.")

        bs.seek(textureOffset, NOESEEK_ABS)
        print ("Built textureSize:", hex(textureSize))
        print ("Width:", str(imgWidth2), "Height:", str(imgHeight2))
        
        textureData = bs.readBytes(textureSize)
        textureData = rapi.callExtensionMethod("untile_1dthin", textureData, imgWidth2, imgHeight2, 8, 1)
        textureData = rapi.imageDecodeDXT(textureData, imgWidth2, imgHeight2, textureFormat)
        texture = NoeTexture(rapi.getInputName(), imgWidth2, imgHeight2, textureData, noesis.NOESISTEX_RGBA32)
    else:
        print("Stream file selected.")

        print ("Stream textureSize:", hex(textureSize2))
        print ("Width:", str(imgWidth), "Height:", str(imgHeight))

        textureData = rapi.decompLZ4(streamFile, textureSize2)
        textureData = rapi.callExtensionMethod("untile_1dthin", textureData, imgWidth, imgHeight, 8, 1)
        textureData = rapi.imageDecodeDXT(textureData, imgWidth, imgHeight, textureFormat)
        texture = NoeTexture(rapi.getInputName(), imgWidth, imgHeight, textureData, noesis.NOESISTEX_RGBA32)
    

    
    texList.append(texture)

    #texList.append(NoeTexture(rapi.getInputName(), imgWidth2, imgHeight2, imgData, texFmt))
    
    
    return 1