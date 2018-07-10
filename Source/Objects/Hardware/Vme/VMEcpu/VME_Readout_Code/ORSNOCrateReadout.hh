#ifndef _ORSNOCrateReadout_hh_
#define _ORSNOCrateReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORSNOCrateReadout : public ORVVmeCard
{
  public:
    ORSNOCrateReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORSNOCrateReadout() {} 
	virtual bool Start();
	virtual bool Readout(SBC_LAM_Data*);
	virtual bool Stop();	
};

#endif /* _ORSNOCrateReadout_hh_*/
