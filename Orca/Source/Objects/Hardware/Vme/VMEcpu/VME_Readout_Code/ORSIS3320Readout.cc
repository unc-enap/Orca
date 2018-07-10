#include "ORSIS3320Readout.hh"
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>


const uint32_t ORSIS3320Readout :: SIS3320_previousBankEndSampleAddress[ 8 ] = {
    0x02000018, 0x0200001C, 0x02800018, 0x0280001C, 0x03000018, 0x0300001C, 0x03800018, 0x0380001C
};


ORSIS3320Readout::ORSIS3320Readout(SBC_card_info* ci) :
ORVVmeCard(ci), 
fBankOneArmed(false) {
    dataBuffer = NULL;

}

// destructor frees dataBuffer, if it was allocated
ORSIS3320Readout :: ~ORSIS3320Readout() {
    if( dataBuffer ) {
        free( dataBuffer );
    }
}

uint32_t ORSIS3320Readout::GetNextBankSampleRegisterOffset(size_t channel)
{
    switch (channel) {
        case 0: return 0x02000010;
        case 1: return 0x02000014;
        case 2: return 0x02800010;
        case 3: return 0x02800014;
        case 4: return 0x03000010;
        case 5: return 0x03000014;
        case 6: return 0x03800010;
        case 7: return 0x03800014;
    }
    return (uint32_t)-1;
}

uint32_t ORSIS3320Readout::GetADCBufferRegisterOffset(size_t channel){
    switch (channel) {
        case 0: return 0x04000000;
        case 1: return 0x04800000;
        case 2: return 0x05000000;
        case 3: return 0x05800000;
        case 4: return 0x06000000;
        case 5: return 0x06800000;
        case 6: return 0x07000000;
        case 7: return 0x07800000;
    }
    return (uint32_t)-1;
}

