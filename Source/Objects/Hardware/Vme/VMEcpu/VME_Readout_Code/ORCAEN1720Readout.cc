#include "ORCAEN1720Readout.hh"
#include <errno.h> 

#define kFastBLTThreshold 2 //must be 2 or more

bool ORCAEN1720Readout::Start() {
    uint32_t numBLTEventsReg = GetDeviceSpecificData()[7];

    //get the BLTEvents number
    int32_t result = VMERead(GetBaseAddress()+numBLTEventsReg,
        GetAddressModifier(),
        sizeof(currentBLTEventsNumber),
        currentBLTEventsNumber);
    if (result != sizeof(currentBLTEventsNumber)) { 
        LogBusErrorForCard(GetSlot(),"V1720 0x%0x Couldn't read register", numBLTEventsReg);
        return false; 
    }
    if (currentBLTEventsNumber == 0) {
        // We will have a problem, this needs to be set *before*
        // starting a run.
        LogErrorForCard(GetSlot(),"CAEN: BLT Events register must be set BEFORE run start");
        return false;
    }

    fixedEventSize = GetDeviceSpecificData()[8];
    userBLTEventsNumber = GetDeviceSpecificData()[9];
    firmwareBugZero = 0;

    return true;
}   

bool ORCAEN1720Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t vmeStatusReg = GetDeviceSpecificData()[0];
    uint32_t eventSizeReg       = GetDeviceSpecificData()[1];
    uint32_t fifoBuffReg        = GetDeviceSpecificData()[2];
    uint32_t fifoAddressMod     = GetDeviceSpecificData()[3];
    uint32_t fifoBuffSize       = GetDeviceSpecificData()[4];
    uint32_t location           = GetDeviceSpecificData()[5];
    uint32_t numBLTEventsReg = GetDeviceSpecificData()[7];
    uint32_t dataId             = GetHardwareMask()[0];
    uint32_t eventStored;

    //must be int, not uint
    int32_t result = VMERead(GetBaseAddress() + 0x812c, //eventStored
        GetAddressModifier(),
        sizeof(eventStored),
        eventStored);

    if (result != sizeof(eventStored)) { 
        LogBusErrorForCard(GetSlot(),"V1720 0x%0x Couldn't read VME status", vmeStatusReg);
        return false; 
    }

    if (!eventStored) {
        return true;
    }

    uint32_t eventSize;
    //if the event size is fixed by user, use it, else, get it from the card
    if (fixedEventSize > 0) {
        eventSize = fixedEventSize;
        result = sizeof(eventSize);
    }
    else {
        result = VMERead(GetBaseAddress()+eventSizeReg,
            GetAddressModifier(),
            sizeof(eventSize),
            eventSize);
    }

    if (result != sizeof(eventSize)) {
        LogBusErrorForCard(GetSlot(),"Rd Err eventSize: V1720 0x%04x %s", GetBaseAddress(), strerror(errno));
        return false;
    }

    if (eventSize == 0) { //corrupted event in variable size mode, e.g. due to a buffer full
        return true;   
    }


    //make sure we can get all the user requested events, grab 1 otherwise
    //the change will take place after we read out this event
    uint32_t thisBLTEventsNumber = currentBLTEventsNumber;
    if (eventStored > kFastBLTThreshold + 2 * userBLTEventsNumber + firmwareBugZero) {
        if (currentBLTEventsNumber == 1) {
            int32_t result = VMEWrite(GetBaseAddress() + numBLTEventsReg,
                GetAddressModifier(),
                sizeof(userBLTEventsNumber),
                userBLTEventsNumber);

            if (result != sizeof(userBLTEventsNumber)) { 
                LogBusErrorForCard(GetSlot(),"V1720 0x%0x Couldn't set BLT Number", numBLTEventsReg);
                return false; 
            }

            currentBLTEventsNumber = userBLTEventsNumber;
        }
    }
    else {
        if (currentBLTEventsNumber == userBLTEventsNumber) {
            uint32_t newBLTEventsNumber = 1;
            int32_t result = VMEWrite(GetBaseAddress() + numBLTEventsReg,
                GetAddressModifier(),
                sizeof(newBLTEventsNumber),
                newBLTEventsNumber);

            if (result != sizeof(newBLTEventsNumber)) { 
                LogBusErrorForCard(GetSlot(),"V1720 0x%0x Couldn't set BLT Number", numBLTEventsReg);
                return false; 
            }

            currentBLTEventsNumber = 1;
        }
    }
    
    uint32_t startIndex = dataIndex;
    //eventSize in uint32_t words, fifoBuffSize in Bytes
    uint32_t dmaTransferCount = thisBLTEventsNumber * eventSize * 4 / fifoBuffSize + 1;
    int32_t bufferSizeNeeded = dmaTransferCount * fifoBuffSize / 4 + 1 + 2; //+orca_header
    if ((int32_t)(bufferSizeNeeded) > (kMaxDataBufferSizeLongs - dataIndex)) {
        /* We can't read out. */ 
        LogErrorForCard(GetSlot(),"Temp buffer too small, requested (%d) > available (%d)",
            bufferSizeNeeded, 
            kMaxDataBufferSizeLongs-dataIndex);
        return false; 
    } 
    ensureDataCanHold(bufferSizeNeeded);

    if (thisBLTEventsNumber == 1) { //recovery safe mode
        if (eventStored <= firmwareBugZero) {
            return true;
        }

        uint32_t vmeStatus;
        result = VMERead(GetBaseAddress() + 0xEF04,
            GetAddressModifier(),
            sizeof(vmeStatus),
            vmeStatus);

        vmeStatus &= 0x1;

        if (!vmeStatus) {
            firmwareBugZero = eventStored;
            return true;
        }
    }

    dataIndex += 2; //the header to be filled after the DMA transfer succeeds

    do {
        result = DMARead(GetBaseAddress()+fifoBuffReg,
            fifoAddressMod,
            (uint32_t) 8,
            (uint8_t*) (data+dataIndex),
            fifoBuffSize);

        dataIndex += fifoBuffSize / 4;
        dmaTransferCount--;
    }
    while (dmaTransferCount && result > 0);

    //ignore the last BERR, it's there on purpose
    if (result < 0 && dmaTransferCount && errno != 0) {
        LogBusErrorForCard(GetSlot(),"Error reading DMA for V1720: %s", strerror(errno));
        dataIndex = startIndex;
        return true; 
    }
    
    if (!dmaTransferCount && result > 0) {
        LogErrorForCard(GetSlot(),"Error reading DMA for V1720, BERR missing");
        dataIndex = startIndex;
        return true;
    }

    uint32_t bufferSizeUsed = 2 + thisBLTEventsNumber * eventSize;
    dataIndex = startIndex + bufferSizeUsed;
    data[startIndex] = dataId | bufferSizeUsed;
    data[startIndex + 1] = location;

    return true;
}

