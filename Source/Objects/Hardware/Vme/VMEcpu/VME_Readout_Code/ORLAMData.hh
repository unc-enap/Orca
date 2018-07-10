#ifndef _ORLAMData_hh_
#define _ORLAMData_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORLAMData : public ORVVmeCard
{
  public:
    ORLAMData(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORLAMData() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORLAMData_hh_*/
