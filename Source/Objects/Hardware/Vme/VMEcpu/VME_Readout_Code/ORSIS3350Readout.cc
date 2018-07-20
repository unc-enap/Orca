#include "ORSIS3350Readout.hh"
#include <errno.h>
uint32_t ORSIS3350Readout::adcOffsets[kNumberOfChannels] = 
    {0x04000000, 0x05000000, 0x06000000, 0x07000000};
uint32_t ORSIS3350Readout::channelOffsets[kNumberOfChannels] = 
    {0x02000000, 0x02000000, 0x03000000, 0x03000000};    
uint32_t ORSIS3350Readout::endOfEventOffset[kNumberOfChannels] = 
    {0x10, 0x14, 0x10, 0x14};    
    
bool ORSIS3350Readout::Readout(SBC_LAM_Data* lamData)
{

    uint32_t dataId         = GetHardwareMask()[0];
    ORSIS3350OperationModes operationMode  = 
        (ORSIS3350OperationModes) GetDeviceSpecificData()[0];
    uint32_t wrapLength     = GetDeviceSpecificData()[1];
    uint32_t locationMask   = ((GetCrate() & 0x0000000f)<<21) | 
                              ((GetSlot() & 0x0000001f)<<16);

    uint32_t status = 0;
    if(VMERead(GetBaseAddress()+0x10,
               GetAddressModifier(),
               sizeof(status),
               status) != sizeof(status)) {  //Check Acq Control Reg
        LogBusErrorForCard(GetSlot(),"SIS3350 VME Exception 0: %s 0x%08x",
            strerror(errno),GetBaseAddress());
    }

    bool thereWasAnEvent = false;
    if(operationMode == 0 || operationMode == 2){
        thereWasAnEvent = ((status & 0x00080000) == 0x00080000);
    }
    else {
        thereWasAnEvent = ((status & 0x00010000) != 0x00010000);
    }
    if(thereWasAnEvent){    //check that the arm bit falls to zero
        if(operationMode == kOperationRingBufferAsync || 
           operationMode == kOperationDirectMemoryGateAsync){
            //if op mode is kOperationRingBufferAsync or 
            // kOperationDirectMemoryGateAsync -- must disarm sampling
            //rearm by writing anything to the sample arm register
            uint32_t disarmIt = 1; 
            if(VMEWrite(GetBaseAddress()+0x414,
                        GetAddressModifier(),
                        sizeof(disarmIt),
                        disarmIt) != sizeof(disarmIt)){ //sample disarm register
                LogBusErrorForCard(GetSlot(),"SIS3350 VME Exception 1: %s 0x%08x",
                    strerror(errno),GetBaseAddress());
            }
        }
        uint32_t stop_next_sample_addr[kNumberOfChannels] = {0,0,0,0};
        for(uint16_t i=0;i<kNumberOfChannels;i++){
            if(VMERead(GetBaseAddress() + 
                           channelOffsets[i] +
                           endOfEventOffset[i],
                       GetAddressModifier(),
                       sizeof(stop_next_sample_addr[i]),
                       stop_next_sample_addr[i]) != 
               sizeof(stop_next_sample_addr[i])) {  //Check Acq Control Reg
                LogBusErrorForCard(GetSlot(),"SIS3350 VME Exception 2: %s 0x%08x",
                    strerror(errno),GetBaseAddress());
             }
             if (stop_next_sample_addr[i] != 0 
                 && stop_next_sample_addr[i] > 65536){
                 stop_next_sample_addr[i] = 65536;
             }
        }
            
        for(uint16_t i=0;i<kNumberOfChannels;i++){
            if(stop_next_sample_addr[i] != 0){
                uint32_t numLongWords = stop_next_sample_addr[i]/2;
                uint32_t startIndex = dataIndex;
                
                ensureDataCanHold(numLongWords + 2); //check for required array space  
                
                data[dataIndex++] = dataId | (numLongWords + 2);
                data[dataIndex++] = locationMask | i;
                if(DMARead(GetBaseAddress() + 
                               adcOffsets[i],
                           GetAddressModifier(),
                           (uint32_t) 4, // Should this be 8? FixME 
                           (uint8_t*)&(data[dataIndex]),
                           numLongWords*4) == (int32_t) numLongWords*4) { 
                
                    dataIndex += numLongWords;    
                    if(operationMode == kOperationDirectMemoryStop){
                        //the kOperationDirectMemoryStop mode 
                        //requires the data to be reordered
                        ReOrderOneSIS3350Event(&data[startIndex],
                            dataIndex-startIndex+1,
                            wrapLength);
                    }
                }
                else {
                    LogBusErrorForCard(GetSlot(),"SIS3350 VME Exception 3: %s 0x%08x",
                        strerror(errno),GetBaseAddress()+adcOffsets[i]);
                    dataIndex = startIndex; //dump the record
                }
            }
        } //end of readout for loop
        
        uint32_t armIt = 1; //rearm by writing anything to the sample arm register
        if(VMEWrite(GetBaseAddress()+0x410,
                    GetAddressModifier(),
                    sizeof(armIt),
                    armIt) != sizeof(armIt)){ //sample arm register
            LogBusErrorForCard(GetSlot(),"SIS3350 VME Exception 6: %s 0x%08x",
                strerror(errno),GetBaseAddress());
        }
    } //End Check Acq Control Reg
    
    return true; 
}

