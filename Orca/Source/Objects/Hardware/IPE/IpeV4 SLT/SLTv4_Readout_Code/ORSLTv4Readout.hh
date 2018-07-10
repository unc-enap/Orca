#ifndef _ORSLTv4Readout_hh_
#define _ORSLTv4Readout_hh_
#include "ORVCard.hh"
#include <iostream>


/** For each IPE4 crate in the Orca configuration one instance of ORSLTv4Readout is constructed.
  *
  * Short firmware history:
  * - Project:1 Doc:0x214 Implementation:0xc063 - current version 2010 - 2011-06-16
  *
  * NOTE: UPDATE 'kCodeVersion': After all major changes in HW_Readout.cc, FLTv4Readout.cc, FLTv4Readout.hh, SLTv4Readout.cc, SLTv4Readout.hh
  * 'kCodeVersion' in HW_Readout.cc should be increased!
  *
  *
  */ //-tb-
class ORSLTv4Readout : public ORVCard
{
  public:
    ORSLTv4Readout(SBC_card_info* ci) : ORVCard(ci) {} 
    virtual ~ORSLTv4Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORSLTv4Readout_hh_*/
