#include "ORVVmeCard.hh"
#include <time.h>

// This is a *subset* of the registers that seem useful for readout tasks.
//
//#define kSIS3305ControlStatus                       0x0	  /* read/write; D32 */
//#define kSIS3305ModID                               0x4	  /* read only; D32 */
//#define kSIS3305IrqConfig                           0x8      /* read/write; D32 */
//#define kSIS3305IrqControl                          0xC      /* read/write; D32 */
//
//#define kSIS3305ADCSerialInterfaceReg               0x74    /* read/write D32 */
//


//
//
//
//

//
//#define kSIS3305Space2ADCDataFIFOCh14      0x800000
//#define kSIS3305Space2ADCDataFIFOCh58      0xC00000



class ORSIS3305Card: public ORVVmeCard
{
public:
	ORSIS3305Card(SBC_card_info* card_info);
	virtual ~ORSIS3305Card() {}
	
	virtual bool Start();
	virtual bool Readout(SBC_LAM_Data* /* lam_data*/);  
	virtual bool Resume();
	virtual bool Stop();
	
	enum EORSIS3305Consts {
		kNumberOfChannels		 = 8,
		kOrcaHeaderInLongs		 = 3,
		kSISHeaderSizeInLongsNoWrap = 4,
		kSISHeaderSizeInLongsWrap	 = 16,
		kTrailerSizeInLongs		 = 0,
        
        kSIS3305AcquisitionControl          = 0x10,      /* read/write; D32 */
        kSIS3305DataTransferADC14CtrlReg    = 0xC0,    /* read/write D32 */
        kSIS3305DataTransferADC58CtrlReg    = 0xC4,    /* read/write D32 */
        kSIS3305DataTransferADC14StatusReg  = 0xC8,    /* read D32 */
        kSIS3305DataTransferADC58StatusReg  = 0xCC,    /* read D32 */
        
        kSIS3305KeyReset                    = 0x400,	/* write only; D32 */
        kSIS3305KeyArmSampleLogic           = 0x410,   /* write only; D32 */
        kSIS3305KeyDisarmSampleLogic        = 0x414,   /* write only, D32 */
        kSIS3305KeyTrigger                  = 0x418,	/* write only; D32 */
        kSIS3305KeyEnableSampleLogic        = 0x41C,   /* write only; D32 */
        kSIS3305KeySetVeto                  = 0x420,   /* write only; D32 */
        kSIS3305KeyClrVeto                  = 0x424,	/* write only; D32 */
        kSIS3305ADCSynchPulse               = 0x430,   /* write only D32 */
        kSIS3305ADCFpgaReset                = 0x434,   /* write only D32 */
        kSIS3305ADCExternalTriggerOutPulse  = 0x43C,   /* write only D32 */
        
        kSIS3305ActualSampleAddressADC14    = 0x2044,
        kSIS3305ActualSampleAddressADC58    = 0x3044,
        
        kSIS3305EndAddressThresholdADC14    = 0x201C,
        kSIS3305EndAddressThresholdADC58    = 0x301C,

        kSIS3305Space1ADCDataFIFOCh14       = 0x8000,
        kSIS3305Space1ADCDataFIFOCh58       = 0xC000,
        
        //// Sample Memory Start Address Registers
        kSIS3305SampleStartAddressADC14     = 0x2004,
        kSIS3305SampleStartAddressADC58     = 0x3004,
        //
        //// Sample/Extended Block Length Registers
        kSIS3305SampleLengthADC14           = 0x2008,
        kSIS3305SampleLengthADC58           = 0x3008,
        //
        ////vDirect Memory Stop Pretrigger Block Length Registers
        kSIS3305SamplePretriggerLengthADC14 = 0x200C,
        kSIS3305SamplePretriggerLengthADC58 = 0x300C,
        //
        //// Direct Memory Max Nof Events Registers
        kSIS3305MaxNofEventsADC14           = 0x2018,
        kSIS3305MaxNofEventsADC58           = 0x3018
    };
    

	
protected:
    
//    virtual uint32_t*   dataRecord[2]; // 2 groups to read out
    uint32_t dataRecordLength[2];   // length without orca header (amount to read)
    uint32_t totalRecordLength[2];  // space of record on disk (with orca and SIS header)
    uint32_t orcaHeaderLength;

    
	virtual inline uint32_t GetAcquisitionControl()		{ return 0x10; }
	virtual inline uint32_t GetADCMemoryPageRegister()	{ return 0x34; }
	virtual inline uint32_t GetDataWidth()				{ return 0x4; }
	virtual inline  size_t  GetNumberOfChannels()		{ return kNumberOfChannels; }
	
    // methods that access the card info struct
    virtual uint32_t longsInSample(uint8_t);
    virtual uint32_t GetChannelMode(uint8_t);
    virtual uint32_t GetDigitizationRate(uint8_t);
    virtual uint32_t GetEventSavingMode(uint8_t);

    // methods for reading/writing to HW
    virtual bool writeDataTransferControlReg(uint8_t, uint8_t, uint32_t);
    virtual uint32_t readActualSampleAddress(uint8_t);
    
    // methods that look things up
    virtual uint32_t GetFIFOAddressOfGroup(uint8_t group);
    
    // other class methods
	virtual bool IsEvent();
//	virtual void ReadOutChannel(size_t channel);
//	virtual bool resetSampleLogic();
    virtual bool armSampleLogic();
    virtual bool enableSampleLogic();
    virtual bool disarmSampleLogic();
    
    // handy class variables
    
    uint32_t dmaBuffer[0x200000]; //2M Longs (8MB)
    //	bool        fPulseMode;
    //	bool        fProcessPulse;
    //	bool        fWaitingForSomeChannels;
    //	uint32_t fChannelsToReadMask;
    
    
};
