#include "ORCAEN1730Readout.hh"
#include <errno.h>
#include <stdio.h>

#define kEventReadyMask 0x8
#define kFastBLTThreshold 2 //must be 2 or more

bool ORCAEN1730Readout::Start() {
    uint32_t numBLTEventsReg = GetDeviceSpecificData()[7];
    
    //get the BLTEvents number
    int32_t result = VMERead(GetBaseAddress()+numBLTEventsReg,
                             GetAddressModifier(),
                             sizeof(currentBLTEventsNumber),
                             currentBLTEventsNumber);
    if (result != sizeof(currentBLTEventsNumber)) {
        LogBusErrorForCard(GetSlot(),"V1730 0x%0x Couldn't read register", numBLTEventsReg);
        return false;
    }
    if (currentBLTEventsNumber == 0) {
        // We will have a problem, this needs to be set *before*
        // starting a run.
        LogError("CAEN: BLT Events register must be set BEFORE run start");
        return false;
    }
    
    userBLTEventsNumber = GetDeviceSpecificData()[8];
     
    return true;
}   

bool ORCAEN1730Readout::Readout(SBC_LAM_Data*)
{
    uint32_t vmeStatusReg       = GetDeviceSpecificData()[0];
    uint32_t eventSizeReg       = GetDeviceSpecificData()[1];
    uint32_t fifoBuffReg        = GetDeviceSpecificData()[2];
    uint32_t fifoAddressMod     = GetDeviceSpecificData()[3];
    uint32_t fifoBuffSize       = GetDeviceSpecificData()[4];
    uint32_t location           = GetDeviceSpecificData()[5];
    uint32_t dataId             = GetHardwareMask()[0];
    uint32_t numEventsToRead;
    uint32_t vmeStatus;
 
    
    //must be int, not uint
    int32_t result = VMERead(GetBaseAddress() + 0x812c, //numEventsToRead
                             GetAddressModifier(),
                             sizeof(numEventsToRead),
                             numEventsToRead);
   
    if (result != sizeof(numEventsToRead)) {
        LogBusErrorForCard(GetSlot(),"V1730 0x%0x Couldn't read num Events", numEventsToRead);
        return false;
    }
    
    if (!numEventsToRead) return true;
    
    uint32_t eventSize;
    result = VMERead(GetBaseAddress()+eventSizeReg,
                         GetAddressModifier(),
                         sizeof(eventSize),
                         eventSize);
    
    
    if (result != sizeof(eventSize)) {
        LogBusErrorForCard(GetSlot(),"Rd Err eventSize: V1730 0x%04x %s", GetBaseAddress(), strerror(errno));
        return false;
    }
    
    if (eventSize == 0) { //corrupted event in variable size mode, e.g. due to a buffer full
        return false;
    }
    
    //because of problems with transfer rate, we will limit the numEventsToRead to 2
    
    if(numEventsToRead>2)numEventsToRead = 2;
    
    uint32_t startIndex = dataIndex;
    //eventSize in uint32_t words, fifoBuffSize in Bytes
    uint32_t dmaTransferCount = currentBLTEventsNumber * eventSize * 4 / fifoBuffSize + 1;
    int32_t bufferSizeNeeded  = dmaTransferCount * fifoBuffSize / 4 + 1 + 2; //+orca_header
    
//    printf("----------------------------\n");
//    printf("num Events stored: %d\n",   numEventsToRead);
//    printf("fifoBuffSize: %d\n",        fifoBuffSize);
//    printf("bufferSizeNeeded: %d\n",    bufferSizeNeeded);
//    printf("eventSize: %d\n",           eventSize);
//    printf("thisBLTEventsNumber: %d\n", thisBLTEventsNumber);
//    printf("dmaTransferCount: %d\n",    dmaTransferCount);

    if ((int32_t)(bufferSizeNeeded) > kMaxDataBufferSizeLongs) {
        /* We can't read out. */
        LogError("Temp buffer too small, requested (%d) > available (%d)",
                 bufferSizeNeeded,
                 kMaxDataBufferSizeLongs-dataIndex);
        return false;
    }
    ensureDataCanHold(bufferSizeNeeded);
    dmaTransferCount++;
    dataIndex += 2; //the header to be filled after the DMA transfer succeeds
    do {
        result = DMARead(GetBaseAddress()+fifoBuffReg,
                         fifoAddressMod,
                         (uint32_t) 8,
                         (uint8_t*) (data+dataIndex),
                         fifoBuffSize);
       // printf("dma result: %d\n",result);

        
        dataIndex += fifoBuffSize / 4;
        dmaTransferCount--;
        
        VMERead(GetBaseAddress() + vmeStatusReg, //BERR is registered here
                                  GetAddressModifier(),
                                  sizeof(vmeStatus),
                                  vmeStatus);
        if(vmeStatus & 0x4){
            //printf("BERR\n");
            break; //There was a BERR at the end of transfer
        }

        
   } while (dmaTransferCount && result > 0);
    
    if (result < 0 && dmaTransferCount && errno != 0) {
        LogBusErrorForCard(GetSlot(),"Error reading DMA for V1730: %s", strerror(errno));
        dataIndex = startIndex;
        return true; 
    }
    /*
    //ignore the last BERR, it's there on purpose
    if (!dmaTransferCount && result > 0) {
        printf("dmaTransferCount: %d result: %d\n",dmaTransferCount,result);
        LogError("Error reading DMA for V1730, BERR missing");
        dataIndex = startIndex;
        return true;
    }
    */
    uint32_t bufferSizeUsed = 2 + numEventsToRead * eventSize;
    //printf("bufferSizeUsed: %d\n",bufferSizeUsed);
    if(bufferSizeUsed>0x7ffff){
        LogBusErrorForCard(GetSlot(),"V1730 waveform too large");
        dataIndex = startIndex;
        return false;
    }
    dataIndex = startIndex + bufferSizeUsed;
    data[startIndex] = dataId | (bufferSizeUsed & 0x7ffff);
    data[startIndex + 1] = location;
//    printf("id: 0x%08x\n",dataId);
//    printf("0: 0x%08x\n",data[startIndex]);
//        printf("1: 0x%08x\n",data[startIndex+1]);
//        printf("2: 0x%08x\n",data[startIndex+2]);
//        printf("3: 0x%08x\n",data[startIndex+3]);
//        printf("4: 0x%08x\n",data[startIndex+4]);
//        printf("5: 0x%08x\n",data[startIndex+5]);
    return true;
}
