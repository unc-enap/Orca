#include "OREdelweissFLTv4Readout.hh"
#include "EdelweissSLTv4_HW_Definitions.h"

//for including ipe4tbtools.h/.cpp:
#include "ipe4structure.h"//for code_acqui_EDW_BB2, code_synchro_100000
//#include "HW_Readout.h"//for pbus
class Pbus;
//class hw4::SubrackKatrin;
extern Pbus *pbus;              //for register access with fdhwlib
//Pbus *pbus=0;              //for register access with fdhwlib
#include "ipe4tbtools.h"
extern int (*sendChargeBBStatusFunctionPtr)(uint32_t prog_status,int numFifo); //defined in HW_Readout.cpp through #include "ipe4tbtools.cpp"
//#include "ipe4tbtools.cpp"

#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
    #include <sys/time.h> // for gettimeofday on MAC OSX -tb-
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif



//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-

//moved to ipe4tbtools -tb-
#if 0
    //SLT registers
	static const uint32_t SLTControlReg     = 0xa80000 >> 2;
	static const uint32_t SLTStatusReg      = 0xa80004 >> 2;
	static const uint32_t SLTCommandReg     = 0xa80008 >> 2;
	static const uint32_t SLTVersionReg     = 0xa80020 >> 2;

	static const uint32_t SLTPixbusPErrorReg     = 0xa80024 >> 2;
	static const uint32_t SLTPixbusEnableReg     = 0xa80028 >> 2;
	static const uint32_t SLTBBOpenedReg         = 0xa80034 >> 2;

	
	static const uint32_t SLTSemaphoreReg   = 0xb00000 >> 2;
	
	static const uint32_t CmdFIFOReg        = 0xb00004 >> 2;
	static const uint32_t CmdFIFOStatusReg  = 0xb00008 >> 2;
	static const uint32_t OperaStatusReg0    = 0xb0000c >> 2;
	static const uint32_t OperaStatusReg1    = 0xb00010 >> 2;
	static const uint32_t OperaStatusReg2    = 0xb00014 >> 2;
	
	static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;
	static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;
	static const uint32_t FIFO0Addr         = 0xd00000 >> 2;
	static const uint32_t BB0PAEOffsetReg   = 0xe00008 >> 2;
	static const uint32_t BB0PAFOffsetReg   = 0xe0000c >> 2;
	static const uint32_t BB0csrReg         = 0xe00010 >> 2;

	static const uint32_t SLTTimeLowReg     = 0xb00018 >> 2;
	static const uint32_t SLTTimeHighReg    = 0xb0001c >> 2;


	
