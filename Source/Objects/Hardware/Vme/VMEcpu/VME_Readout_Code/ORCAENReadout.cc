#include "ORCAENReadout.hh"
#define isValidCaenData(x)       ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_ValidDatum)
#define isNotValidCaenData(x)    ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_NotValidDatum)
#define isCaenHeader(x)          ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_Header)
#define isCaenEndOfBlock(x)      ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_EndOfBlock)
#define caenDataChannelCount(x)  (((x) & kCaen_DataChannelCountMask) >> kCaen_DataChannelCoutShift)


bool ORCAENReadout::Readout(SBC_LAM_Data* lamData)
{
  
    /* The deviceSpecificData is as follows:          */ 
    /* 0: statusOne register                          */
    /* 1: statusTwo register                          */
    /* 2: fifo buffer size (in longs)                 */
    /* 3: fifo buffer address                         */
    
    uint16_t statusOne, statusTwo;
    
    uint32_t statusOneAddress  = GetBaseAddress() + GetDeviceSpecificData()[0];
    uint32_t statusTwoAddress  = GetBaseAddress() + GetDeviceSpecificData()[1];
    uint32_t fifoAddress       = GetDeviceSpecificData()[3];
    //uint32_t statusOneDataSize = GetBaseAddress() + GetDeviceSpecificData()[4];
    //uint32_t statusTwoDataSize = GetBaseAddress() + GetDeviceSpecificData()[5];
    uint32_t dataId            = GetHardwareMask()[0];
    int32_t result;

    //read the states
    result = VMERead(statusOneAddress,
                     0x39,
                     sizeof(statusOne),
                     statusOne);

    if (result != sizeof(statusOne)) {
        LogBusErrorForCard(GetSlot(),"CAEN 0x%0x status 1 read",GetBaseAddress());
        return false; 
    }

    result = VMERead(statusTwoAddress,
                     0x39,
                     sizeof(statusTwo),
                     statusTwo);
    if (result != sizeof(statusTwo)) {
        LogBusErrorForCard(GetSlot(),"CAEN 0x%0x status 2 read",GetBaseAddress());
        return false; 
    }

    uint8_t bufferIsNotBusy =  !((statusOne & 0x0004) >> 2);
    uint8_t dataIsReady     =  statusOne & 0x0001;
    uint8_t bufferIsFull    =  (statusTwo & 0x0004) >> 2;

    if ((bufferIsNotBusy && dataIsReady) || bufferIsFull) {
        uint32_t dataValue;
        //read the first word, could be a header, or the buffer could be empty now
        result = VMERead(fifoAddress,
                         0x39,
                         sizeof(dataValue),
                         dataValue);
        if (result != sizeof(dataValue)) {
            LogBusErrorForCard(GetSlot(),"CAEN 0x%0x FIFO header read",GetBaseAddress());
            return false; 
        }
                                
        if(!isNotValidCaenData(dataValue)) {
        
            // FixME!!
			ensureDataCanHold(kMaxDataBufferSizeLongs/2); 
            //not sure how much this card can produce... 
            //just ensure half the data buffer is free
			
			//OK some data is apparently in the buffer and is valid
            uint32_t dataIndexStart = dataIndex; //save the start index in case we have to flush the data because of errors
            dataIndex += 2;                         //reserve two words for the ORCA header, we'll fill it in if we get valid data

            if(isCaenHeader(dataValue)) {
                //got a header, store it
                data[dataIndex++] = dataValue;
            } else {
                //error--flush buffer
                Flush_CAEN_FIFO();
                return false; 
            }
            
            //read out the channel count
            int32_t n = caenDataChannelCount(dataValue); 
            //decode the channel from the data word
            int32_t i;
            for(i=0;i<n;i++){
                result = VMERead(fifoAddress,
                                 0x39,
                                 sizeof(dataValue),
                                 dataValue);
                if (result != sizeof(dataValue)) {
                    LogBusErrorForCard(GetSlot(),"CAEN 0x%0x fifo read",GetBaseAddress());
                    dataIndex = dataIndexStart; //don't allow this data out.
                    return false; 
                }
            
                if(isValidCaenData(dataValue)){
                    data[dataIndex++] = dataValue;
                }
                else {
                    //oh-oh. big problems flush the buffer.
                    LogErrorForCard(GetSlot(),"CAEN 0x%0x fifo flushed",GetBaseAddress());
                    dataIndex = dataIndexStart; //don't allow this data out.
                    Flush_CAEN_FIFO();
                    return false; 
                }
            }
                        
            result = VMERead(fifoAddress,
                             0x39,
                             sizeof(dataValue),
                             dataValue);
            //read the end of block
            if (result != sizeof(dataValue)) {
                LogBusErrorForCard(GetSlot(),"CAEN 0x%0x EOB read",GetBaseAddress());
                dataIndex = dataIndexStart; //don't allow this data out.
                return false;
            }

            if(isCaenEndOfBlock(dataValue)){
                data[dataIndex++] = dataValue;
                //OK, it looks like this data block is valid, so fill in the header
                data[dataIndexStart] = dataId |  
                    ((dataIndex-dataIndexStart) & 0x3ffff);
                data[dataIndexStart+1] = ((GetCrate()&0x0000000f)<<21) | 
                    ((GetSlot() & 0x0000001f)<<16);
            }
            else {
                //error...the end of block not where we expected it
                LogErrorForCard(GetSlot(),"CAEN 0x%0x fifo flushed",GetBaseAddress());
                dataIndex = dataIndexStart; //don't allow this data out.
                Flush_CAEN_FIFO();
                return false;
            }
        }
    }

    return true; 
}

void ORCAENReadout::Flush_CAEN_FIFO()
{
    /* The vmeAM39Handle device *must* be locked before calling this function. */
    uint32_t fifoSize    = GetDeviceSpecificData()[3];
    uint32_t fifoAddress = GetBaseAddress() + GetDeviceSpecificData()[4];
    
    uint32_t dataValue;
    int32_t result;
    for(uint32_t i=0;i<fifoSize;i++){
        result = VMERead(fifoAddress,
                         0x39,
                         sizeof(dataValue),
                         dataValue);
        if (result != sizeof(dataValue)) {
            LogBusErrorForCard(GetSlot(),"CAEN 0x%0x Couldn't flush fifo",GetBaseAddress());
            break;
        }
    }
}
