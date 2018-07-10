#include "ORAcqirisDC440Readout.hh"
#include <iostream>
extern "C" {
#include "AcqirisDC440.h"
#include "CircularBuffer.h"
}
extern char needToSwap;
bool ORAcqirisDC440Readout::Start()
{
    ViSession dev = GetBaseAddress();
    ::StartUp(dev);
    return true;
}

bool ORAcqirisDC440Readout::Stop()
{
    ViSession dev = GetBaseAddress();
    ::Stop(dev);
    return true;
}
bool ORAcqirisDC440Readout::Readout(SBC_LAM_Data* /*lamData*/)
{
    uint32_t boardID       = GetBaseAddress();
    uint32_t numberSamples = GetDeviceSpecificData()[0];
    uint32_t enableMask    = GetDeviceSpecificData()[1];
    uint32_t dataID        = GetHardwareMask()[0];
    uint32_t location      = ((GetCrate() & 0x0f) << 21) |
                             ((GetSlot()  & 0x1f) << 16); //the location (crate,card)
    char restart           = (char) GetDeviceSpecificData()[2];
    char useCB             = (char) GetDeviceSpecificData()[3];
    int32_t nbrSegments=1;
    /*
    std::cout << boardID << '-' <<
                 numberSamples << '-' <<
                 enableMask << '-' <<
                 dataID << '-' <<
                 location << '-' <<
                 restart << '-' <<
                 useCB << std::endl;
    */
    if(useCB){
        ViBoolean done = 0;
        AcqrsD1_acqDone(boardID, &done); // Poll for the end of the acquisition
        if(!done) return false;
    }

    AqDataDescriptor                wfDesc;
    AqSegmentDescriptor             segDesc;

    int32_t extra;
    AcqrsD1_getInstrumentInfo(boardID, "TbSegmentPad", &extra);
    AqReadParameters readParams;
    readParams.dataType         = ReadInt16;            // short
    readParams.readMode            = ReadModeStdW;            // continuous
    readParams.firstSegment     = 0;                    // First segment to read.
    readParams.nbrSegments      = nbrSegments;
    readParams.firstSampleInSeg = 0;                    // First data point in segment.
    readParams.nbrSamplesInSeg  = numberSamples;        // Expected number of points
    readParams.segmentOffset    = numberSamples + 100;    // Offset between segments.
    readParams.dataArraySize    = ( kSBC_MaxPayloadSizeBytes - 
                                    sizeof(Acquiris_WaveformResponseStruct) - 
                                    sizeof(Acquiris_OrcaWaveformStruct)) / sizeof(int16_t) ;    // User supplied array size.
    readParams.segDescArraySize = nbrSegments*sizeof(AqSegmentDescriptor);  // Maximum number of segments.    
    readParams.reserved1 = 0;
    readParams.reserved2 = 0;
    readParams.reserved3 = 0;

    fSendPacket.cmdHeader.destination                    = kAcqirisDC440;
    fSendPacket.cmdHeader.cmdID                            = kAcqiris_DataReturn;
    fSendPacket.cmdHeader.numberBytesinPayload            = sizeof(Acquiris_WaveformResponseStruct); //waveform sizes added below
    fSendPacket.message[0] = '\0';
    
    //get pointer to the response and init to zero
    Acquiris_WaveformResponseStruct* wPtr = (Acquiris_WaveformResponseStruct*)fSendPacket.payload;
    wPtr->numWaveformStructsToFollow = 0;
    wPtr->hitMask = 0;
    
    //get pointer to the Orca part of the payload
    Acquiris_OrcaWaveformStruct* recordPtr = (Acquiris_OrcaWaveformStruct*)(wPtr+1); //point to recordStart
    int16_t* dataPtr     = (int16_t*)(recordPtr+1);                                         //point to the start of data
    int32_t numberShortsInSample;    
    int32_t numberLongsInSample;

    int32_t channel;
    for(channel=0;channel<2;channel++){
    
        if(enableMask & (1<<channel)){
        
            wPtr->numWaveformStructsToFollow++;
            
            //go get the waveform, putting it directly into the payload starting at the dataPtr position
            ViStatus status = AcqrsD1_readData(boardID, channel+1, 
                &readParams, dataPtr , &wfDesc, &segDesc);
            if(status == VI_SUCCESS){
                wPtr->hitMask |= (1<<channel);                            //the hitMask is used to compute rates
                numberShortsInSample = wfDesc.returnedSamplesPerSeg +    //actual short word count
                                       wfDesc.indexFirstPoint;
                numberLongsInSample = (numberShortsInSample+1)/2;        //rounded to next long word boundary

                //update the size of payload
                fSendPacket.cmdHeader.numberBytesinPayload += 
                    sizeof(Acquiris_OrcaWaveformStruct);
                fSendPacket.cmdHeader.numberBytesinPayload += 
                    numberLongsInSample*sizeof(int32_t);            
            }
            else {
                numberShortsInSample = 0;
                numberLongsInSample = 0;
            }
            
            //update the Orca record
            recordPtr->orcaHeader            = dataID   | (numberLongsInSample + (sizeof(Acquiris_OrcaWaveformStruct)/sizeof(int32_t)));
            recordPtr->location                = location | (channel&0xFF)<<8;
            recordPtr->timeStampLo            = segDesc.timeStampLo;
            recordPtr->timeStampHi            = segDesc.timeStampHi;
            recordPtr->offsetToValidData    = wfDesc.indexFirstPoint;
            recordPtr->numShorts            = numberShortsInSample - wfDesc.indexFirstPoint;
            
            //advance our pointers
            recordPtr = (Acquiris_OrcaWaveformStruct*)((int32_t*)(recordPtr+1) + numberLongsInSample); //point to next recordStart
            dataPtr      = (int16_t*)(recordPtr+1);                                                         //point to the start of next data
        }
    }
    
    //if using the Circular Buffer, only the Orca part of the payload is put in the CB. The first part holding the
    //hitMask and numWaveforms is discarded. set up here because we may have to swap
    int32_t* orcaRecordPartPtr = (int32_t*)(wPtr+1);
    int32_t numLongs = (fSendPacket.cmdHeader.numberBytesinPayload - sizeof(Acquiris_WaveformResponseStruct))/sizeof(int32_t);

    if(needToSwap){
        int32_t numRec = wPtr->numWaveformStructsToFollow;
        recordPtr = (Acquiris_OrcaWaveformStruct*)(wPtr+1); //point to recordStart
        dataPtr     = (int16_t*)(recordPtr+1);                    //point to the start of data

        SwapLongBlock(wPtr,sizeof(Acquiris_WaveformResponseStruct)/sizeof(int32_t));
        int32_t i;
        for(i=0;i<numRec;i++){
            int32_t recordLen            = (recordPtr->orcaHeader & 0x0003ffff);    //# longs
            int32_t numShortsInData    = recordPtr->numShorts;
            
            int16_t* dataPtr = (int16_t*)(recordPtr+1);
            SwapLongBlock(recordPtr,sizeof(Acquiris_OrcaWaveformStruct)/sizeof(int32_t));
            SwapShortBlock(dataPtr,numShortsInData);
            recordPtr = (Acquiris_OrcaWaveformStruct*)((int32_t*)recordPtr + recordLen);
        }
    }
    
    if(useCB) CB_writeDataBlock((int32_t*)orcaRecordPartPtr,numLongs);
    else      writeBuffer(&fSendPacket);

    if(restart) AcqrsD1_acquire(boardID);

    return true; 
}

// Legacy code for doing one waveform reads...
int32_t Readout_DC440(uint32_t boardID, uint32_t numberSamples,
                      uint32_t enableMask, uint32_t dataID,
                      uint32_t location, char autoRestart,
                      char useCircularBuffer)
{
    SBC_card_info card_info;
    SBC_LAM_Data lam_data;
    card_info.base_add = boardID;
    card_info.crate = ((location >> 21) & 0xF);
    card_info.slot = ((location >> 16) & 0x1F);
    card_info.deviceSpecificData[0] = numberSamples;
    card_info.deviceSpecificData[1] = enableMask;
    card_info.deviceSpecificData[2] = autoRestart;
    card_info.deviceSpecificData[3] = useCircularBuffer;
    
    ORAcqirisDC440Readout readoutCard(&card_info);
    return readoutCard.ReadoutAndGetNextIndex(&lam_data);
}
