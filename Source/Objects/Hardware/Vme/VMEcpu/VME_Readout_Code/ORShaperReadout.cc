#include "ORShaperReadout.hh"
#include <errno.h>
//#include <sys/timeb.h>
#include <sys/time.h>

bool ORShaperReadout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t conversionRegOffset = GetDeviceSpecificData()[1];
    
    uint8_t theConversionMask;
    int32_t result = VMERead(GetBaseAddress() + conversionRegOffset,
                             0x29, 
                             sizeof(theConversionMask),
                             theConversionMask);
    if(result == (int32_t) sizeof(theConversionMask) && theConversionMask != 0){

        uint32_t dataId            = GetHardwareMask()[0];
        uint32_t locationMask      = ((GetCrate() & 0xf)<<21) |
                                     ((GetSlot() & 0x1f)<<16);
        uint32_t onlineMask        = GetDeviceSpecificData()[0];
        uint32_t firstAdcRegOffset = GetDeviceSpecificData()[2];
		uint8_t  shipTimeStamp     = GetDeviceSpecificData()[3];
		ensureDataCanHold(2*8 + 4*8); //max this card can produce
		
        for (int16_t channel=0; channel<8; ++channel) {
            if(onlineMask & theConversionMask & (1L<<channel)){
				
				
                uint16_t aValue;
                result = VMERead(GetBaseAddress() + firstAdcRegOffset + 2*channel,
                                 0x29, 
                                 sizeof(aValue),
                                 aValue);
                if(result == sizeof(aValue)){
                    if(((dataId) & 0x80000000)){ //short form
                        data[dataIndex++] = dataId | locationMask | 
                            ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    } 
					else { //int32_t form
						int length;
						if(shipTimeStamp)length = 4;
						else length = 2;
						
                        data[dataIndex++] = dataId | length;
                        data[dataIndex++] = locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
						if(shipTimeStamp){
                            struct timeval ts;
                            if(gettimeofday(&ts,NULL) ==0){
  								data[dataIndex++] = ts.tv_sec;
								data[dataIndex++] = ts.tv_usec;
                            }
							else {
								data[dataIndex++] = 0xFFFFFFFF;
								data[dataIndex++] = 0xFFFFFFFF;
							}

                            /* original
							struct timeb mt;
							if (ftime(&mt) == 0) {
								data[dataIndex++] = mt.time;
								data[dataIndex++] = mt.millitm;
							}
							else {
								data[dataIndex++] = 0xFFFFFFFF;
								data[dataIndex++] = 0xFFFFFFFF;

							}
                             */
						}
                    }
                } 
				else if (result < 0) {
                    LogBusErrorForCard(GetSlot(),"Rd Err: Shaper 0x%04x %s",
                        GetBaseAddress(),strerror(errno));                
                }
            }
        }
    } else if (result < 0) {
        LogBusErrorForCard(GetSlot(),"Rd Err: Shaper 0x%04x %s",GetBaseAddress(),strerror(errno)); 
    }

    return true; 
}
