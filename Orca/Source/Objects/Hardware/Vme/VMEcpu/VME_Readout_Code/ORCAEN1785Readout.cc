#include "ORCAEN1785Readout.hh"
#include "readout_code.h"
#include <errno.h>

#define ShiftAndExtract(aValue,aShift,aMask) (((aValue)>>(aShift)) & (aMask))

bool ORCAEN1785Readout::Readout(SBC_LAM_Data* lamData)
{
    int16_t leaf_index;
	uint32_t dataId               = GetHardwareMask()[0];
	uint32_t locationMask         = ((GetCrate() & 0x01e)<<21) | 
                                    ((GetSlot() & 0x0000001f)<<16);
	uint32_t firstStatusRegOffset = GetDeviceSpecificData()[0];
 	uint32_t dataBufferOffset     = GetDeviceSpecificData()[1];

	uint16_t theStatusReg;
	int32_t result = VMERead(GetBaseAddress()+firstStatusRegOffset,
							 0x39,
							 sizeof(theStatusReg),
							 theStatusReg);
	
	if((result == sizeof(theStatusReg)) && (theStatusReg & 0x0001)){
		//OK, at least one data value is ready, first value read should be a header
		uint32_t dataValue;
		result = VMERead(GetBaseAddress()+dataBufferOffset, 0x39, sizeof(dataValue), dataValue);
		if((result == sizeof(dataValue)) && (ShiftAndExtract(dataValue,24,0x7) == 0x2)){
			int32_t numMemorizedChannels = ShiftAndExtract(dataValue,8,0x3f);
			int32_t i;
			if((numMemorizedChannels>0)){
				//make sure the data buffer can hold our data. Note that we do NOT ship the end of block. 
				ensureDataCanHold(numMemorizedChannels + 2);
				
				int32_t savedDataIndex = dataIndex;
				data[dataIndex++] = dataId | (numMemorizedChannels + 2);
				data[dataIndex++] = locationMask;
				
				for(i=0;i<numMemorizedChannels;i++){
					result = VMERead(GetBaseAddress()+dataBufferOffset, 0x39, sizeof(dataValue), dataValue);
					if((result == sizeof(dataValue)) && (ShiftAndExtract(dataValue,24,0x7) == 0x0))data[dataIndex++] = dataValue;
					else break;
				}
				
				//OK we read the data, get the end of block
				result = VMERead(GetBaseAddress()+dataBufferOffset, 0x39, sizeof(dataValue), dataValue);
				if((result != sizeof(dataValue)) || (ShiftAndExtract(dataValue,24,0x7) != 0x4)){
					//some kind of bad error, report and flush the buffer
					LogBusErrorForCard(GetSlot(),"Rd Err: CAEN 965 0x%04x %s", GetBaseAddress(),strerror(errno));
					dataIndex = savedDataIndex;
					FlushDataBuffer();
				}
				
				//read out the children
				leaf_index = GetNextTriggerIndex()[0];
				while(leaf_index >= 0) {
					ORVCard* card = peek_at_card(leaf_index);
					if (!card) {
						// means we couldn't find the card.
						// Shouldn't happen but...
						LogErrorForCard(GetSlot(),"Readout Err: Card at index %i not found",leaf_index);
						break;
					}
					leaf_index = readout_card(leaf_index,lamData);
				}
			}
		}
	}
	
    return true; 
}

void ORCAEN1785Readout::FlushDataBuffer()
{
 	uint32_t dataBufferOffset     = GetDeviceSpecificData()[1];
	//flush the buffer, read until not valid datum
	int32_t i;
	for(i=0;i<0x07FC;i++) {
		uint32_t dataValue;
		int32_t result = VMERead(GetBaseAddress()+dataBufferOffset, 0x39, sizeof(dataValue), dataValue);
		if(result<0){
			LogBusErrorForCard(GetSlot(),"Flush Err: CAEN 965 0x%04x %s", GetBaseAddress(),strerror(errno));
			break;
		}
		if(ShiftAndExtract(dataValue,24,0x7) == 0x6) break;
	}
}