void ORSIS3350Readout::ReOrderOneSIS3350Event(int32_t* inDataPtr, uint32_t dataLength, uint32_t wrapLength)
{
    uint32_t i;
    int32_t* outDataPtr = new int32_t[dataLength];
    uint32_t lword_length     = 0;
    uint32_t lword_stop_index = 0;
    uint32_t lword_wrap_index = 0;
    
    uint32_t wrapped       = 0;
    uint32_t stopDelayCounter=0;
    
    uint32_t event_sample_length = wrapLength;
    
    if (dataLength != 0) {
        outDataPtr[0] = inDataPtr[0]; //copy ORCA header
        outDataPtr[1] = inDataPtr[1]; //copy ORCA header
        
        uint32_t index = 2;
        
        outDataPtr[index]   = inDataPtr[index];        // copy Timestamp    
        outDataPtr[index+1] = inDataPtr[index+1];    // copy Timestamp        
        
        wrapped             =   ((inDataPtr[4]  & 0x08000000) >> 27); 
        stopDelayCounter =   ((inDataPtr[4]  & 0x03000000) >> 24); 
        
        uint32_t stopAddress =   ((inDataPtr[index+2]  & 0x7) << 24)  
                                    + ((inDataPtr[index+3]  & 0xfff0000 ) >> 4) 
                                    +  (inDataPtr[index+3]  & 0xfff);
        
        
        // write event length 
        outDataPtr[index+3] = (((event_sample_length) & 0xfff000) << 4)            // bit 23:12
                            + ((event_sample_length) & 0xfff);                    // bit 11:0 
        
        outDataPtr[index+2] = (((event_sample_length) & 0x7000000) >> 24)        // bit 23:12
                            + (inDataPtr[index+2]  & 0x0F000000);                // Wrap arround flag and stopDelayCounter
        
        
        lword_length = event_sample_length/2;
        // stop delay correction
        if ((stopAddress/2) < stopDelayCounter) {
            lword_stop_index = lword_length + (stopAddress/2) - stopDelayCounter;
        }
        else {
            lword_stop_index = (stopAddress/2) - stopDelayCounter;
        }
        
        // rearange
        if (wrapped) { // all samples are vaild
            for (i=0;i<lword_length;i++){
                lword_wrap_index =   lword_stop_index + i;
                if  (lword_wrap_index >= lword_length) {
                    lword_wrap_index = lword_wrap_index - lword_length; 
                } 
                outDataPtr[index+4+i] =  inDataPtr[index+4+lword_wrap_index]; 
            }
        }
        else { // only samples from "index" to "stopAddress" are valid
            for (i=0;i<lword_length-lword_stop_index;i++){
                lword_wrap_index =   lword_stop_index + i;
                if  (lword_wrap_index >= lword_length) {lword_wrap_index = lword_wrap_index - lword_length; } 
                outDataPtr[index+4+i] =  0; 
            }
            for (i=lword_length-lword_stop_index;i<lword_length;i++){
                lword_wrap_index =   lword_stop_index + i;
                if  (lword_wrap_index >= lword_length) {lword_wrap_index = lword_wrap_index - lword_length; } 
                outDataPtr[index+4+i] =  inDataPtr[index+4+lword_wrap_index]; 
            }
        }
    }
    memcpy(inDataPtr, outDataPtr, dataLength*sizeof(uint32_t));
    delete outDataPtr;

}