bool ORSIS3320Readout::Readout(SBC_LAM_Data* /*lam_data*/)
{
    uint32_t dataId   = GetHardwareMask()[0];
    uint32_t status   = 0x0;
    uint32_t location = ((GetCrate()&0x0000000f)<<21) | ((GetSlot()& 0x0000001f)<<16);
    
    if (VMERead(GetBaseAddress() + kAcquisitionControlReg,
                GetAddressModifier(),
                sizeof(status),
                status) != sizeof(uint32_t)) {
		LogBusErrorForCard(GetSlot(),"Rd Status Err: SIS3320 0x%04x %s", GetBaseAddress() + kAcquisitionControlReg,strerror(errno));
	}
    else if((status & kEndAddressThresholdFlag) == kEndAddressThresholdFlag){
        
        //if we get here, there may be something to read out
        if(fBankOneArmed)  armBank2();
        else               armBank1();
        
        for (size_t i=0;i<kNumberOfChannels;i++) {
            
            // retrieve the data indicating whether or not this channel is enabled
            // if it isn't, go to the next channel
            if( !((GetDeviceSpecificData()[4]) & ( 0x1 << i )) ) {
                continue;
            }
            
            
            uint32_t endSampleAddress = 0;
            
            // populate endSampleAddress with the next sample address from the previous bank
            
            if (VMERead(GetBaseAddress() + SIS3320_previousBankEndSampleAddress[i],
                        GetAddressModifier(),
                        sizeof(endSampleAddress),
                        endSampleAddress) != sizeof(uint32_t)) {
                LogBusErrorForCard(GetSlot(),"Rd End Add Err: SIS3320 0x%04x %s", GetBaseAddress() + GetNextBankSampleRegisterOffset(i),strerror(errno));
            }
            
            // now apply appropriate mask and shift to translate this number into words to read
            endSampleAddress = (endSampleAddress & 0x3ffffc) >>1;
            uint32_t numLongsToRead = endSampleAddress;
            
            if( numLongsToRead == 0 ){
                continue; // if nothing to read, skip the channel
            }
            uint32_t maxOrcaRecordInLongs = 0x3FFFF;
          
            //can't fit more than maxOrcaRecordInLongs -2 into an Orca record
            if ( numLongsToRead < maxOrcaRecordInLongs - 2 ) {
                
                ensureDataCanHold(maxOrcaRecordInLongs);
                            
                
                uint32_t savedDataStart = dataIndex;
                
                data[dataIndex++] = dataId | (numLongsToRead+2);
                data[dataIndex++] = location | (i<<8);
                
        
                int32_t bytesRead = DMARead( GetBaseAddress() + GetADCBufferRegisterOffset(i),
                                         GetAddressModifier(),
                                         (uint32_t) 4,
                                         (uint8_t*)&(data[dataIndex]),
                                         numLongsToRead*4);
                
                
                if(bytesRead < 0) {
                    //something wrong.. dump the data
                    dataIndex = savedDataStart;
                    LogErrorForCard(GetSlot(),"Rd Buffer Err: SIS3320 0x%04x %s", GetBaseAddress() +
                                GetADCBufferRegisterOffset(i),strerror(errno));
                    
                }
                else {
                    dataIndex += numLongsToRead;
                }
                
                
            }
            else {
                
                commitData();
                
                if( !dataBuffer ) dataBuffer = (uint32_t*)malloc(8*1024*1024*sizeof(uint8_t));
                
                int32_t bytesRead = DMARead( GetBaseAddress() + GetADCBufferRegisterOffset(i),
                                         GetAddressModifier(),
                                         (uint32_t) 4,
                                         (uint8_t*)dataBuffer,
                                         numLongsToRead*4);
                
                if( bytesRead > 0 ) {
                    
                    uint32_t nWaveformWords = 0;
                    uint32_t offsetInBuffer = 0;
                    uint32_t positionFromOffset;
                    
                    uint32_t bytesCopied = 0;
                    uint8_t getOut = 0;
                    
                    while( offsetInBuffer <= (uint32_t)bytesRead / 4 ) {
                        
                        positionFromOffset = 0;
                        
                        while( (positionFromOffset + 521 < maxOrcaRecordInLongs) && ( (offsetInBuffer + positionFromOffset) <= (uint32_t)bytesRead/4 ) ) {
                            
                            // determine number of samples
                            uint32_t headerCheck = (dataBuffer[offsetInBuffer + positionFromOffset + 9 ] & 0xffff0000) >> 16;
                            if(headerCheck  == 0xdada ) {
                                // healthy header indicating waveform samples; pick out how many
                                nWaveformWords = (dataBuffer[offsetInBuffer + positionFromOffset + 9 ] & 0xffff); // still have to divide by 2
                                // this next sequence divides by two, rounding up... i think
                                if( (nWaveformWords & 0x1) == 0x1 ) nWaveformWords++;
                                nWaveformWords = nWaveformWords >> 1;
                            }
                            else if(headerCheck == 0xeded ) {
                                // header sez: "no samples"
                                nWaveformWords = 0;
                            }
                            else {
                                // bad header.. who knows what to do!
                                LogErrorForCard(GetSlot(),"3320 0x%04x found a bad header",GetBaseAddress());
                                getOut = 1;
                                break;
                            }
                            
                            positionFromOffset += 10 + nWaveformWords; //waveform + header
                        }
                        
                        if(getOut)break;
                        
                        // now form the ORCA data packet..
                        data[dataIndex++] = dataId | (positionFromOffset + 2);
                        data[dataIndex++] = location | (i<<8) | 0x80000000;
                                                
                        memcpy( (void*)&(data[dataIndex]), (void*)&(dataBuffer[offsetInBuffer]), (size_t)4*(positionFromOffset) );
                        dataIndex += positionFromOffset;

                        bytesCopied += (size_t)4*positionFromOffset;
                        
                        offsetInBuffer += positionFromOffset;
                        
                        commitData();
                        
                        if(bytesCopied == (uint32_t)bytesRead ) {
                            break;
                        }
                    }
                    commitData();
                }
                
                
                if(bytesRead < 0) {
                    //something wrong..
                    LogBusErrorForCard(GetSlot(),"Rd Buffer Err: SIS3320 0x%04x %s", GetBaseAddress() +
                                GetADCBufferRegisterOffset(i),strerror(errno));
                }
            }
        }
    }
    return true;
}

void ORSIS3320Readout::armBank1()
{
    uint32_t addr = GetBaseAddress() + kDisarmAndArmBank1;
    uint32_t data_wr = 1;
    if (VMEWrite(addr, GetAddressModifier(),sizeof(data_wr),data_wr) != sizeof(data_wr)){
		LogBusErrorForCard(GetSlot(),"Arm 1 Err: SIS3320 0x%04x %s", addr,strerror(errno));
	}
    
    fBankOneArmed = true;
	
}

void ORSIS3320Readout::armBank2()
{
    uint32_t addr = GetBaseAddress() + kDisarmAndArmBank2;
    uint32_t data_wr = 1;
    if (VMEWrite(addr, GetAddressModifier(),sizeof(data_wr),data_wr) != sizeof(data_wr)){
		LogBusErrorForCard(GetSlot(),"Arm 2 Err: SIS3320 0x%04x %s", addr,strerror(errno));
	}
    fBankOneArmed = false;
}

