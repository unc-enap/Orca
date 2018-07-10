#ifndef _ORDataGenReadout_hh_
#define _ORDataGenReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORDataGenReadout : public ORVVmeCard
{
  public:
    ORDataGenReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORDataGenReadout() {} 
	virtual bool Start();
    virtual bool Readout(SBC_LAM_Data*);
	
	uint32_t nextBurst;
	uint32_t nextBigBurst;
	
};

#endif /* _ORDataGenReadout_hh_*/