inline uint32_t FIFOStatusReg(int numFIFO){
    return FIFO0StatusReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

inline uint32_t FIFOModeReg(int numFIFO){
    return FIFO0ModeReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

inline uint32_t FIFOAddr(int numFIFO){
    return FIFO0Addr | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

inline uint32_t PAEOffsetReg(int numFIFO){
    return BB0PAEOffsetReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

inline uint32_t PAFOffsetReg(int numFIFO){
    return BB0PAFOffsetReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

inline uint32_t BBcsrReg(int numFIFO){
    return BB0csrReg | ((numFIFO & 0xf) <<14);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

    //FLT registers
	static const uint32_t FLTStatusRegBase      = 0x000000 >> 2;
	static const uint32_t FLTControlRegBase     = 0x000004 >> 2;
	static const uint32_t FLTCommandRegBase     = 0x000008 >> 2;
	static const uint32_t FLTVersionRegBase     = 0x00000c >> 2;
	
	static const uint32_t FLTFiberOutMaskRegBase  = 0x000018 >> 2;
    
	static const uint32_t FLTFiberSet_1RegBase  = 0x000024 >> 2;
	static const uint32_t FLTFiberSet_2RegBase  = 0x000028 >> 2;
	static const uint32_t FLTStreamMask_1RegBase  = 0x00002c >> 2;
	static const uint32_t FLTStreamMask_2RegBase  = 0x000030 >> 2;
	static const uint32_t FLTTriggerMask_1RegBase  = 0x000034 >> 2;
	static const uint32_t FLTTriggerMask_2RegBase  = 0x000038 >> 2;

	static const uint32_t FLTAccessTestRegBase     = 0x000040 >> 2;
	
	static const uint32_t FLTTotalTriggerNRegBase  = 0x000084 >> 2;

	static const uint32_t FLTBBStatusRegBase    = 0x001400 >> 2;

	static const uint32_t FLTRAMDataRegBase     = 0x003000 >> 2;
	
// 
// NOTE: numFLT from 1...20  !!!!!!!!!!!!
//
// (NOT from 0 ... 19!!!)
//
// channels from 0 to 5!!!

	//TODO: 0x3f or 0x1f?????????????

inline uint32_t FLTStatusReg(int numFLT){
    return FLTStatusRegBase | ((numFLT & 0x3f) <<17);  //PCI adress would be <<16, but we use Pbus adress -tb-
}

inline uint32_t FLTControlReg(int numFLT){
    return FLTControlRegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTCommandReg(int numFLT){
    return FLTCommandRegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTVersionReg(int numFLT){
    return FLTVersionRegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTFiberOutMaskReg(int numFLT){
    return FLTFiberOutMaskRegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTFiberSet_1Reg(int numFLT){
    return FLTFiberSet_1RegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTFiberSet_2Reg(int numFLT){
    return FLTFiberSet_2RegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTStreamMask_1Reg(int numFLT){
    return FLTStreamMask_1RegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTStreamMask_2Reg(int numFLT){
    return FLTStreamMask_2RegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTTriggerMask_1Reg(int numFLT){
    return FLTTriggerMask_1RegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTTriggerMask_2Reg(int numFLT){
    return FLTTriggerMask_2RegBase | ((numFLT & 0x3f) <<17);  
}

inline uint32_t FLTAccessTestReg(int numFLT){
    return FLTAccessTestRegBase | ((numFLT & 0x3f) <<17); 
}

inline uint32_t FLTBBStatusReg(int numFLT, int numChan){
    return FLTBBStatusRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
}

inline uint32_t FLTTotalTriggerNReg(int numFLT){
    return FLTTotalTriggerNRegBase | ((numFLT & 0x3f) <<17);  
}


inline uint32_t FLTRAMDataReg(int numFLT, int numChan){
    return FLTRAMDataRegBase | ((numFLT & 0x3f) <<17) | ((numChan & 0x1f) <<12); 
}


#endif
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-
//TODO: move to HW_Readout.cc -tb-





//init static members and globals
uint32_t histoShipSumHistogram = 0;





#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------

//extern hw4::SubrackKatrin* srack; 
extern Pbus* pbus; 


bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{

	//static data: buffer for data coming in from the hardware
#define kNumV4FLTs 20
#define kNumV4FLTChannels 24
#define kNumV4FLTADCPageSize16 2048
#define kNumV4FLTADCPageSize32 1024
	static uint32_t adctrace32[kNumV4FLTs][kNumV4FLTChannels][kNumV4FLTADCPageSize32];//shall I use a 4th index for the page number? -tb-
	//if sizeof(int32_t unsigned int) != sizeof(uint32_t) we will come into troubles (64-bit-machines?) ... -tb-
	static uint32_t FIFO1[kNumV4FLTs];
	static uint32_t FIFO2[kNumV4FLTs];
	static uint32_t FIFO3[kNumV4FLTs][kNumV4FLTChannels];
	static uint32_t FIFO4[kNumV4FLTs];
	static uint32_t FltStatusReg[kNumV4FLTs];
	static uint32_t debugbuffer[kNumV4FLTs][kNumV4FLTChannels];//used for debugging -tb-


	static uint32_t isPresentFLT[kNumV4FLTs];


    //this data must be constant during a run
    static uint32_t histoBinWidth = 0;
    static uint32_t histoEnergyOffset = 0;
    static uint32_t histoRefreshTime = 0;
    
    //
    uint32_t dataId     = GetHardwareMask()[0];//this is energy record
    uint32_t waveformId = GetHardwareMask()[1];
    uint32_t histogramId = GetHardwareMask()[2];
    uint32_t energyTraceId = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //GetSlot() is in fact stationNumber, which goes from 1 to 20 (slots go from 0-9, 11-20)
    uint32_t crate      = GetCrate();
    
	
//TODO: most of this is obsolete for Edelweiss -tb-            <----------------- !!!
    uint32_t postTriggerTime = GetDeviceSpecificData()[0];
    uint32_t eventType  = GetDeviceSpecificData()[1];
    uint32_t fltModeFlags = GetDeviceSpecificData()[2];
    uint32_t runFlags   = GetDeviceSpecificData()[3];//this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:
    uint32_t triggerEnabledMask = GetDeviceSpecificData()[4];
    uint32_t daqRunMode = GetDeviceSpecificData()[5];
    uint32_t filterIndex = GetDeviceSpecificData()[6];
    uint32_t versionCFPGA = GetDeviceSpecificData()[7];
    uint32_t versionFPGA8 = GetDeviceSpecificData()[8];
    uint32_t filterShapingLength = GetDeviceSpecificData()[9];//TODO: need to change in the code below! -tb- 2011-04-01
    //new for Edelweiss
    uint32_t selectFiberTrig = GetDeviceSpecificData()[10];//...
	
	uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16); // | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;



    if(runFlags & kFirstTimeFlag){// firstTime   
fprintf(stderr,"ORFLTv4Readout::Readout(SBC_LAM_Data* lamData): location %i, GetNextTriggerIndex()[0] %i\n",location,GetNextTriggerIndex()[0]);fflush(stderr);
		//make some plausability checks
		//...
		//  is FLT present?
	    uint32_t val;
	    val = pbus->read(FLTVersionReg(col+1));
	    fprintf(stderr,"FLT %i: version 0x%08x\n",col,val);fflush(stderr);
	    if(val!=0x1f000000 && val!=0xffffffff) isPresentFLT[col]=1;
		else  isPresentFLT[col]=0;
		
		runFlags &= ~(kFirstTimeFlag);
        GetDeviceSpecificData()[3]=runFlags;// runFlags is GetDeviceSpecificData()[3], so this clears the 'first time' flag -tb-
		//TODO: better use a local static variable and init it the first time, as changing GetDeviceSpecificData()[3] could be dangerous -tb-
        //debug: 
		fprintf(stdout,"FLT #%i: first cycle\n",col+1);fflush(stdout);
        //debug: //sleep(1);
		return true;
	}



	//this handles FLT firmware starting from CFPGA-FPGA8 version 0x20010104-0x20010104 (both 2.1.1.4) and newer 2010-11-08  -tb-
	// (mainly from 2.1.1.4 - 2.1.2.1 -tb-)((but both 2.1.1.4 will work, too)
	// new in FPGA config:  FIFO redesign and new 'sync' mode -tb-
	//===================================================================================================================
    if(isPresentFLT[col]){
		
		uint32_t currFlt = col;// only for better readability  -tb-
        
        
        //READOUT MODES (energy, energy+trace, histogram)
        ////////////////////////////////////////////////////
        
        
        // --- TRIGGER EVENT MODE ------------------------------
//DISABLED ---> 2013-08-19 -tb-
return true;
        if(daqRunMode == kIpeFltV4_EventDaqMode){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            uint32_t status         = 0;//pbus->read(FIFOStatusReg(currFlt+1));
            uint32_t totalTriggerN  = pbus->read(FLTTotalTriggerNReg(currFlt+1));
            //uint32_t status         = srack->theFlt[col]->status->read();

            //uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
                //hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                //fifoStatus = eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(totalTriggerN>0){
                    fprintf(stdout,"totalTriggerN for FLT #%i (col %i): %i\n",currFlt+1,col+1,totalTriggerN);fflush(stdout);

					
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = 0;//eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = 0;//eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
					fifoFlags = (status >> 24) & 0xf;
					//(eventFIFOStatus->fullFlag->getCache()			<< 3) |
					//			(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
					//			(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
					//			(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                        uint32_t evsec      = 0;//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = 0;//(f2 >> 2) & 0x1ffffff; // 25 bit
                        //uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = 0;
                        uint32_t sltsubsec;
                        int32_t timediff2slt;
                        int32_t chan=0;
                            for(chan=0;chan<6;chan++){
                                uint32_t f3            = 0;
                                uint32_t pagenr        = 0;
                                uint32_t energy        = 0;
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: page %i\n",col,eventchan,pagenr);fflush(stdout);
                                uint32_t eventFlags=0;//append page, append next page
                                //TODO: REMOVE IT, use FW version or Orca rev. or ... ? see KATRINv4FLT !!!!!      
								//TODO:  uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                                
                                //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger
						//wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                //else: full trigger search (not recommended)
								

                                static uint32_t waveformLength = 2048; 
                                static uint32_t waveformBuffer32[64*1024];
                                uint32_t shipWaveformBuffer32[64*1024];
                                static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                //uint32_t searchTrig,triggerPos = 0xffffffff;
                                //int32_t appendFlagPos = 0;
                                
                                //srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read raw trace
                                uint32_t adccount, trigSlot;
#if 1
                                pbus->readBlock(FLTRAMDataReg(currFlt+1,chan),(uint32_t*)waveformBuffer32,waveformLength);
                                
                                #if 0 //this was a workaround ...
								for(adccount=0; adccount<waveformLength;adccount++){ //kNumV4FLTADCPageSize32 is 1024; waveformLength is 2048
			            //pbus->read(FLTRAMDataReg(currFlt+1,chan)+0);//dummy
					    
                                    //waveformBuffer32[adccount]  = pbus->read(FLTRAMDataReg(currFlt+1,chan)+adccount);
                                    if(adccount<5){fprintf(stdout,"1RAMDataReg for flt #%i, chan %i (location 0x%x,colSlot %i,crate %i):  addr 0x%08x   value:", currFlt+1,chan,location,col,crate ,FLTRAMDataReg(currFlt+1,0)+adccount);
                                        fprintf(stdout,"     0x%08x\n", waveformBuffer32[adccount]);fflush(stdout);
						            }
                                    //shipWaveformBuffer32[adccount]  = (adccount*2)  | ((adccount*2+1)<<16);
								}
                                #endif
#else
								for(adccount=0; adccount<waveformLength;adccount++){ //kNumV4FLTADCPageSize32 is 1024; waveformLength is 2048
								    
                                    waveformBuffer32[adccount]  = pbus->read(FLTRAMDataReg(currFlt+1,chan)+adccount);
                                    if(adccount<10){fprintf(stdout,"2RAMDataReg for flt #%i, chan %i (location 0x%x,colSlot %i,crate %i):  addr 0x%08x   value:", currFlt+1,chan,location,col,crate ,FLTRAMDataReg(currFlt+1,0)+adccount);
                                        fprintf(stdout,"     0x%08x\n", waveformBuffer32[adccount]);fflush(stdout);
						            }
                                    //shipWaveformBuffer32[adccount]  = (adccount*2)  | ((adccount*2+1)<<16);
								}
#endif
							/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
								
								
								
								
                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2);  //waveformLength is 2048, see above
                                data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | ((selectFiberTrig & 0xf)<<12) | ((chan & 0xf)<<8);
                                data[dataIndex++] = 2;//evsec;        //sec
                                data[dataIndex++] = 3;//evsubsec;     //subsec
                                data[dataIndex++] = 0;//chmap;
                                data[dataIndex++] = 0;//(readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = 6;// ((fifoEventID & 0xfff) << 20) | energy;
                                data[dataIndex++] = 0;// ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = 1023;//postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength;i++){//TODO: use memcopy!!!
                                    shipWaveformBuffer16[i] = waveformBuffer32[i] & 0xffff;
                                }
                                uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                for(uint32_t i=0;i<waveformLength32;i++){//TODO: use memcopy!!!
                                    data[dataIndex++] = shipWaveformBuffer32[i];
//                                    data[dataIndex++] = i;
                                }
                                
                            }//for(chan ...
                    usleep(1000);
					pbus->write(FLTCommandReg(currFlt+1),0x10000);//reset  TotalTriggerNReg
                }//if(totalTriggerN>0)...
                //else break;//fifo is empty, leave loop ...
        }
        // --- BAD MODE ------------------------------
        else{
            fprintf(stdout,"ORFLTv4Readout.cc: WARNING: received unknown DAQ mode (%i)!\n",daqRunMode); fflush(stdout);
        }

    }
	
	
    return true;
    
}

#if 1 //Test to prepare single sum histogram readout -tb-
//TODO: using this inhibits stopping a waveform run (?) -tb-
bool ORFLTv4Readout::Stop()
{



//-----------------------------------------
#if 0
	//-tb- a test:
	//fprintf(stdout,"ORFLTv4Readout.cc: This is bool ORFLTv4Readout::Stop() for slot %i (ct is %i)!\n",GetSlot()); fflush(stdout);
    // it seems to me that nobody cares when I return false; -tb-
	
    if( histoShipSumHistogram & kShipSumHistogramFlag ) {
		//fprintf(stdout,"ORFLTv4Readout.cc: Writing out sum histogram\n"); fflush(stdout);
		//ship the sum histograms
		uint32_t histogramId = GetHardwareMask()[2];
		uint32_t crate      = GetCrate();
		uint32_t col        = GetSlot() - 1; //GetSlot() is in fact stationNumber, which goes from 1 to 24 (slots go from 0-9, 11-20)
		uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16);
		uint32_t fltRunMode = GetDeviceSpecificData()[2];
		uint32_t triggerEnabledMask = GetDeviceSpecificData()[4];
		uint32_t daqRunMode = GetDeviceSpecificData()[5];
		//data to ship
		uint32_t chan=0;
		uint32_t readoutSec;
		uint32_t totalLength=kMaxHistoLength;
		uint32_t last=kMaxHistoLength-1,first=0;
		uint32_t fpgaHistogramID;
		uint32_t histoBinWidth = 0;
		uint32_t histoEnergyOffset = 0;
		if(fltRunMode == kIpeFltV4Katrin_Histo_Mode ) {//only in histogram mode ...
			// buffer some data:
			hw4::FltKatrin *currentFlt = srack->theFlt[col];
			//read sec
			readoutSec=currentFlt->secondCounter->read();
			//readoutSec=2303;
			histoBinWidth       = currentFlt->histogramSettings->histEBin->getCache();
			histoEnergyOffset   = currentFlt->histogramSettings->histEMin->getCache();
			//histoBinWidth       = 4;
			//histoEnergyOffset   = 20000;
			// CHANNEL LOOP ----------------
			for(chan=0; chan < kNumChan ; chan++) {//read out histogram
				if( !(triggerEnabledMask & (0x1L << chan)) ) continue; //skip channels with disabled trigger
				katrinV4HistogramDataStruct theEventData;
				theEventData.readoutSec = readoutSec;
				theEventData.refreshTimeSec =  recordingTimeSum[chan];//histoRunTime;   
				
				theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
				theEventData.binSize    = histoBinWidth;        
				theEventData.offsetEMin = histoEnergyOffset;
				theEventData.histogramID    = (col+1)*100+chan;
				theEventData.histogramInfo  = 0x2;// bit1 means 'this is a sum histogram'
				
				theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
				theEventData.lastBin   = 2047;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
				theEventData.histogramLength =2048;
				
				//ship data record
				totalLength = 2 + (sizeof(katrinV4HistogramDataStruct)/sizeof(int32_t)) + theEventData.histogramLength;// 2 = header + locationWord
				ensureDataCanHold(totalLength); 
				data[dataIndex++] = histogramId | totalLength;    
				data[dataIndex++] = location | chan<<8;
				int32_t checkDataIndexLength = dataIndex;
				data[dataIndex++] = theEventData.readoutSec;
				data[dataIndex++] = theEventData.refreshTimeSec;
				data[dataIndex++] = theEventData.firstBin;
				data[dataIndex++] = theEventData.lastBin;
				data[dataIndex++] = theEventData.histogramLength;
				data[dataIndex++] = theEventData.maxHistogramLength;
				data[dataIndex++] = theEventData.binSize;
				data[dataIndex++] = theEventData.offsetEMin;
				data[dataIndex++] = theEventData.histogramID;// don't confuse with Orca data ID 'histogramID' -tb-
				data[dataIndex++] = theEventData.histogramInfo;
				if( ((dataIndex-checkDataIndexLength)*sizeof(int32_t)) != sizeof(katrinV4HistogramDataStruct) ){ fprintf(stdout,"ORFLTv4Readout: WARNING: bad record size!\n");fflush(stdout); }
				int i;
				if(theEventData.histogramLength>0){
					for(i=0; i<theEventData.histogramLength;i++)
						data[dataIndex++] = sumHistogram[chan][i];
				}
			}
		}
	}
#endif
//-----------------------------------------
	
	return true;
}
#endif


#if (0)
//maybe read hit rates in the pmc at some point..... here's how....
//read hitrates
{
    int col,row;
    for(col=0; col<20;col++){
        if(srack->theFlt[col]->isPresent()){
            //fprintf(stdout,"FLT %i:",col);
            for(row=0; row<24;row++){
                int hitrate = srack->theFlt[col]->hitrate->read(row);
                //if(row<5) fprintf(stdout," %i(0x%x),",hitrate,hitrate);
            }
            //fprintf(stdout,"\n");
            //fflush(stdout);
            
        }
    }

    return true; 
}
#endif


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    //
    uint32_t dataId     = GetHardwareMask()[0];//this is energy record
    uint32_t waveformId = GetHardwareMask()[1];
    uint32_t histogramId = GetHardwareMask()[2];
    uint32_t col        = GetSlot() - 1; //the mac slots go from 1 to n
    uint32_t crate        = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16);
    
    uint32_t postTriggerTime = GetDeviceSpecificData()[0];
    uint32_t eventType  = GetDeviceSpecificData()[1];
    uint32_t fltRunMode = GetDeviceSpecificData()[2];
    uint32_t runFlags   = GetDeviceSpecificData()[3];
    uint32_t triggerEnabledMask = GetDeviceSpecificData()[4];
    uint32_t daqRunMode = GetDeviceSpecificData()[5];
	
#if 1
    //"counter" for debugging/simulation
    static int currentSec=0;
    static int currentUSec=0;
    static int lastSec=0;
    static int lastUSec=0;
    //static int32_t int counter=0;
    static int32_t int secCounter=0;
	static uint32_t writeSimEventMask = 0; //one bit per FLT (flags 'write simulated event' next time) -tb-
    
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    //timing
    gettimeofday(&t,NULL);
    currentSec = t.tv_sec;  
    currentUSec = t.tv_usec;  
    double diffTime = (double)(currentSec  - lastSec) +
    ((double)(currentUSec - lastUSec)) * 0.000001;
    
    if(diffTime >1.0){
        secCounter++;
        printf("PrPMC (FLTv4 simulation mode) sec %d: 1 sec is over ...\n",secCounter);
        fflush(stdout);
        //remember for next call
        lastSec      = currentSec; 
        lastUSec     = currentUSec; 
		//set the 'write event' mask
		writeSimEventMask = 0xfffff; //20 FLTs
    }else{
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }
#endif

	//FROM HERE: PUT THE SIMULATION CODE
	{
	if(writeSimEventMask & (1<<col)){
        printf("mask is 0x%x  ,  col %i\n", writeSimEventMask,col);
        fflush(stdout);
		writeSimEventMask &= ~(1<<col);
			//we write one energy event per channel per card ...
                        uint32_t evsec      = currentSec; 
                        uint32_t evsubsec   = currentUSec * 20; 
                        uint32_t precision  = 0;
                        uint32_t eventchan  = 2, chmap = 0x4;
						uint32_t readptr  =  secCounter % 512;
						uint32_t pagenr   =  secCounter % 64;
                        uint32_t fifoFlags = 0;
                        uint32_t energy = 10000 + (col+1)*100 + eventchan;
						ensureDataCanHold(7); 
                                data[dataIndex++] = dataId | 7;    
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = readptr | (pagenr<<10) | (precision<<16)  | (fifoFlags <<20);  //event flags: event ID=read ptr (10 bit); pagenr (6 bit); fifoFlags (4 bit)
                                data[dataIndex++] = energy;
		}
	}
	//END OF SIMULATION CODE
		
    
    return true;
}

bool ORFLTv4Readout::Stop()
{
	return true;
}


#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------


void ORFLTv4Readout::ClearSumHistogramBuffer()
{
	int i,j;
	for(i=0; i<kNumChan; i++){
		for(j=0; j<kMaxHistoLength; j++) sumHistogram[i][j] = 0;// i*1000 +j;
		recordingTimeSum[i] = 0;//i;
	}
}




//dumpster
        #if 0
            uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t  fifoStatus = (status >> 24) & 0xf;
            
            if(fifoStatus != kFifoEmpty){
                //TO DO... the number of events to read could (should) be made variable 
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    uint32_t fstatus = srack->theFlt[col]->eventFIFOStatus->read();
                    uint32_t writeptr = fstatus & 0x3ff;
                    uint32_t readptr = (fstatus >>16) & 0x3ff;
                    uint32_t diff = (writeptr-readptr+1024) % 512;
                    
                    if(diff>0){
                        uint32_t f1 = srack->theFlt[col]->eventFIFO1->read();
                        uint32_t chmap = f1 >> 8;
                        uint32_t f2 = srack->theFlt[col]->eventFIFO2->read();
                        uint32_t eventchan;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            if(chmap & (0x1L << eventchan)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                uint32_t evsec        = ( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                                uint32_t evsubsec    = (f2 >> 2) & 0x1ffffff; // 25 bit
                                
                                uint32_t waveformLength = 2048; 
                                if(eventType & kReadWaveForms){
                                    ensureDataCanHold(9 + waveformLength/2); 
                                    data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                }
                                else {
                                    ensureDataCanHold(7); 
                                    data[dataIndex++] = dataId | 7;    
                                }
                                

                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;    //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = pagenr;        //was listed as the event ID... put in the pagenr for now 
                                data[dataIndex++] = energy;
                                
                                if(eventType & kReadWaveForms){
                                    static uint32_t waveformBuffer32[64*1024];
                                    static uint32_t shipWaveformBuffer32[64*1024];
                                    static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                    static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                    uint32_t triggerPos = 0;
                                    
                                    srack->theSlt->pageSelect->write(0x100 | pagenr);
                                    
                                    uint32_t adccount;
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = srack->theFlt[col]->ramData->read(eventchan,adccount);
                                        waveformBuffer32[adccount] = adcval;
#if 1 //TODO: WORKAROUND - align according to the trigger flag - in future we will use the timestamp, when Denis has fixed it -tb-
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
#endif
                                    }
                                    uint32_t copyindex = (triggerPos + 1024) % 2048; // + postTriggerTime;
                                    uint32_t i;
                                    for(i=0;i<waveformLength;i++){
                                        shipWaveformBuffer16[i] = waveformBuffer16[copyindex];
                                        copyindex++;
                                        copyindex = copyindex % 2048;
                                    }
                                    
                                    //simulation mode
                                    if(0){
                                        for(i=0;i<waveformLength;i++){
                                            shipWaveformBuffer16[i]= (i>100)*i;
                                        }
                                    }
                                    //ship waveform
                                    uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                    data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                    for(i=0;i<waveformLength32;i++){
                                        data[dataIndex++] = shipWaveformBuffer32[i];
                                    }
                                }
                            }
                        }
                    }
                    else break;
                }
            }
            #endif
