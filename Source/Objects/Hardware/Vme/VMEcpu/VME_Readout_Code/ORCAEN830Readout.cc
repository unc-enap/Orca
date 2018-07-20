#include "ORCAEN830Readout.hh"
#include <errno.h>
#include <sys/timeb.h>
#include "readout_code.h"
#include "ORCAEN830Shared.hh"
#include <stdio.h>
uint64_t rollOverCount[21];
uint32_t lastChan0Count[21];


bool ORCAEN830Readout::Start()
{
    errorCount      = 0;
    goodCount       = 0;
    int32_t reset   = (int32_t)GetDeviceSpecificData()[6];
    if(reset){
        for(uint32_t i=0;i<21;i++){
            lastChan0Count[i] = 0;
            rollOverCount[i] = 0;
        }
    }
    
    uint32_t enabledMask = GetDeviceSpecificData()[0];
    if(enabledMask & (0x1)) chan0Enabled = true;
    else                    chan0Enabled = false;
	return true;
}

bool ORCAEN830Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t statusRegOffset	= GetDeviceSpecificData()[1];
    int32_t chan0Offset		    = (int32_t)GetDeviceSpecificData()[5];
    uint16_t statusWord;
    uint32_t addressModifier    = GetAddressModifier();
    uint32_t baseAdd            = GetBaseAddress();
    int32_t result = VMERead(baseAdd + statusRegOffset,addressModifier, sizeof(statusWord),statusWord);

    if(result != sizeof(statusWord)){
        LogBusError("Status Rd: V830 0x%04x %s",GetBaseAddress(),strerror(errno));
    }
    else  {
        bool dataReady = statusWord & (0x1L << 0);
		if(dataReady){
			uint32_t dataId			= GetHardwareMask()[0];
			uint32_t locationMask	= ((GetCrate() & 0x0f)<<21) | ((GetSlot() & 0x1f)<<16);
			
			uint16_t numEvents = 0;
			uint32_t mebEventNumRegOffset	= GetDeviceSpecificData()[2];
            result = VMERead(baseAdd + mebEventNumRegOffset,addressModifier, sizeof(numEvents), numEvents);
			if(result != sizeof(numEvents)){
				LogBusErrorForCard(GetSlot(),"Num Events Rd: V830 0x%04x %s",baseAdd+mebEventNumRegOffset,strerror(errno));
			}
			else if(numEvents){
				
				uint32_t enabledMask		= GetDeviceSpecificData()[0];
				uint32_t eventBufferOffset	= GetDeviceSpecificData()[3];
				uint32_t numEnabledChannels	= GetDeviceSpecificData()[4];
                
				for(uint32_t event=0;event<numEvents;event++){
					ensureDataCanHold(5+numEnabledChannels); //event size
					data[dataIndex++] = dataId | (5+numEnabledChannels);
					data[dataIndex++] = locationMask;
                    uint32_t indexForRollOver = dataIndex;  //save a place for the roll over
                    data[dataIndex++] = 0;                  //channel 0 rollover
					data[dataIndex++] = enabledMask;
                    
                    //get the header -- always the first word
                    uint32_t dataHeader = 0;
                    if(VMERead(baseAdd + eventBufferOffset,addressModifier, sizeof(dataHeader),dataHeader)!= sizeof(dataHeader)){
                        LogBusErrorForCard(GetSlot(),"Header Rd: V830 0x%04x %s",baseAdd+eventBufferOffset,strerror(errno));
                    }
                    data[dataIndex++] = dataHeader;
                    
                    for(uint16_t i=0 ; i<numEnabledChannels ; i++){
                        uint32_t aValue;
                        if(VMERead(baseAdd + eventBufferOffset,addressModifier, sizeof(aValue), aValue) != sizeof(aValue)){
                            LogBusErrorForCard(GetSlot(),"Data Rd: V830 0x%04x %s",baseAdd+eventBufferOffset,strerror(errno));
                        }
                        //keep a rollover count for channel zero
                        if(chan0Enabled && i==0){
                            if(aValue!=0){
                                if(aValue<lastChan0Count[GetSlot()]){
                                    rollOverCount[GetSlot()]++;
                                }
                                int64_t final = (rollOverCount[GetSlot()] << 32) | aValue;
                                final += chan0Offset;
                                lastChan0Count[GetSlot()] = aValue;
                                data[indexForRollOver] = (final >> 32) & 0xffffffff;
                                data[dataIndex++]      = final & 0xffffffff;
                                goodCount++;
                            }
                            else {
                                errorCount++;
                                LogMessageForCard(GetSlot(),"Bad Count: V830 0x%x %d/%d",baseAdd,errorCount,goodCount);
                                data[indexForRollOver] = 0xffffffff;
                                data[dataIndex++]      = 0xffffffff;
                            }
                        }
                        else    data[dataIndex++]      = aValue;
                    }
					int32_t leaf_index;
					//read out the children that are in the readout list
					leaf_index = GetNextTriggerIndex()[0];
					while(leaf_index >= 0) {
						leaf_index = readout_card(leaf_index,lamData);
					}
				}
			}
		}
	}
    return true; 
}
