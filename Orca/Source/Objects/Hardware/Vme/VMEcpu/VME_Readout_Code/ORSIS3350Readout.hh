#ifndef _ORSIS3350Readout_hh_
#define _ORSIS3350Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORSIS3350Readout : public ORVVmeCard
{
  public:
    ORSIS3350Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORSIS3350Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);

    enum ORSIS3350Consts {
        kNumberOfChannels = 4
    };

    enum ORSIS3350OperationModes {
        kOperationRingBufferAsync = 0,
        kOperationDirectMemoryGateAsync = 2,
        kOperationDirectMemoryStop = 4
    };
  protected:
    static void ReOrderOneSIS3350Event(int32_t* inDataPtr, 
                                       uint32_t dataLength, 
                                       uint32_t wrapLength);
	static uint32_t adcOffsets[kNumberOfChannels];
	static uint32_t channelOffsets[kNumberOfChannels];
	static uint32_t endOfEventOffset[kNumberOfChannels];
};

#endif /* _ORSIS3350Readout_hh_*/
