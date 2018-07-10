#ifndef _ORCAENReadout_hh_
#define _ORCAENReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCAENReadout : public ORVVmeCard
{
  public:
    ORCAENReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCAENReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);

    enum ORCAENConsts {
        kCaen_Header               = 0x2,
        kCaen_ValidDatum           = 0x0,
        kCaen_EndOfBlock           = 0x4,
        kCaen_NotValidDatum        = 0x6,   
        kCaen_DataWordTypeMask     = 0x07000000,
        kCaen_DataWordTypeShift    = 24,
        kCaen_DataChannelCountMask = 0x00003f00,
        kCaen_DataChannelCoutShift = 8
    };
  protected:
    void Flush_CAEN_FIFO();
};

#endif /* _ORCAENReadout_hh_*/
