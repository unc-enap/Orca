#include "ORCAEN419Readout.hh"
#include <errno.h>
bool ORCAEN419Readout::Readout(SBC_LAM_Data* lamData)
{
	uint32_t dataId               = GetHardwareMask()[0];
	uint32_t locationMask         = ((GetCrate() & 0x01e)<<21) | 
                                    ((GetSlot() & 0x0000001f)<<16);
    uint32_t enabledMask		  = GetDeviceSpecificData()[0];
	uint32_t firstStatusRegOffset = GetDeviceSpecificData()[1];
 	uint32_t firstAdcRegOffset    = GetDeviceSpecificData()[2];

	ensureDataCanHold(4 * 2); //max this card can produce

	for(uint32_t chan=0;chan<4;chan++){
		if(enabledMask & (1<<chan)){
			uint16_t theStatusReg;
            int32_t result = VMERead(GetBaseAddress()+firstStatusRegOffset+(chan*4),
                                     0x39,
                                     sizeof(theStatusReg),
                                     theStatusReg);
			if(result == sizeof(theStatusReg) && (theStatusReg&0x8000)){
				uint16_t aValue;
                result = VMERead(GetBaseAddress()+firstAdcRegOffset+(chan*4),
                                 0x39,
                                 sizeof(aValue),
                                 aValue);
				if(result == sizeof(aValue)){
					if(((dataId) & 0x80000000)){ //short form
						data[dataIndex++] = dataId | locationMask | 
                            ((chan & 0x0000000f) << 12) | (aValue & 0x0fff);
					} 
					else { //int32_t form
						data[dataIndex++] = dataId | 2;
						data[dataIndex++] = locationMask | 
                            ((chan & 0x0000000f) << 12) | (aValue & 0x0fff);
					}
				} 
				else if (result < 0) {
                    LogBusErrorForCard(GetSlot(),"Rd Err: CAEN 419 0x%04x %s",
                        GetBaseAddress(),strerror(errno));                
                }
			} 
			else if (result < 0) {
                LogBusErrorForCard(GetSlot(),"Rd Err: CAEN 419 0x%04x %s",
                    GetBaseAddress(),strerror(errno));   
            }
		}
	}
    return true; 
}
