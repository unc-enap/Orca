#include "ORGretina4MReadout.hh"
#include <errno.h>
#include <stdio.h>
#include <iostream>
using namespace std;
bool ORGretina4MReadout::Readout(SBC_LAM_Data* /*lamData*/)
{

#define kGretinaPacketSeparator ((int32_t)(0xAAAAAAAA))
#define kGretina4MFIFOEmpty			0x00100000
#define kGretina4MFIFO16KFull       0x00800000
#define kGretina4MFIFO30KFull		0x01000000
#define kGretina4MFIFOFull          0x02000000
    
#define kUseDMA  true
    
    uint32_t baseAddress      = GetBaseAddress();  
    uint32_t fifoStateAddress = GetDeviceSpecificData()[0];
    uint32_t fifoAddress      = GetDeviceSpecificData()[1];
    uint32_t fifoAddressMod   = GetDeviceSpecificData()[2];
    uint32_t fifoResetAddress = GetDeviceSpecificData()[3];
    uint32_t location         = GetDeviceSpecificData()[4];
    uint32_t dataId           = GetHardwareMask()[0];
    uint32_t slot             = GetSlot(); 

    int32_t  result;
    uint32_t fifoState = 0;
    uint32_t fifoFlag = 0;
    
    result = VMERead(fifoStateAddress,
                     GetAddressModifier(),
                     (uint32_t) 4,
                     fifoState);
    if (result != sizeof(fifoState)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoStateAddress,strerror(errno));
    }
    else if ((fifoState & kGretina4MFIFOEmpty) == 0 ) {
        
        //we want to read as much as possible to have the highest thru-put
        int32_t                                     numEventsToRead = 1;
        if(fifoState & kGretina4MFIFO30KFull){
            numEventsToRead = 256;
            fifoFlag = 0x80000000;
        }
        else if(fifoState & kGretina4MFIFO16KFull){
            numEventsToRead = 128;
            fifoFlag = 0x40000000;
        }
        
        int32_t i;
        for(i=0;i<numEventsToRead;i++){
            ensureDataCanHold(10*(1024+2)); //ensure we leave plenty of room. If we are that close to filling the data buffer.. to bad -- we lose the data
     
            int32_t savedIndex      = dataIndex;
            data[dataIndex++]       = dataId | 1026;
            data[dataIndex++]       = location | fifoFlag;
            int32_t firstDataIndex  = dataIndex;

            if(kUseDMA){
                result = DMARead(fifoAddress,fifoAddressMod, 4, (uint8_t*)(&data[dataIndex]),1024*4);
                dataIndex+=1024;
            }
            else {
                //non-DMA for testing
                int32_t j;
                for(j=0;j<1024;j++){
                    uint32_t aValue = 0;
                    result = VMERead(fifoAddress,GetAddressModifier(),4, aValue);
                    if (result != sizeof(int32_t))break;
                    data[dataIndex++] = aValue;
                }
            }
            if ((result < 0) || (data[firstDataIndex] != kGretinaPacketSeparator)) {
                dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
                if(result < 0)  LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                else            LogBusErrorForCard(slot,"No Separator: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                clearFifo(fifoResetAddress);
                break;
            }
         }
        
        //a test -- do a non-DMA read to see if the number of SBC errors is reduced
        uint32_t junk;
        VMERead(fifoStateAddress,GetAddressModifier(),(uint32_t) 4, junk);
    }
    return true;
}

void ORGretina4MReadout::clearFifo(uint32_t fifoClearAddress)
{
    uint32_t slot             = GetSlot();
    uint32_t orginalData = 0;
    int32_t result = VMERead(fifoClearAddress, 
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                     orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData |= (0x1<<27);

    result = VMEWrite(fifoClearAddress,
                     GetAddressModifier(),
                     (uint32_t) 0x4,
                      orginalData);

    if (result != sizeof(orginalData)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
    orginalData &= ~(0x1<<27);

    result = VMEWrite(fifoClearAddress,
                      GetAddressModifier(),
                      (uint32_t) 0x4,
                      orginalData);
    
    if (result != sizeof(orginalData)){
        LogBusErrorForCard(slot,"Rd Err: Gretina4 0x%04x %s",fifoClearAddress,strerror(errno));
        return;
    }
}
