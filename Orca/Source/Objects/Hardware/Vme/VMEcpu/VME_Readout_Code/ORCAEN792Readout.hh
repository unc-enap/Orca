#ifndef _ORCAEN792Readout_hh_
#define _ORCAEN792Readout_hh_
#include "ORCAENReadout.hh"
#include <iostream>

class ORCAEN792Readout : public ORCAENReadout
{
  public:
    ORCAEN792Readout(SBC_card_info* ci) : ORCAENReadout(ci) {}
    virtual ~ORCAEN792Readout() {}
    virtual bool Readout(SBC_LAM_Data*);
protected:
	virtual void FlushDataBuffer();
};

#endif /* _ORCAENReadout_hh_*/
