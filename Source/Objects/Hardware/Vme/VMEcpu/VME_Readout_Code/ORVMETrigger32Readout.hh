#ifndef _ORVMETrigger32Readout_hh_
#define _ORVMETrigger32Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORVMETrigger32Readout : public ORVVmeCard
{
  public:
    ORVMETrigger32Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORVMETrigger32Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);

    enum ORVMETrigger32Consts {
             kTrigger1EventMask                = 1L << 0,
             kValidTrigger1GTClockMask         = 1L << 1,
             kTrigger2EventMask                = 1L << 2,
             kValidTrigger2GTClockMask         = 1L << 3,
          // kCountErrorMask                   = 1L << 4,
          // kTimeClockCounterEnabledMask      = 1L << 5,
          // kTrigger2EventInputEnabledMask    = 1L << 6,
          // kBusyOutputEnabledMask            = 1L << 7,
          // kTrigger1GTOutputOREnabledMask    = 1L << 8,
          // kTrigger2GTOutputOREnabledMask    = 1L << 9,
             kMSamEventMask                    = 1L << 10,
    
             kTrigger2GTEventReset        = 0x0A,     //resets trigger2 adc event 
                                                      // and trigger2 GT clock status bits
             kTrigger1GTEventReset        = 0x0C,     //reset muix event and valid trigger1 
                                                      //GT clock status bits
             kTestLatchTrigger2Time       = 0x12,     //latches the Time Clock into trigger2 
                                                      //Timer register
             kTestLatchTrigger1Time       = 0x16,     //latches the Time Clock into trigger1 
                                                      //Timer register
             kStatusRegOffset             = 0x14, 
             kReadTrigger2GTID            = 0x18,    //read the trigger2 GTID
             kReadTrigger1GTID            = 0x1C,    //read the trigger1 GTID
             kReadLowerTrigger2TimeReg    = 0x20,     
             kMSamEventReset              = 0x22,    //reset the M-SAM status bit.
             kReadUpperTrigger2TimeReg    = 0x24,     
             kReadLowerTrigger1TimeReg    = 0x28,        
             kReadUpperTrigger1TimeReg    = 0x2C,        
             kReadAuxGTIDReg              = 0x3C,        
          
             kShipEvt1ClkMask    = 1L<<0,
             kShipEvt2ClkMask    = 1L<<1,
             kUseSoftwareGtid    = 1L<<2,
             kUseMSam            = 1L<<3
    };

  protected:
    void ResetTR32(uint32_t offset);
};

#endif /* _ORVMETrigger32Readout_hh_*/
