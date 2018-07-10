#ifndef _ORVCard_hh_
#define _ORVCard_hh_

extern "C" {
#include "SBC_Config.h"
#include "SBC_Cmds.h"
#include "SBC_Readout.h"
}
#include <cstring>
extern int32_t  dataIndex;
extern int32_t* data;
class ORVCard 
{
   public:
		ORVCard(SBC_card_info* ci)  {  memcpy(&fCardInfo, ci, sizeof(fCardInfo)); }
		virtual ~ORVCard() {} 

		virtual bool Start()					{ return true; }
		virtual bool Readout(SBC_LAM_Data*) = 0;  
		virtual bool Pause()					{ return true; }
		virtual bool Resume()					{ return true; }
		virtual bool Stop()						{ return true; }
		virtual int32_t ReadoutAndGetNextIndex(SBC_LAM_Data*);  

		inline uint32_t GetSlot()				 { return fCardInfo.slot; }
		inline uint32_t GetCrate()				 { return fCardInfo.crate; }
		inline uint32_t GetBaseAddress()		 { return fCardInfo.base_add; }
		inline uint32_t GetAddressModifier()	 { return fCardInfo.add_mod; }
		inline uint32_t* GetHardwareMask()		 { return fCardInfo.hw_mask; }
		inline uint32_t* GetDeviceSpecificData() { return fCardInfo.deviceSpecificData; }
		inline int32_t GetNextCardIndex()		 { return fCardInfo.next_Card_Index; }
		inline uint32_t* GetNextTriggerIndex()	 { return fCardInfo.next_Trigger_Index; }
		inline uint32_t GetHWTypeID()			 { return fCardInfo.hw_type_id; }

   protected:
      SBC_card_info fCardInfo;
 
   private:
       ORVCard() {}
       ORVCard(const ORVCard& other) {}


};
#endif /* _ORVCard_hh_ */
