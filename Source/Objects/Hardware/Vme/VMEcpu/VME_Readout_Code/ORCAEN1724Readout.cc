#include "ORCAEN1724Readout.hh"
#include <errno.h>

bool ORCAEN1724Readout::Start() {
	numEventsToReadout = 0;
	
	uint32_t numBLTEventsReg    = GetDeviceSpecificData()[7];
	int32_t result = VMERead(GetBaseAddress()+numBLTEventsReg,
				 GetAddressModifier(),
				 sizeof(numEventsToReadout),
				 numEventsToReadout);
	if ( result != sizeof(numEventsToReadout) ) { 
		LogBusErrorForCard(GetSlot(),"V1724 0x%0x Couldn't read register", numBLTEventsReg);
		return false; 
	}
	if ( numEventsToReadout == 0 ) {
		// We will have a problem, this needs to be set *before*
		// starting a run.
		LogErrorForCard(GetSlot(),"CAEN: BLT Events register must be set BEFORE run start");
		return false; 
	}
	
	fixedEventSize = GetDeviceSpecificData()[8];
	return true;
}	


bool ORCAEN1724Readout::Readout(SBC_LAM_Data* lamData)
{
    // WARNING, this code has *not* been tested!!!!!

    uint32_t numEventsAvailReg  = GetDeviceSpecificData()[0];
    uint32_t eventSizeReg       = GetDeviceSpecificData()[1];
    uint32_t fifoBuffReg        = GetDeviceSpecificData()[2];
    uint32_t fifoAddressMod     = GetDeviceSpecificData()[3];
    uint32_t fifoBuffSize       = GetDeviceSpecificData()[4];
    uint32_t location           = GetDeviceSpecificData()[5];
    uint32_t dataId             = GetHardwareMask()[0];
    
    
    uint32_t numEventsAvail;    
    int32_t result = VMERead(GetBaseAddress()+numEventsAvailReg,
                     GetAddressModifier(),
                     sizeof(numEventsAvail),
                     numEventsAvail);
    if(result == sizeof(numEventsAvail) && (numEventsAvail > 0)){
        //if at least one event is ready
        uint32_t eventSize;
	    //if the event size is fixed by user, use it, if not get it from the card
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
	    
	    
	    if(result == sizeof(eventSize) && eventSize>0){
		    uint32_t startIndex = dataIndex;
		    //eventSize in uint32_t words, fifoBuffSize in Bytes
		    uint32_t dmaTransferCount = numEventsToReadout*eventSize * 4 / fifoBuffSize + 1;
		
		    //if ((int32_t)(numEventsToReadout*(eventSize+1) + 2) >
		    if ((int32_t)(dmaTransferCount * fifoBuffSize / 4 + 1 + 2) >
			(kMaxDataBufferSizeLongs-dataIndex) ) {
			    /* We can't read out. */ 
			    LogErrorForCard(GetSlot(),"Temp buffer too small, requested (%d) > available (%d)",
				     numEventsToReadout*(eventSize+1)+2, 
				     kMaxDataBufferSizeLongs-dataIndex);
			    return false; 
		    } 
		    ensureDataCanHold(2 + dmaTransferCount*fifoBuffSize/4 + 1);
                        
		    data[dataIndex++] = dataId | (2+numEventsToReadout*eventSize);
		    data[dataIndex++] = location; //location = crate and card number
          
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
		if (result < 0 && dmaTransferCount) {
			LogBusErrorForCard(GetSlot(),"Error reading DMA for V1724: %s", strerror(errno));
			dataIndex = startIndex;
			return true; 
		}
		
		if (!dmaTransferCount && result > 0) {
			LogErrorForCard(GetSlot(),"Error reading DMA for V1724, BERR missing");
			dataIndex = startIndex;
			return true;
		}

		//the last DMA is incomplete, fix the dataIndex, and the possible trailing 0xFFFFFFFF
		dataIndex = startIndex + 2 + numEventsToReadout*eventSize;
        } else {
		if (eventSize == 0) {
			uint32_t clearMem = 1;
			result = VMEWrite(GetBaseAddress()+0xEF28,
					  GetAddressModifier(),
					  sizeof(clearMem),
					  clearMem);
			LogErrorForCard(GetSlot(),"Rd Err: V1724 Buffer FULL, flushed.");
		}
		else {
			LogBusErrorForCard(GetSlot(),"Rd Err: V1724 0x%04x %s",
				    GetBaseAddress(),strerror(errno));          
		}
        }
    }

    return true; 
}
