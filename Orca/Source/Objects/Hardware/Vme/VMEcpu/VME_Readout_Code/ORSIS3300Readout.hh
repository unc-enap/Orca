#ifndef _ORSIS3300Readout_hh_
#define _ORSIS3300Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORSIS3300Readout : public ORVVmeCard
{
  public:
    ORSIS3300Readout(SBC_card_info* ci);
    virtual ~ORSIS3300Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);

    enum EORSIS3300Consts {
        kSISBank1ClockStatus   = 0x00000001,
        kSISBank2ClockStatus   = 0x00000002,
        kSISBank1BusyStatus	   = 0x00100000,
        kSISBank2BusyStatus	   = 0x00400000,
        kTriggerEvent1DirOffset= 0x101000,
        kTriggerEvent2DirOffset= 0x102000,
        kTriggerTime1Offset	   = 0x1000,
        kTriggerTime2Offset	   = 0x2000,
        kSISAcqReg			   = 0x10,		// [] Acquistion Reg
        kStartSampling		   = 0x30,		// [] Start Sampling
        kClearBank1FullFlag	   = 0x48,		// [] Clear Bank 1 Full Flag
        kClearBank2FullFlag	   = 0x4C,		// [] Clear Bank 2 Full Flag
        kSISSampleBank1		   = 0x0001L,
        kSISSampleBank2		   = 0x0002L,
    };

  protected:
    static uint32_t eventCountOffset[4][2];
    static uint32_t bankMemory[4][2];
    int32_t fCurrentBank; 
};

#endif /* _ORSIS3300Readout_hh_*/
