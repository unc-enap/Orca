#include "ORCAEN260Readout.hh"
#include <errno.h>

bool ORCAEN260Readout::Start()
{
	lastScalerValue = 0xFFFFFFFF;
	return true;
}

bool ORCAEN260Readout::Readout(SBC_LAM_Data* lamData)
{
	uint32_t dataId					= GetHardwareMask()[0];
	uint32_t locationMask			= ((GetCrate() & 0x01e)<<21) | 
									  ((GetSlot() & 0x0000001f)<<16);
	uint32_t enabledMask			= GetDeviceSpecificData()[0];
 	uint32_t dataBufferOffset		= GetDeviceSpecificData()[1];
	bool     shipOnlyOnlyOnChange   = GetDeviceSpecificData()[2];
	uint32_t channelToWatch			= GetDeviceSpecificData()[3];
	
	time_t	ut_Time;
	time(&ut_Time);
	
	ensureDataCanHold(19);
	int32_t savedDataIndex = dataIndex; //in case we have to dump the record
	
	data[dataIndex++] = dataId | 19;
	data[dataIndex++] = locationMask  | (enabledMask & 0x0000ffff);
	data[dataIndex++] = ut_Time;		//seconds since 1970
	
	uint32_t i;
	for(i=0;i<16;i++){
		uint32_t dataValue = 0;
		if(enabledMask & (0x1<<i)){
			int32_t result = VMERead(GetBaseAddress()+dataBufferOffset+(i*0x04), 0x39, sizeof(dataValue), dataValue);
			if(result != sizeof(dataValue)){
                LogBusErrorForCard(GetSlot(),"Error for V260: %s", strerror(errno));
				dataIndex = savedDataIndex;
				break;
			}
		}
		uint32_t theScalerValue = dataValue & 0x00ffffff;
		data[dataIndex++] = theScalerValue;
		
		if(shipOnlyOnlyOnChange){
			if(i == channelToWatch){
				if(lastScalerValue == theScalerValue){
					dataIndex = savedDataIndex; //dump the record
					break;						//no need to continue;
				}
				else lastScalerValue = theScalerValue;
			}
		}
	}
	
	
			   
    return true; 
}
