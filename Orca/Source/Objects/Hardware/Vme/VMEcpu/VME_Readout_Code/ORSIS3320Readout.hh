#include "ORVVmeCard.hh"

class ORSIS3320Readout: public ORVVmeCard
{
public:
	ORSIS3320Readout(SBC_card_info* card_info);
//	virtual ~ORSIS3320Readout() {}
    ~ORSIS3320Readout(); // now non-virtual because we need to free allocated dataBuffer upon cleanup
	
	virtual bool Readout(SBC_LAM_Data* /* lam_data*/);  
	
	enum EORSIS3320Consts {
		kNumberOfChannels		 = 8,
        kDisarmAndArmBank1       = 0x0420,
        kDisarmAndArmBank2       = 0x0424,
        kAcquisitionControlReg	 = 0x10,
        kEndAddressThresholdFlag = 0x80000
	};
    
    // perhaps some care should be taken to make accesses to this quick like a puma
    // make it a static member? does that help?
    // where in memory does it wind up when declared as it is?
    static const uint32_t SIS3320_previousBankEndSampleAddress[ 8 ];
    

	
	
protected:
	virtual uint32_t GetADCBufferRegisterOffset(size_t channel);
	
	virtual inline uint32_t GetAcquisitionControl()		{ return 0x10; }
	virtual inline uint32_t GetDataWidth()				{ return 0x4; }
	virtual uint32_t GetNextBankSampleRegisterOffset(size_t channel);
    virtual void armBank1();
    virtual void armBank2();
	
	bool	 fBankOneArmed;
    
    uint32_t* dataBuffer; // if allocated, will be 8 MB array for storing large amounts of data from 3320
};
