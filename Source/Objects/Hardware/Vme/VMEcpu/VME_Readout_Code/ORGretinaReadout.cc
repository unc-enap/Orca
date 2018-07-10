#include "ORGretinaReadout.hh"
#include <errno.h>
#include <iostream>
using namespace std;
bool ORGretinaReadout::Readout(SBC_LAM_Data* /*lamData*/)
{

#define kGretinaPacketSeparater 0xAAAAAAAA
#define kGretinaNumberWordsMask 0x07FF0000
	
    uint32_t fifoState;

    uint32_t baseAddress      = GetBaseAddress();  
    uint32_t fifoStateAddress = GetDeviceSpecificData()[0];
    uint32_t fifoEmptyMask    = GetDeviceSpecificData()[1];
    uint32_t fifoAddress      = GetDeviceSpecificData()[2];
    uint32_t fifoAddressMod   = GetDeviceSpecificData()[3];
    uint32_t sizeOfFIFO       = GetDeviceSpecificData()[4];
    uint32_t location         = GetDeviceSpecificData()[5];
    uint32_t dataId           = GetHardwareMask()[0];

    //read the fifo state
    int32_t result;
    fifoState = 0;

    result = VMERead(fifoStateAddress, 
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     fifoState);
    //cout << hex << result << " " << fifoState << endl;
    if (result != sizeof(fifoState)) return true;
     
    if ((fifoState & fifoEmptyMask) == 0 ) {
		
        ensureDataCanHold(kMaxDataBufferSizeLongs/2); //not sure how much this card can produce... just ensure half the data buffer is free
     
        uint32_t numLongs = 3;
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = dataId | 0; //we'll fill in the length later
        data[dataIndex++] = location;
        
        //read the first int32_tword which should be the packet separator: 0xAAAAAAAA
        uint32_t theValue;
        result = VMERead(fifoAddress, 
                         GetAddressModifier(),
                         (uint32_t) 0x4,
                         theValue);
        
        if (result == 4 && (theValue==kGretinaPacketSeparater)){
            //read the first word of actual data so we know how much to read
            result = VMERead(fifoAddress, 
                             GetAddressModifier(),
                             (uint32_t) 0x4,
                             theValue);
            
            data[dataIndex++] = theValue;
            uint32_t numLongsLeft  = ((theValue & kGretinaNumberWordsMask)>>16)-1;
            int32_t totalNumLongs  = (numLongs + numLongsLeft);
             
       
            /* OK, now use dma access. */
                /* Gretina IV card */
       
            result = DMARead(fifoAddress,fifoAddressMod, (uint32_t) 4,
                             (uint8_t*)(&data[dataIndex]),numLongsLeft*4); 
            dataIndex += numLongsLeft;
            
            if (result != (int32_t)numLongsLeft*4) return true; 
            data[savedIndex] |= totalNumLongs; //see, we did fill it in...
       
        } else if(result < 0) {
            LogBusErrorForCard(GetSlot(),"Rd Err: Gretina 0x%04x %s",baseAddress,strerror(errno));
        } else {
            //oops... really bad -- the buffer read is out of sequence -- try to recover 
            LogErrorForCard(GetSlot(),"Rd Err: Gretina 0x%04x Buffer out of sequence, trying to recover",baseAddress);
            uint32_t i = 0;
            while(i < sizeOfFIFO) {
                result = VMERead(fifoAddress,
                                 GetAddressModifier(), 
                                 (uint32_t) 0x4,
                                 theValue); 
                if (result == 0) { // means the FIFO is empty
                    return true; 
                } else if (result < 0) {
                    LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                    return true; 
                }
                if (theValue == kGretinaPacketSeparater) break;
                i++;
            }
            //read the first word of actual data so we know how much to read
            //note that we are NOT going to save the data, but we do use the data buffer to hold the garbage
            //we'll reset the index to dump the data later....
            result = VMERead(fifoAddress,
                             GetAddressModifier(),
                             (uint32_t) 0x4,
                             theValue); 
           
            if (result < 0) {
                LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                return true; 
            }
            uint32_t numLongsLeft  = ((theValue & kGretinaNumberWordsMask)>>16)-1;
             
            result = DMARead(fifoAddress,fifoAddressMod, (uint32_t) 4,
                             (uint8_t*)(&data[dataIndex]),numLongsLeft*4); 
            if (result < 0) {
                LogBusErrorForCard(GetSlot(),"Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                return true; 
            }
            dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
        }
    }
    return true; 
}
