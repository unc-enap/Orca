#ifndef _ORPollingTimeStampReadout_hh_
#define _ORPollingTimeStampReadout_hh_
#include "ORPollingTimeStampReadout.hh"
#include "ORVVmeCard.hh"

class ORPollingTimeStampReadout : public ORVVmeCard
{
  public:
    ORPollingTimeStampReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORPollingTimeStampReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif //_ORPollingTimeStampReadout_hh_
