#include "ORVMETrigger32Readout.hh"
#include "SBC_Readout.h"
#include "readout_code.h"
#include "VME_HW_Definitions.h" 
#include <unistd.h>
bool ORVMETrigger32Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t baseAddress, low_word, high_word, statusReg;
    uint16_t placeHolderIndex;
    int16_t leaf_index;
    SBC_LAM_Data localData;
    
    int32_t savedIndex;
    uint32_t gtid;
    uint32_t gtidShortForm;
    uint32_t result;
    uint32_t lValue;
    uint16_t sValue = 0;
    //--------------------------------------------------------------------------//

    //if(index<0)return -1;
    
    //read the status register
    baseAddress = GetBaseAddress(); 
    
    result    = VMERead(baseAddress + kStatusRegOffset,
                        0x29,
                        sizeof(statusReg),
                        statusReg); //short access, the adc Value
    if (result != sizeof(statusReg)) {
        LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Status",baseAddress);
        return false; 
    }
    
     //--------------------------------------------------------------------------------------------------------
    // Handle Trigger #1
    //--------------------------------------------------------------------------------------------------------
    //check for the event1 bit
    if(statusReg & kTrigger1EventMask){
        unsigned char gtBitSet = 0;

        gtidShortForm =  GetHardwareMask()[1] & 0x80000000L;
            
        //save the data word index in case we have to dump this event because of an error
        savedIndex = dataIndex;
        localData.numFormatedWords = 0;
        localData.numberLabeledDataWords = 0;
        
        if(GetDeviceSpecificData()[0]&kUseSoftwareGtid){
        
            //must latch the clock if in soft gtid mode
            lValue = 0;
            result = VMEWrite(baseAddress+kTestLatchTrigger1Time,
                              0x29,
                              sizeof(lValue),
                              lValue);
            
             if (result != sizeof(lValue)) {
                LogErrorForCard(GetSlot(),"Wr Err: TR32 0x%04x Trig1 Latch",baseAddress);
                return false; 
            }
           
            result    = VMERead(baseAddress + kStatusRegOffset,
                                0x29,
                                sizeof(gtid),
                                gtid); //short access, the adc Value
            if (result != sizeof(gtid)) {
                LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Status",baseAddress);
                return false; 
            }
            
            statusReg |= kValidTrigger1GTClockMask;
           
            gtBitSet = 1;
            
            ResetTR32(kTrigger1GTEventReset);
        }
        else {
            if(!(statusReg & kValidTrigger1GTClockMask)){
                //should have been a gt, try some more--but not too many times.
                int k;
                for(k=0;k<5;k++){
                    //read the status reg
                    result    = VMERead(baseAddress + kStatusRegOffset,
                                        0x29,
                                        sizeof(statusReg),
                                        statusReg); //short access, the adc Value
                  
                    if (result != sizeof(statusReg)) {
                       LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Status",baseAddress);
                       return false;  
                    }
                    if(statusReg & kValidTrigger1GTClockMask)break;
                    else usleep(1);
                }
            }
            if(statusReg & kValidTrigger1GTClockMask){
                //read the gtid;
                if(!(GetDeviceSpecificData()[0] & kUseSoftwareGtid)){
                    result    = VMERead(baseAddress + kReadTrigger1GTID,
                                        0x29,
                                        sizeof(gtid),
                                        gtid); //short access, the adc Value
                    if (result != sizeof(gtid)) {
                        LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Trig1 GTID",baseAddress);
                        return false;   
                    }
                }
                gtBitSet = 1;
            }
        }
        
        if(gtidShortForm){
            localData.formatedWords[localData.numFormatedWords++] = 
                GetHardwareMask()[1] | (1L<<24) | (0x00ffffff&gtid);
        }
        else {
            localData.formatedWords[localData.numFormatedWords++] = 
                GetHardwareMask()[1] | 2;
            localData.formatedWords[localData.numFormatedWords++] = 
                (1L<<24) | (0x00ffffff&gtid);
        }
        if(GetDeviceSpecificData()[0]&kShipEvt1ClkMask){
            //read the time
            result    = VMERead(baseAddress + kReadUpperTrigger1TimeReg,
                                0x29,
                                sizeof(high_word),
                                high_word); //short access, the adc Value
            if (result != sizeof(high_word)) {
                LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Upper Trig1",baseAddress);
                dataIndex = savedIndex; //dump the event back to the last marker
                return false; 
            }
            result    = VMERead(baseAddress + kReadLowerTrigger1TimeReg,
                                0x29,
                                sizeof(low_word),
                                low_word); //short access, the adc Value
            if (result != sizeof(low_word)) {
                LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Low Trig1",baseAddress);
                dataIndex = savedIndex; //dump the event back to the last marker
                return false; 
            }
            //clock data
            localData.formatedWords[localData.numFormatedWords++] = GetHardwareMask()[0] | 3;
            localData.formatedWords[localData.numFormatedWords++] = (1L<<24) | (high_word & 0x00ffffff);
            localData.formatedWords[localData.numFormatedWords++] = low_word;
        }
        

        //------labeled data that can be passed back to the mac---- 
        // "GTID"            gtid
        // "MSAMEvent"        isMSAM event
        // "MSAMPrescale"    MSAM prescale value
        //--------------------
        strcpy(localData.labeledData[localData.numberLabeledDataWords].label,"GTID");
        localData.labeledData[localData.numberLabeledDataWords].data = gtid;
        localData.numberLabeledDataWords++;
         
        if(!gtBitSet){
            //the gt bit was NOT set, ditch the event and reset
            ResetTR32(kTrigger1GTEventReset);
        }
 
        //MSAM is a special bit that is set if a trigger 1 has occurred within 15 microseconds after a trigger2
        if(GetDeviceSpecificData()[0] & kUseMSam){
            unsigned short reReadStatusReg = statusReg;
            int i;
            for(i=0;i<15;i++){
                if((reReadStatusReg & kValidTrigger1GTClockMask) && !(reReadStatusReg & kMSamEventMask)){
                    usleep(1);
                    result    = VMERead(baseAddress + kStatusRegOffset,
                                        0x29,
                                        sizeof(reReadStatusReg),
                                        reReadStatusReg); //short access, the adc Value
  
                    if (result != sizeof(reReadStatusReg)) {
                        LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Status",baseAddress);
                        return false;  
                    }
                    
                    if(reReadStatusReg & kMSamEventMask) break;
                }
                else break;
                usleep(1);
            }                
  
            strcpy(localData.labeledData[localData.numberLabeledDataWords].label,"MSAMEvent");
            localData.labeledData[localData.numberLabeledDataWords].data = (reReadStatusReg & kMSamEventMask)!=0;
            localData.numberLabeledDataWords++;

            strcpy(localData.labeledData[localData.numberLabeledDataWords].label,"MSAMPrescale");
            localData.labeledData[localData.numberLabeledDataWords].data = GetDeviceSpecificData()[1];
            localData.numberLabeledDataWords++;
            
            result = VMEWrite(baseAddress + kMSamEventReset,
                              0x29,
                              sizeof(sValue),
                              sValue); //short access, the adc Value
            if (result != sizeof(sValue)) {
                LogErrorForCard(GetSlot(),"Wr Err: TR32 0x%04x SAM Reset",baseAddress);
            }
        }
        
        //read out the children for event 1
        leaf_index = GetNextTriggerIndex()[0];
        while(leaf_index >= 0) {
            //if the next object is NOT a lam object, then we'll just put the formated data into the data stream
            // FixME
            ORVCard* card = peek_at_card(leaf_index);
            if (!card) {
                // means we couldn't find the card.
                // Shouldn't happen but...
                LogErrorForCard(GetSlot(),"Readout Err: Card at index %i not found",leaf_index);
                break;
            }
            if(card->GetHWTypeID() != kSBCLAM){
                for(uint32_t j=0;j<localData.numFormatedWords;j++){
                    data[dataIndex++] = localData.formatedWords[j];
                }
            }
            leaf_index = readout_card(leaf_index,&localData);
        }
    }
    
    if(!(statusReg & kTrigger2EventMask)){
        //if the trigger 2 is NOT set at this point check the status word again in case an event 
        //happened while we were reading out the event 1.
        result    = VMERead(baseAddress + kStatusRegOffset,
                            0x29,
                            sizeof(statusReg),
                            statusReg); //short access, the adc Value
        if (result != sizeof(statusReg)) {
            LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Status",baseAddress);
            return false;   
        }
    }
    
    //--------------------------------------------------------------------------------------------------------
    //Handle Trigger #2
    //Note for debugging. EVERY variable in the following block should have a '2' in it if is referring to
    //an event, gtid, or placeholder.
     //--------------------------------------------------------------------------------------------------------
   if(statusReg & kTrigger2EventMask){
        //event mask 2 is special and requires that the children's hw be readout BEFORE the GTID
        //word is read. Reading the GTID clears the event 2 bit in the status word and can cause
        //a lockout of the hw.
        gtidShortForm =  GetHardwareMask()[2] & 0x80000000L;

        if(GetDeviceSpecificData()[0] & kUseSoftwareGtid){
             //must latch the clock if in soft gtid mode
            lValue = 0;
            result = VMEWrite(baseAddress + kTestLatchTrigger2Time,
                              0x29,
                              sizeof(lValue),
                              lValue); //short access, the adc Value
            if (result != sizeof(lValue)) {
                LogErrorForCard(GetSlot(),"Wr Err: TR32 0x%04x Latch Trig2",baseAddress);
                return false;    
            }
            //soft gtid, so set the bit ourselves
            statusReg |= kValidTrigger2GTClockMask;
        }
        else if(!(statusReg & kValidTrigger2GTClockMask)){
            //should have been a gt, maybe we're too fast. try some more--but not too many times.
            int k;
            for(k=0;k<5;k++){
                result    = VMERead(baseAddress + kStatusRegOffset,
                                    0x29,
                                    sizeof(statusReg),
                                    statusReg); //short access, the adc Value
                if (result != sizeof(statusReg)) {
                    LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Status",baseAddress);
                    return false;     
                }
                if(statusReg & kValidTrigger2GTClockMask)break;
                else  usleep(1);
            }
        }
        
        if(statusReg & kValidTrigger2GTClockMask){
            savedIndex = dataIndex;
            
            placeHolderIndex = dataIndex; //reserve space for the gtid and save the pointer so we can replace it later
                                          //load a dummy gtid--we'll replace it later if we can.
            if(gtidShortForm){
                data[dataIndex++] = GetHardwareMask()[2] | (1L<<25) | 0x00ffffff;
            }
            else {
                data[dataIndex++] = GetHardwareMask()[2] | 2;
                data[dataIndex++] = (1L<<25) | 0x00ffffff;
            }
            if(GetDeviceSpecificData()[0] & kShipEvt2ClkMask){
                //load a dummy time--we'll replace it later if we can.
                data[dataIndex++] = GetHardwareMask()[0] | 3;
                data[dataIndex++] = (1L<<25);
                data[dataIndex++] = 0;
            }        
            
            //read out the event2 children
            leaf_index = GetNextTriggerIndex()[1];
            while(leaf_index >= 0)    leaf_index = readout_card(leaf_index,&localData);
            
            if(!(GetDeviceSpecificData()[0] & kUseSoftwareGtid)){
                result    = VMERead(baseAddress + kReadTrigger2GTID,
                                    0x29,
                                    sizeof(gtid),
                                    gtid); //short access, the adc Value
                if (result != sizeof(gtid)){
                    LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Trig2 GTID",baseAddress);
                    dataIndex = savedIndex; //dump the event back to the last marker
                    return false; 
                }
            }
            else {
                result    = VMERead(baseAddress + kReadAuxGTIDReg,
                                    0x29,
                                    sizeof(gtid),
                                    gtid); //short access, the adc Value
                if (result != sizeof(gtid)) {
                    LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x AuxGTID",baseAddress);
                    return false; 
                }
                ResetTR32(kTrigger2GTEventReset);
            }
            
            if(savedIndex != dataIndex){   //check if data was taken and is waiting in the que
                                           //OK there was some data so pack the gtid.
                if(gtidShortForm){
                    data[placeHolderIndex++] = GetHardwareMask()[2] | (1L<<25) | (0x00ffffff&gtid);
                }
                else {
                    data[placeHolderIndex++] = GetHardwareMask()[2] | 2;
                    data[placeHolderIndex++] = (1L<<25) | (0x00ffffff&gtid);
                }
                if((GetDeviceSpecificData()[0]&kShipEvt2ClkMask)!=0){
                    
                    //get the time
                    result    = VMERead(baseAddress + kReadUpperTrigger2TimeReg,
                                        0x29,
                                        sizeof(high_word),
                                        high_word); //short access, the adc Value
                    if (result != sizeof(high_word)) {
                        LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x Upper Trig2",baseAddress);
                        dataIndex = savedIndex; //dump the event back to the last marker
                        return false; 
                    }
                
                    result    = VMERead(baseAddress + kReadLowerTrigger2TimeReg,
                                        0x29,
                                        sizeof(low_word),
                                        low_word); //short access, the adc Value
                    if (result != sizeof(low_word)) {
                        LogErrorForCard(GetSlot(),"Rd Err: TR32 0x%04x LowerTrig2",baseAddress);
                        dataIndex = savedIndex; //dump the event back to the last marker
                        return false; 
                    }
                    
                    data[placeHolderIndex++] = GetHardwareMask()[0] | 3;
                    data[placeHolderIndex++] = (1L<<25) | (high_word & 0x00ffffff);
                    data[placeHolderIndex++] = low_word;
                }
            }
        }
    }
    
    return true; 
}

void ORVMETrigger32Readout::ResetTR32(uint32_t offset)
{
    uint16_t value = 1;
    int32_t result = VMEWrite(GetBaseAddress()+offset,
                              0x29,
                              sizeof(value),
                              value);
    if(result != sizeof(value)){
        LogErrorForCard(GetSlot(),"Wr Err: TR32 0x%04x Reset",GetBaseAddress());
    }
}
