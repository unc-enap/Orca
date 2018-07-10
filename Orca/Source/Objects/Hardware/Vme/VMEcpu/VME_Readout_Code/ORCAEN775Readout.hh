#ifndef _ORCAEN775Readout_hh_
#define _ORCAEN775Readout_hh_
#include "ORCAENReadout.hh"
#include <iostream>

class ORCAEN775Readout : public ORCAENReadout
{
  public:
    ORCAEN775Readout(SBC_card_info* ci) : ORCAENReadout(ci) {}
    virtual ~ORCAEN775Readout() {}
    virtual bool Readout(SBC_LAM_Data*);
    virtual void FlushDataBuffer();
};

#endif /* _ORCAENReadout_hh_*/
