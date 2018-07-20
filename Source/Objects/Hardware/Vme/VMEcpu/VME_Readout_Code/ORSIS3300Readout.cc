#include "ORSIS3300Readout.hh"
#include <errno.h>
uint32_t ORSIS3300Readout::eventCountOffset[4][2]={ //group,bank
    {0x00200010,0x00200014},
    {0x00280010,0x00280014},
    {0x00300010,0x00300014},
    {0x00380010,0x00380014},
};

uint32_t ORSIS3300Readout::bankMemory[4][2]={
    {0x00400000,0x00600000},
    {0x00480000,0x00680000},
    {0x00500000,0x00700000},
    {0x00580000,0x00780000},
};    

ORSIS3300Readout::ORSIS3300Readout(SBC_card_info* ci) : 
ORVVmeCard(ci), fCurrentBank(0)
{
} 

bool ORSIS3300Readout::Readout(SBC_LAM_Data* lamData)
{
    
    uint32_t dataId       = GetHardwareMask()[0];
    uint32_t locationMask = ((GetCrate() & 0x0000000f)<<21) | 
                            ((GetSlot() & 0x0000001f)<<16);
    uint32_t bankSwitchMode  = GetDeviceSpecificData()[0];
    uint32_t numberOfSamples = GetDeviceSpecificData()[1];
    uint32_t moduleID        = GetDeviceSpecificData()[2];
    int32_t result;

    uint32_t mask;
    
    //read the acq register and decode the bank full and bank busy bits
    uint32_t theValue;
    result = VMERead(GetBaseAddress()+kSISAcqReg,
                     GetAddressModifier(),
                     sizeof(theValue),
                     theValue); 
    if (result < (int32_t) sizeof(theValue)){
        LogBusErrorForCard(GetSlot(),"Rd Err0: SIS3300 0x%04x %s",kSISAcqReg,strerror(errno));
        return true; 
    }
    mask = (fCurrentBank) ? kSISBank2ClockStatus : kSISBank1ClockStatus;
    bool bankIsFull = ((theValue & mask) == 0);
    
    mask =  (fCurrentBank?kSISBank2BusyStatus : kSISBank1BusyStatus);
    bool bankIsBusy = ((theValue & mask) != 0);
    
    if(bankIsFull && !bankIsBusy) {
        //read the number of events
        uint32_t numEvents;
        result = VMERead(GetBaseAddress()+eventCountOffset[fCurrentBank][0],
                         GetAddressModifier(), 
                         sizeof(numEvents),
                         numEvents);
        if (result < (int32_t) sizeof(numEvents)){
            LogBusErrorForCard(GetSlot(),"Rd Err1: SIS3300 0x%04x %s",
                eventCountOffset[fCurrentBank][0],strerror(errno));
            return true; 
        }
        for(uint32_t event=0;event<numEvents;event++){
            
            //read the trigger Event Directory
            uint32_t triggerEventBankReg = ((fCurrentBank) ? 
                kTriggerEvent2DirOffset : 
                kTriggerEvent1DirOffset) + 
                (event*sizeof(uint32_t));
            uint32_t triggerEventDir;
            result = VMERead(GetBaseAddress()+triggerEventBankReg,
                             GetAddressModifier(), 
                             sizeof(triggerEventDir),
                             triggerEventDir);
            if (result < (int32_t) sizeof(triggerEventDir)){
                LogBusErrorForCard(GetSlot(),"Rd Err2: SIS3300 0x%04x %s",
                    triggerEventBankReg,strerror(errno));
                return true; 
            }
            
            uint32_t startOffset = ((triggerEventDir & 0x1ffff) 
                                   & (numberOfSamples-1));
            uint32_t triggerTime;
            uint32_t triggerTriggerReg = ((fCurrentBank) ? 
                kTriggerTime2Offset : 
                kTriggerTime1Offset) + 
                (event*sizeof(int32_t));
            result = VMERead(GetBaseAddress()+triggerTriggerReg,
                             GetAddressModifier(), 
                             sizeof(triggerTime),
                             triggerTime);
            if (result < (int32_t) sizeof(triggerTime)){
                LogBusErrorForCard(GetSlot(),"Rd Err3: SIS3300 0x%04x %s",
                    triggerTriggerReg,strerror(errno));
                return true; 
            }
            
            for(uint32_t group=0;group<4;group++){
                uint32_t channelMask = triggerEventDir 
                    & (0xC0000000 >> (group*2));
                if(channelMask==0)continue;
                
                ensureDataCanHold(numberOfSamples + 4);  
                
                //only read the channels that have trigger info
                uint32_t totalNumLongs = numberOfSamples + 4;
                uint32_t startIndex = dataIndex;
                //but we are going to write over this below
                data[dataIndex++] = dataId | totalNumLongs; 
                data[dataIndex++] = locationMask | 
                    ((moduleID==0x3301) ? 1:0);
                
                data[dataIndex++] = triggerEventDir & 
                    (channelMask | 0x00FFFFFF);
                data[dataIndex++] = ((event&0xFF)<<24) | 
                    (triggerTime & 0xFFFFFF);
            
                // The first read is from startOffset -> nPagesize.
                uint32_t nLongsToRead = numberOfSamples - startOffset;    
                if(nLongsToRead>0){
                    result = DMARead(GetBaseAddress()+
                                     bankMemory[group][fCurrentBank] +
                                     4*startOffset,
                                     //0x9, // MBLT 64 
                                     0x8, // MBLT 64 
                                     (uint32_t) 8,
                                     (uint8_t*)&data[dataIndex],
                                     nLongsToRead*4);
                    if (result < (int32_t) nLongsToRead*4){
                        dataIndex = startIndex; //dump the record
                        LogBusErrorForCard(GetSlot(),"DMA2: SIS3300 Rd Error: %s",
                            strerror(errno));
                        return true; 
                    }
                    dataIndex +=  nLongsToRead;
                }
                
                // The second read, if necessary, is from 0 ->nEventEnd-1.
                if(startOffset>0) {
                    result = DMARead(GetBaseAddress()+
                                     bankMemory[group][fCurrentBank],
                                     //0x9, // MBLT 64 
                                     0x8, // MBLT 64 
                                     (uint32_t) 8,
                                     (uint8_t*)&data[dataIndex],
                                     startOffset*4);
                
                    if (result < (int32_t) startOffset*4){
                        dataIndex = startIndex; //dump the record
                        LogBusErrorForCard(GetSlot(),"Rd Err5: SIS3300 0x%04x %s",
                            bankMemory[group][fCurrentBank],strerror(errno));
                        return true;
                    }
                    dataIndex +=  startOffset;
                }
                data[startIndex] = dataId | dataIndex;
                //we ship from here to prevent putting 
                //too much data into the data array
                commitData();
                
            }
             
        }
        
        uint32_t clearBankReg = fCurrentBank ? 
            kClearBank2FullFlag : 
            kClearBank1FullFlag;
        uint32_t dummy = 0;
        result = VMEWrite(GetBaseAddress()+clearBankReg,
                          GetAddressModifier(), 
                          sizeof(dummy),
                          dummy);
        if (result < (int32_t) sizeof(dummy)){
            LogBusErrorForCard(GetSlot(),"Rd Err6: SIS3300 0x%04x %s",
                clearBankReg,strerror(errno));
            return true; 
        }        
        if(bankSwitchMode) {
            fCurrentBank= (fCurrentBank+1)%2;
        }
                
        //Arm the current Bank
        uint32_t armBit = fCurrentBank ?
            kSISSampleBank2 : 
            kSISSampleBank1;
        result = VMEWrite(GetBaseAddress()+kSISAcqReg,
                          GetAddressModifier(), 
                          sizeof(armBit),
                          armBit);
        if (result < (int32_t) sizeof(armBit)){
            LogBusErrorForCard(GetSlot(),"Rd Err7: SIS3300 0x%04x %s",
                kSISAcqReg,strerror(errno));
            return true; 
        }        
        //Start Sampling
        result = VMEWrite(GetBaseAddress()+kStartSampling,
                          GetAddressModifier(), 
                          sizeof(dummy),
                          dummy);
        if (result < (int32_t) sizeof(dummy)){
            LogBusErrorForCard(GetSlot(),"Rd Err8: SIS3300 0x%04x %s",
                kStartSampling,strerror(errno));
            return true; 
        }
    }
    return true; 
}
