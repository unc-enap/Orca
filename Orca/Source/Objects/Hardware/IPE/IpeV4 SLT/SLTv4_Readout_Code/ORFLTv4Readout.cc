#include "ORFLTv4Readout.hh"
#include "SLTv4_HW_Definitions.h"

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

//init static members and globals
uint32_t histoShipSumHistogram = 0;


#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------

extern hw4::SubrackKatrin* srack; 


bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
	//static data: buffer for data coming in from the hardware
#define kNumV4FLTs 20
#define kNumV4FLTChannels 24
#define kNumV4FLTADCPageSize16 2048
#define kNumV4FLTADCPageSize32 1024
	static uint32_t adctrace32[kNumV4FLTs][kNumV4FLTChannels][kNumV4FLTADCPageSize32];//shall I use a 4th index for the page number? -tb-
	//if sizeof(long unsigned int) != sizeof(uint32_t) we will come into troubles (64-bit-machines?) ... -tb-
	static uint32_t FIFO1[kNumV4FLTs];
	static uint32_t FIFO2[kNumV4FLTs];
	static uint32_t FIFO3[kNumV4FLTs][kNumV4FLTChannels];
	static uint32_t FIFO4[kNumV4FLTs];
	//static uint32_t FltStatusReg[kNumV4FLTs];
	//static uint32_t debugbuffer[kNumV4FLTs][kNumV4FLTChannels];//used for debugging -tb-


    //this data must be constant during a run
    static uint32_t histoBinWidth = 0;
    static uint32_t histoEnergyOffset = 0;
    static uint32_t histoRefreshTime = 0;
    
    //
    uint32_t dataId     = GetHardwareMask()[0];//this is energy record
    uint32_t waveformId = GetHardwareMask()[1];
    uint32_t histogramId = GetHardwareMask()[2];
    //uint32_t energyTraceId = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //GetSlot() is in fact stationNumber, which goes from 1 to 24 (slots go from 0-9, 11-20)
    uint32_t crate      = GetCrate();
    
    uint32_t postTriggerTime = GetDeviceSpecificData()[0];
    //uint32_t eventType  = GetDeviceSpecificData()[1];
    uint32_t fltRunMode = GetDeviceSpecificData()[2];
    uint32_t runFlags   = GetDeviceSpecificData()[3];//this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:
    uint32_t triggerEnabledMask = GetDeviceSpecificData()[4];
    uint32_t daqRunMode = GetDeviceSpecificData()[5];
    //uint32_t filterIndex = GetDeviceSpecificData()[6]; obsolete, changed 2012-11 -tb-
    uint32_t versionCFPGA = GetDeviceSpecificData()[7];
    uint32_t versionFPGA8 = GetDeviceSpecificData()[8];
    uint32_t filterShapingLength = GetDeviceSpecificData()[9];//TODO: need to change in the code below! -tb- 2011-04-01
    uint32_t useDmaBlockReadSetting = GetDeviceSpecificData()[10];//TODO: need to change in the code below! -tb- 2011-04-01
    uint32_t boxcarLen = GetDeviceSpecificData()[11];
	


    uint32_t useDmaBlockRead = 1; //if linked with DMA lib, force DMA mode -tb-
    if(useDmaBlockReadSetting){//0=auto detect, 1=yes, 2=no
       if(useDmaBlockReadSetting==2) useDmaBlockRead = 0;
    }else{//auto detect
        #ifdef PMC_LINK_WITH_DMA_LIB
            #if PMC_LINK_WITH_DMA_LIB
            useDmaBlockRead = 1; //if linked with DMA lib, force DMA mode -tb-
            #else
            useDmaBlockRead = 0;
            #endif
        #else
            useDmaBlockRead = 0;
        #endif
    }



	uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) | ((boxcarLen & 0x3)<<4)  | (filterShapingLength & 0xf)  ;  //TODO:  remove filterIndex (remove in decoders, too!) -tb-
	//uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) | ((filterIndex & 0xf)<<4)  | (filterShapingLength & 0xf)  ;  //TODO:  remove filterIndex (remove in decoders, too!) -tb-

	//for backward compatibility (before FLT versions2.1.1.4); shall be removed Jan. 2011 -tb-
	//===========================================================================================
	if((versionCFPGA>0x20010100 && versionCFPGA<0x20010104) || (versionFPGA8>0x20010100  && versionFPGA8<0x20010104) ){
	//this is for FPGA config. before FIFO redesign and 'sync' mode -tb-
    if(srack->theFlt[col]->isPresent()){
    
        #if 0
        //check timing
        //TODO: hmm, this should be done even before SLT releases inhibit ... -tb-
        if(0 /*runFlags & kSyncFltWithSltTimerFlag*/){ //TODO: FLT sec counter has only 13 bit, so this currently makes no sense; maybe after firmware redesign ... -tb-
            GetDeviceSpecificData()[3] &= ~(kSyncFltWithSltTimerFlag);
            uint32_t sltsubsec;
            uint32_t sltsec1;
            uint32_t sltsec2;
            uint32_t fltsec;
            sltsubsec   = srack->theSlt->subSecCounter->read();
            sltsec1      = srack->theSlt->secCounter->read();
            fltsec      = srack->theFlt[col]->secondCounter->read();
            sltsubsec   = srack->theSlt->subSecCounter->read();
            sltsec2      = srack->theSlt->secCounter->read();
            int i;
            for(i=0; i<10; i++){
                if(sltsec1==fltsec && sltsec2==fltsec) break;//to be sure that the second strobe was not between reading sltsec1 and sltsec2
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec1      = srack->theSlt->secCounter->read();
                srack->theFlt[col]->secondCounter->write(sltsec1);
                fltsec      = srack->theFlt[col]->secondCounter->read();
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec2      = srack->theSlt->secCounter->read();
                //debug fprintf(stdout,"ORFLTv4Readout.cc: Syncronizing FLT %i to secCounter %li!\n",col+1,sltsec1);fflush(stdout);
            }
        }
        #endif
        #if 0 // a temporary test -tb-
        {
            static int once=1;
            if(once){
            once=0;
            uint32_t sltsec;
            uint32_t sltsec1;
            uint32_t sltsec2;
            uint32_t sltsubsec;
            uint32_t sltsubsec1;
            uint32_t sltsubsec2;
            uint32_t fltsec,fltsec1;
            sltsubsec   = srack->theSlt->subSecCounter->read();
            sltsec1=sltsec      = srack->theSlt->secCounter->read();
            while(sltsec1 == sltsec){
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec      = srack->theSlt->secCounter->read();
            }
            fltsec1=fltsec = srack->theFlt[col]->secondCounter->read();
            fprintf(stdout,"slt strobe:slt sec %i  slt sub  %i  fltsec:  %i\n",sltsec,sltsubsec,fltsec);
            while(fltsec1==fltsec){
                fltsec = srack->theFlt[col]->secondCounter->read();
            }
                sltsubsec   = srack->theSlt->subSecCounter->read();
                sltsec      = srack->theSlt->secCounter->read();
            fprintf(stdout,"FLT strobe:slt sec %i  slt sub  %i  fltsec:  %i\n",sltsec,sltsubsec,fltsec);
            fflush(stdout);
            sleep(1);
            }
        }
        #endif
        
        
        //READOUT MODES (energy, energy+trace, histogram)
        ////////////////////////////////////////////////////
        
        
        // --- ENERGY MODE ------------------------------
        if((daqRunMode == kIpeFltV4_EnergyDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //not needed for now - uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();//TODO: then we should read more than 10 events? -tb-
                //not needed for now - uint32_t fifoFullFlag = eventFIFOStatus->fullFlag->getCache();//TODO: then we should clear the fifo and leave? -tb-

                if(!fifoEmptyFlag){
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
								
                    //depending on 'diff' the loop should start here -tb-
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        eventFIFO1->read();
                        eventFIFO2->read();
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                
                                ensureDataCanHold(7); 
                                data[dataIndex++] = dataId | 7;    
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit); fifoFlags (4 bit);flt mode (4 bit)
                                data[dataIndex++] = energy;
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave ...
            }//for(eventN=0; ...
        }
        // --- ENERGY+TRACE MODE ------------------------------
        else if((daqRunMode == kIpeFltV4_EnergyTraceDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){
                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        eventFIFO1->read();
                        eventFIFO2->read();
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        //uint32_t sltsubsec;
                        //uint32_t sltsec;
                        //int32_t timediff2slt;
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                uint32_t pagenr        = f3 & 0x3f;
                                uint32_t energy        = f4 ;
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: page %i\n",col,eventchan,pagenr);fflush(stdout);
                                uint32_t eventFlags=0;//append page, append next page
                                uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                                uint32_t traceStart16;//start of trace in short array
                                
                                //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger
                                wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                //else: full trigger search (not recommended)
								
                                #if 0
                                //check timing
                                readSltSecSubsec(sltsec,sltsubsec);
                                timediff2slt = (sltsec-evsec)*(int32_t)20000000 + ((int32_t)sltsubsec-(int32_t)evsubsec);//in 50ns units
//fprintf(stdout,"FLT%i>%i,%i<Timediff ev2slttime is %i (sec slt %i  ev %i) (subsec slt %i  ev  %i))   \n\r",col+1,readptr,writeptr,timediff2slt,sltsec,evsec,sltsubsec,evsubsec); fflush(stdout);
//fprintf(stdout,"-----------------------------                                  \n\r"); fflush(stdout);
                                #endif

                                uint32_t waveformLength = 2048; 
                                static uint32_t waveformBuffer32[64*1024];
                                static uint32_t shipWaveformBuffer32[64*1024];
                                //static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                uint32_t searchTrig,triggerPos = 0xffffffff;
                                int32_t appendFlagPos = -1;
                                
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read raw trace
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
                                if(wfRecordVersion == 0x2){
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;
								}
                                else if(wfRecordVersion == 0x1){
                                     //search trigger flag (usually in the same or adcoffset+2 bin 2009-12-15)
                                    searchTrig=adcoffset; //+2;
                                    searchTrig = searchTrig & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    //printf("FLT%i: FOund triggerPos %i , diff> %i<  (adcoffset was %i, searchtrig %i)\n",col+1,triggerPos,triggerPos-adcoffset, adcoffset,searchTrig);
									//printf("FLT%i: FOund triggerPos %i , diff> %i<  \n",col+1,triggerPos,triggerPos-adcoffset);fflush(stdout);
                                    //uint32_t copyindex = (adcoffset + postTriggerTime) % 2048;
#if 0  //TODO: testcode - I will remove it later -tb-
             fprintf(stdout,"triggerPos is %x (%i)  (last search pos %i)\n",triggerPos,triggerPos,searchTrig);fflush(stdout);
             fprintf(stdout,"srack->theFlt[col]->postTrigTime->read() %x \n",srack->theFlt[col]->postTrigTime->read());fflush(stdout);
           if(srack->theFlt[col]->postTrigTime->read() == 0x12c){
           for(adccount=0; adccount<2*1024;adccount++){
                   uint16_t adcval = shipWaveformBuffer16[adccount] & 0xffff;
                        if(adcval & 0xf000){
                         fprintf(stdout,"adcval[%i] has flags %x \n",adccount,adcval);fflush(stdout);
                        }
           }
           }
#endif
                                    traceStart16 = (triggerPos + postTriggerTime ) % 2048;
                                }
                                else {
                                    //search trigger pos
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = waveformBuffer32[adccount];
                                        #if 1
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
                                        if(adcval1 & 0x2000) appendFlagPos = adccount*2;
                                        if(adcval2 & 0x2000) appendFlagPos = adccount*2+1;
                                        #endif
                                    }
                                    //printf("FLT%i:triggerPos %i\n",col+1, triggerPos);
                                    //set append page flag
                                    if(appendFlagPos>=0) eventFlags |= 0x20;
                                    //uint32_t copyindex = (triggerPos + 1024) % 2048; //<- this aligns the trigger in the middle (from Mark)
                                    //uint32_t copyindex = (triggerPos + postTriggerTime) % 2048 ;// this was the workaround without time info -tb-
                                    traceStart16 = (adcoffset + postTriggerTime) % 2048 ;
								}
                                
                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                data[dataIndex++] = energy;
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = shipWaveformBuffer32[i];
                                }
                                
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }
        // --- HISTOGRAM MODE ------------------------------
        else if(fltRunMode == kIpeFltV4Katrin_Histo_Mode) {    //then fltRunMode == kIpeFltV4Katrin_Histo_Mode
                // buffer some data:
                hw4::FltKatrin *currentFlt = srack->theFlt[col];
                //hw4::SltKatrin *currentSlt = srack->theSlt;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);    
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout); 
                //sleep(1);   
                if(runFlags & kFirstTimeFlag){// firstTime   
                    //make some plausability checks
                    currentFlt->histogramSettings->read();//read to cache
                    if(currentFlt->histogramSettings->histModeStopUncleared->getCache() ||
                       currentFlt->histogramSettings->histClearModeManual->getCache()){
                        fprintf(stdout,"ORFLTv4Readout.cc: WARNING: histogram readout is designed for continous and auto-clear mode only! Change your FLTv4 settings!\n");
                        fflush(stdout);
                    }
                    //store some static data which is constant during run
                    histoBinWidth       = currentFlt->histogramSettings->histEBin->getCache();
                    histoEnergyOffset   = currentFlt->histogramSettings->histEMin->getCache();
                    histoRefreshTime    = currentFlt->histMeasTime->read();
					histoShipSumHistogram = runFlags & kShipSumHistogramFlag;

					//clear the buffers for the sum histogram
					ClearSumHistogramBuffer();
				
					//set page manager to automatic mode
					//srack->theSlt->pageSelect->write(0x100 | 3); //TODO: this flips the two parts of the histogram - FPGA bug? -tb-
					srack->theSlt->pageSelect->write((long unsigned int)0x0);
                    //reset histogram time counters (=histRecTime=refresh time -tb-) //TODO: unfortunately there is no such command for the histogramming -tb- 2010-07-28
                    //TODO: srack->theFlt[col]->command->resetPointers->write(1);
                    //clear histogram (probably not really necessary with "automatic clear" -tb-) 
                    srack->theFlt[col]->command->resetPages->write(1);
                    //init page AB flag
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    GetDeviceSpecificData()[3]=pageAB;// runFlags is GetDeviceSpecificData()[3], so this clears the 'first time' flag -tb-
					//TODO: better use a local static variable and init it the first time, as changing GetDeviceSpecificData()[3] could be dangerous -tb-
                    //debug: fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
                    //debug: //sleep(1);
                }
                else{//check timing
                    //pagenr=srack->theFlt[col]->histNofMeas->read() & 0x3f;
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    oldpageAB = GetDeviceSpecificData()[3]; //
                    //pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
                    //pageAB = srack->theFlt[col]->periphStatus->histPageAB->read(0);
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    //fprintf(stdout,"FLT %i: oldpage  %i currpagenr %i\n",col+1, oldpagenr, pagenr  );fflush(stdout);  
                    //              sleep(1);
                    
                    if(oldpageAB != pageAB){
                        //debug: fprintf(stdout,"FLT %i:toggle now from %i to page %i\n",col+1, oldpageAB, pageAB  );fflush(stdout);    
                        GetDeviceSpecificData()[3] = pageAB; 
                        //read data
                        uint32_t chan=0;
                        uint32_t readoutSec;
                        unsigned long totalLength;
                        uint32_t last,first;
                        uint32_t fpgaHistogramID;
                        static uint32_t shipHistogramBuffer32[2048];
                        fpgaHistogramID     = currentFlt->histNofMeas->read();
                        // CHANNEL LOOP ----------------
                        for(chan=0;chan<kNumChan;chan++) {//read out histogram
                            if( !(triggerEnabledMask & (0x1L << chan)) ) continue; //skip channels with disabled trigger
                            currentFlt->histLastFirst->read(chan);//read to cache ...
                            //last = (lastFirst >>16) & 0xffff;
                            //first = lastFirst & 0xffff;
                            last  = currentFlt->histLastFirst->histLastEntry->getCache(chan);
                            first = currentFlt->histLastFirst->histFirstEntry->getCache(chan);
                            //debug: fprintf(stdout,"FLT %i: ch %i:first %i, last %i \n",col+1,chan,first,last);fflush(stdout);
                            
                            #if 1  //READ OUT HISTOGRAM -tb- -------------
							{
								//read sec
								readoutSec=currentFlt->secondCounter->read();
                                //prepare data record
                                katrinV4HistogramDataStruct theEventData;
                                theEventData.readoutSec = readoutSec;
                                theEventData.refreshTimeSec =  histoRefreshTime;//histoRunTime;   
								
								//read out histogram
								if(last<first){
									//no events, write out empty histogram -tb-
									theEventData.firstBin  = 2047;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 0;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =0;
								}
								else{
									//read histogram block
									srack->theFlt[col]->histogramData->readBlockAutoInc(chan,  (long unsigned int*)shipHistogramBuffer32, 0, 2048);
									theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 2047;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =2048;
								}
							
                                //theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
                                //if(theEventData.histogramLength < 0){// we had no counts ...
                                //    theEventData.histogramLength = 0;
                                //}
                                theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
                                theEventData.binSize    = histoBinWidth;        
                                theEventData.offsetEMin = histoEnergyOffset;
                                theEventData.histogramID    = fpgaHistogramID;
                                theEventData.histogramInfo  = pageAB & 0x1;//one bit
                                
                                //ship data record
                                totalLength = 2 + (sizeof(katrinV4HistogramDataStruct)/sizeof(uint32_t)) + theEventData.histogramLength;// 2 = header + locationWord
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
										data[dataIndex++] = shipHistogramBuffer32[i];
								}
								//debug: fprintf(stdout," Shipping histogram with ID %i\n",histogramID);     fflush(stdout);  
								
								//add histogram to sum histogram
								if( histoShipSumHistogram & kShipSumHistogramFlag ){
									recordingTimeSum[chan] += theEventData.refreshTimeSec;
									if(theEventData.histogramLength>0){//don't fill in empty histograms
										for(i=0; i<theEventData.histogramLength;i++){//TODO: need to use firstBin...lastBin for parts of histograms -tb-
											sumHistogram[chan][i] += shipHistogramBuffer32[i];
										}
									}
								}
                            }
                            #endif
                            
                        }
                    } 
                }
        }
        // --- BAD MODE ------------------------------
        else{
            fprintf(stdout,"ORFLTv4Readout.cc: WARNING: received unknown DAQ mode! (old FPGA conf?)\n"); fflush(stdout);
			return true;
        }

    }
	}

	//this handles FLT firmware starting from CFPGA-FPGA8 version 0x20010104-0x20010104 (both 2.1.1.4) and newer 2010-11-08  -tb-
	// (mainly from 2.1.1.4 - 2.1.2.1 -tb-)((but both 2.1.1.4 will work, too)
	// new in FPGA config:  FIFO redesign and new 'sync' mode -tb-
    // 2013-11-14 bipolar energy update - changes in SLT registers - see below -tb-
	//===================================================================================================================
    if((versionCFPGA>=0x20010104 && versionCFPGA<0x20010300) || (versionFPGA8>=0x20010104  && versionFPGA8<0x20010300) ){
    if(srack->theFlt[col]->isPresent()){
		
		//static uint32_t currFlt = col;// only for better readability (started using it since EnergyTraceSync mode for HW data buffering)  -tb-
		
        
        //READOUT MODES (energy, energy+trace, histogram)
        ////////////////////////////////////////////////////
        
        
        // --- ENERGY MODE ------------------------------
        if((daqRunMode == kIpeFltV4_EnergyDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //not needed for now - uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();//TODO: then we should read more than 10 events? -tb-
                //not needed for now - uint32_t fifoFullFlag = eventFIFOStatus->fullFlag->getCache();//TODO: then we should clear the fifo and leave? -tb-

                if(!fifoEmptyFlag){
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
								
                    //depending on 'diff' the loop should start here -tb-
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        f1=eventFIFO1->read();
                        f2=eventFIFO2->read();
                        //uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                        //uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        uint32_t evsec      = f4;//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                uint32_t energy        = f3 & 0xfffff;
                                
                                ensureDataCanHold(7); 
                                data[dataIndex++] = dataId | 7;    
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit); fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave ...
            }//for(eventN=0; ...
        }
        // --- 'ENERGY+TRACE' MODE -------------------------tb-------   2013-05-29: THIS MODE NOW replaces 'ENERGY+TRACE' and 'ENERGY+TRACE (SYNC)'!!-tb-
        else if((daqRunMode == kIpeFltV4_EnergyTraceDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
        //TODO: else if((daqRunMode == kIpeFltV4_EnergyTraceSyncDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceSyncDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
			
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){

                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                    if(diff>0){
						//first buffer the data in the FIFO and the ADC pages ...
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        FIFO1[col] =eventFIFO1->read();
                        FIFO2[col] =eventFIFO2->read();
                        f1 = FIFO1[col];
                        f2 = FIFO2[col];
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
						//if in DMA mode we need to leave some time (postTriggerTime) until the ADC trace is written to the FLT RAM
						#if 1
						if(useDmaBlockRead){//we poll the FIFO; typically we detect a event after 200 subsecs (=10 micro sec/usec) (150-250 subsec) (sometimes 1200-4000 subsec=60-200 usec - is Orca busy here?)
						                    //as the HW is still recording the ADC trace (post trigg part with typically 1024 and up to 2048 subsec = 51,2-102,4 usec)
							uint32_t sltsubseccount,sltsubsec1,sltsubsec2,sltsubsec;
							int32_t diffsubsec;
							sltsubseccount   = srack->theSlt->subSecCounter->read();
							sltsubsec1 = sltsubseccount & 0x7ff;
							sltsubsec2 = (sltsubseccount>>11) & 0x3fff;
							sltsubsec   =  sltsubsec2 * 2000 + sltsubsec1;
							diffsubsec = (sltsubsec-evsubsec+20000000) % 20000000;
//							if(evsubsec>sltsubsec) fprintf(stderr,"---==============-------------------==============================_-----------------______________===========================\n");
//							fprintf(stderr,"---  diffsubsec is %i\n",diffsubsec);
//							fprintf(stderr,"---  diffsubsec is %i, post trigg: %i  (  ((0x%08x=%i))  sltsubsec %i, evsubsec %i)\n",diffsubsec,postTriggerTime,sltsubseccount,sltsubseccount,sltsubsec,evsubsec);
//							if(diffsubsec<postTriggerTime) fprintf(stderr,"---=============break\n");
							if(diffsubsec<(int32_t)postTriggerTime) break; //FLT still recording ADC trace -> leave for later for(eventN ...)-loop cycle ... -tb-
						}
						#endif
						
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
						uint32_t traceStart16;//start of trace in short array
                                //if(wfRecordVersion == 0x2){ 
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;  //TODO: take this as standard from FW 2.1.1.4 on -tb-
								//}
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache(); //TODO: we would need this for every channel in the channel mask -> move to FIFO3!!!! -tb-   !!!!!!!!
						
						uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                        //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger - OBSOLETE (I think this never was used ...)
                        wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
						//TODO: I would like to store the version of the readout code <------------------------------------!!!! use new functions "generalRead/Write   -tb-
                        //else: full trigger search (not recommended)

                        uint32_t eventchan, eventchanmask;
						//now start loop to buffer FIFO and the ADC pages ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
								FIFO3[col][eventchan] = f3;
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                //uint32_t energy        = f3 & 0xfffff;
				
                                //static uint32_t waveformBuffer32[64*1024];
                                //static uint32_t shipWaveformBuffer32[64*1024];
                                //static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                //static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                //uint32_t searchTrig;
                                //uint32_t triggerPos = 0xffffffff;
                                //int32_t appendFlagPos = -1;
                                
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read the raw trace
								if(useDmaBlockRead){
								    //DMA: readBlock
								    //srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								    srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA, memcopy without
								}else{
								    //single access mode
								    //read raw trace (use two loops as otherwise the FLT maybe has not yet written 'postTrigTIme' traces ... then we would read old data - see Elog XXX Florian)
                                    uint32_t adccount, trigSlot;
								    trigSlot = adcoffset/2;
								    for(adccount=trigSlot; adccount<1024;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								    for(adccount=0; adccount<trigSlot;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								}
								
								//this was the old code (before 2012-03, DMA):
							   #if 0
								#if 1
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								#else
								//DMA: readBlock
								#pragma message Using DMA mode!
								;
								//srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA
								//srack->theFlt[col]->histogramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //PCI burst  w/o libPCIDMA
								#endif
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
							   #endif
							}
						}
						//if FIFO is full this (reading FIFO4) will release the current entry in the FIFO to allow the HW to record the next event -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						FIFO4[col]=f4;
						
						//now ship the buffered data ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3		= FIFO3[col][eventchan];
                                uint32_t pagenr = (f3 >> 24) & 0x3f;
                                uint32_t energy = f3 & 0xfffff;
								uint32_t evsec	= FIFO4[col];//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
       
                                uint32_t waveformLength = 2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
								
                                uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-

                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength32);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                                //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = adctrace32[col][eventchan][i];
                                }
                                
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }
        // --- 'ENERGY+TRACE (SYNC)' MODE ------------------------NEW: 2011-01-tb-------   2013-05-29: THIS MODE NOW IS OBSOLETE!! (make all changes manually) -tb-
        else if((daqRunMode == kIpeFltV4_EnergyTraceSyncDaqMode) ){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
        //TODO: else if((daqRunMode == kIpeFltV4_EnergyTraceSyncDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceSyncDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
			// this mode ensures to read out according energy and trace (but will not catch all events at high rates)
			#if 0
            {//TODO: remove debugging output -tb-
			static int firsttimeflag=0;
			if(firsttimeflag<5){fprintf(stdout,"ORFLTv4Readout.cc:   DAQ mode kIpeFltV4_EnergyTraceSyncDaqMode!\n"); fflush(stdout);}
			firsttimeflag++;
			}
			//return true;
			#endif
			
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){

                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                    if(diff>0){
						//first buffer the data in the FIFO and the ADC pages ...
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        FIFO1[col] =eventFIFO1->read();
                        FIFO2[col] =eventFIFO2->read();
                        f1 = FIFO1[col];
                        f2 = FIFO2[col];
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
						//if in DMA mode we need to leave some time (postTriggerTime) until the ADC trace is written to the FLT RAM
						#if 1
						if(useDmaBlockRead){//we poll the FIFO; typically we detect a event after 200 subsecs (=10 micro sec/usec) (150-250 subsec) (sometimes 1200-4000 subsec=60-200 usec - is Orca busy here?)
						                    //as the HW is still recording the ADC trace (post trigg part with typically 1024 and up to 2048 subsec = 51,2-102,4 usec)
							uint32_t sltsubseccount,sltsubsec1,sltsubsec2,sltsubsec;
							int32_t diffsubsec;
							sltsubseccount   = srack->theSlt->subSecCounter->read();
							sltsubsec1 = sltsubseccount & 0x7ff;
							sltsubsec2 = (sltsubseccount>>11) & 0x3fff;
							sltsubsec   =  sltsubsec2 * 2000 + sltsubsec1;
							diffsubsec = (sltsubsec-evsubsec+20000000) % 20000000;
//							if(evsubsec>sltsubsec) fprintf(stderr,"---==============-------------------==============================_-----------------______________===========================\n");
//							fprintf(stderr,"---  diffsubsec is %i\n",diffsubsec);
//							fprintf(stderr,"---  diffsubsec is %i, post trigg: %i  (  ((0x%08x=%i))  sltsubsec %i, evsubsec %i)\n",diffsubsec,postTriggerTime,sltsubseccount,sltsubseccount,sltsubsec,evsubsec);
//							if(diffsubsec<postTriggerTime) fprintf(stderr,"---=============break\n");
							if(diffsubsec<(int32_t)postTriggerTime) break; //FLT still recording ADC trace -> leave for later for(eventN ...)-loop cycle ... -tb-
						}
						#endif
						
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
						uint32_t traceStart16;//start of trace in short array
                                //if(wfRecordVersion == 0x2){ 
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;  //TODO: take this as standard from FW 2.1.1.4 on -tb-
								//}
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache(); //TODO: we would need this for every channel in the channel mask -> move to FIFO3!!!! -tb-   !!!!!!!!
						
						uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                        //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger - OBSOLETE (I think this never was used ...)
                        wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
						//TODO: I would like to store the version of the readout code <------------------------------------!!!! use new functions "generalRead/Write   -tb-
                        //else: full trigger search (not recommended)

                        uint32_t eventchan, eventchanmask;
						//now start loop to buffer FIFO and the ADC pages ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
								//DEBUG:// for checking the peripheral page counters (debugging) -tb-
								//DEBUG://test page#
                                //DEBUG:uint32_t pageN            = (srack->theFlt[col]->eventFIFO3)->Pbus::read(0x20200c>>2); 
								//DEBUG:debugbuffer[col][eventchan] = pageN;
								//DEBUG:
								FIFO3[col][eventchan] = f3;
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                //uint32_t energy        = f3 & 0xfffff;
//fprintf(stdout,"col:%i, rp: %i wp: %i , chmap: %i pagenr:%i energy: %i \n\r",col+1,readptr,writeptr, chmap,pagenr, energy); fflush(stdout);
//fprintf(stdout,"-----------------------------                                  \n\r"); fflush(stdout);
				
                                //static uint32_t waveformBuffer32[64*1024];
                                //static uint32_t shipWaveformBuffer32[64*1024];
                                //static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                //static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                //uint32_t searchTrig;
                                //uint32_t triggerPos = 0xffffffff;
                                //int32_t appendFlagPos = -1;
                                
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read the raw trace
								if(useDmaBlockRead){
								    //DMA: readBlock
								    //srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								    srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA, memcopy without
								}else{
								    //single access mode
								    //read raw trace (use two loops as otherwise the FLT maybe has not yet written 'postTrigTIme' traces ... then we would read old data - see Elog XXX Florian)
                                    uint32_t adccount, trigSlot;
								    trigSlot = adcoffset/2;
								    for(adccount=trigSlot; adccount<1024;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								    for(adccount=0; adccount<trigSlot;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								}
								
								//this was the old code (before 2012-03, DMA):
							   #if 0
								#if 1
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								#else
								//DMA: readBlock
								#pragma message Using DMA mode!
								;
								//srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA
								//srack->theFlt[col]->histogramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //PCI burst  w/o libPCIDMA
								#endif
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
							   #endif
							}
						}
						//if FIFO is full this (reading FIFO4) will release the current entry in the FIFO to allow the HW to record the next event -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						FIFO4[col]=f4;
						
						//now ship the buffered data ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3		= FIFO3[col][eventchan];
                                uint32_t pagenr = (f3 >> 24) & 0x3f;
                                uint32_t energy = f3 & 0xfffff;
								uint32_t evsec	= FIFO4[col];//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
       
                                uint32_t waveformLength = 2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
								
                                uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-

                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength32);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                                //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = adctrace32[col][eventchan][i];
                                }
                                
                            }
                        }
#if 0
						//f4            = 
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"3x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
						srack->theFlt[col]->eventFIFO4->read(0);
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"4x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
#endif
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }

#if 0 //old ENERGY+TRACE MODE (without waiting until postTriggerTime has elapsed) - commented out 2013-05-29   --> REMOVE IT 2015-05 -tb-
        // --- ENERGY+TRACE MODE ------------------------------
        else if((daqRunMode == kIpeFltV4_EnergyTraceDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){

                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        f1=eventFIFO1->read();
                        f2=eventFIFO2->read();
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        uint32_t evsec      = f4;//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t sltsubsec;
                        uint32_t sltsec;
                        int32_t timediff2slt;
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                uint32_t energy        = f3 & 0xfffff;
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: page %i\n",col,eventchan,pagenr);fflush(stdout);
                                uint32_t eventFlags=0;//append page, append next page
                                uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                                uint32_t traceStart16;//start of trace in short array
                                
                                //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger
                                wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                //else: full trigger search (not recommended)
								
                                #if 0
                                //check timing
                                readSltSecSubsec(sltsec,sltsubsec);
                                timediff2slt = (sltsec-evsec)*(int32_t)20000000 + ((int32_t)sltsubsec-(int32_t)evsubsec);//in 50ns units
//fprintf(stdout,"FLT%i>%i,%i<Timediff ev2slttime is %i (sec slt %i  ev %i) (subsec slt %i  ev  %i))   \n\r",col+1,readptr,writeptr,timediff2slt,sltsec,evsec,sltsubsec,evsubsec); fflush(stdout);
//fprintf(stdout,"-----------------------------                                  \n\r"); fflush(stdout);
                                #endif

                                uint32_t waveformLength = 2048; 
                                static uint32_t waveformBuffer32[64*1024];
                                static uint32_t shipWaveformBuffer32[64*1024];
                                static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                uint32_t searchTrig,triggerPos = 0xffffffff;
                                int32_t appendFlagPos = -1;
                                
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read raw trace
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
                                if(wfRecordVersion == 0x2){
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;  //TODO: take this as standard from FW 2.1.1.4 on -tb-
								}
                                else if(wfRecordVersion == 0x1){
                                     //search trigger flag (usually in the same or adcoffset+2 bin 2009-12-15)
                                    searchTrig=adcoffset; //+2;
                                    searchTrig = searchTrig & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    //printf("FLT%i: FOund triggerPos %i , diff> %i<  (adcoffset was %i, searchtrig %i)\n",col+1,triggerPos,triggerPos-adcoffset, adcoffset,searchTrig);
									//printf("FLT%i: FOund triggerPos %i , diff> %i<  \n",col+1,triggerPos,triggerPos-adcoffset);fflush(stdout);
                                    //uint32_t copyindex = (adcoffset + postTriggerTime) % 2048;
#if 0  //TODO: testcode - I will remove it later -tb-
             fprintf(stdout,"triggerPos is %x (%i)  (last search pos %i)\n",triggerPos,triggerPos,searchTrig);fflush(stdout);
             fprintf(stdout,"srack->theFlt[col]->postTrigTime->read() %x \n",srack->theFlt[col]->postTrigTime->read());fflush(stdout);
           if(srack->theFlt[col]->postTrigTime->read() == 0x12c){
           for(adccount=0; adccount<2*1024;adccount++){
                   uint16_t adcval = shipWaveformBuffer16[adccount] & 0xffff;
                        if(adcval & 0xf000){
                         fprintf(stdout,"adcval[%i] has flags %x \n",adccount,adcval);fflush(stdout);
                        }
           }
           }
#endif
                                    traceStart16 = (triggerPos + postTriggerTime ) % 2048;
                                }
                                else {
                                    //search trigger pos
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = waveformBuffer32[adccount];
                                        #if 1
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
                                        if(adcval1 & 0x2000) appendFlagPos = adccount*2;
                                        if(adcval2 & 0x2000) appendFlagPos = adccount*2+1;
                                        #endif
                                    }
                                    //printf("FLT%i:triggerPos %i\n",col+1, triggerPos);
                                    //set append page flag
                                    if(appendFlagPos>=0) eventFlags |= 0x20;
                                    //uint32_t copyindex = (triggerPos + 1024) % 2048; //<- this aligns the trigger in the middle (from Mark)
                                    //uint32_t copyindex = (triggerPos + postTriggerTime) % 2048 ;// this was the workaround without time info -tb-
                                    traceStart16 = (adcoffset + postTriggerTime) % 2048 ;
								}
                                
                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = shipWaveformBuffer32[i];
                                }
                                
                            }
                        }
#if 0
						//f4            = 
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"3x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
						srack->theFlt[col]->eventFIFO4->read(0);
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"4x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
#endif
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }
#endif
        // --- HISTOGRAM MODE ------------------------------
        else if(fltRunMode == kIpeFltV4Katrin_Histo_Mode) {    //then fltRunMode == kIpeFltV4Katrin_Histo_Mode
                // buffer some data:
                hw4::FltKatrin *currentFlt = srack->theFlt[col];
                //hw4::SltKatrin *currentSlt = srack->theSlt;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);    
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout); 
                //sleep(1);   
                if(runFlags & kFirstTimeFlag){// firstTime   
                    //make some plausability checks
                    currentFlt->histogramSettings->read();//read to cache
                    if(currentFlt->histogramSettings->histModeStopUncleared->getCache() ||
                       currentFlt->histogramSettings->histClearModeManual->getCache()){
                        fprintf(stdout,"ORFLTv4Readout.cc: WARNING: histogram readout is designed for continous and auto-clear mode only! Change your FLTv4 settings!\n");
                        fflush(stdout);
                    }
                    //store some static data which is constant during run
                    histoBinWidth       = currentFlt->histogramSettings->histEBin->getCache();
                    histoEnergyOffset   = currentFlt->histogramSettings->histEMin->getCache();
                    histoRefreshTime    = currentFlt->histMeasTime->read();
					histoShipSumHistogram = runFlags & kShipSumHistogramFlag;

					//clear the buffers for the sum histogram
					ClearSumHistogramBuffer();
				
					//set page manager to automatic mode
					//srack->theSlt->pageSelect->write(0x100 | 3); //TODO: this flips the two parts of the histogram - FPGA bug? -tb-
					srack->theSlt->pageSelect->write((long unsigned int)0x0);
                    //reset histogram time counters (=histRecTime=refresh time -tb-) //TODO: unfortunately there is no such command for the histogramming -tb- 2010-07-28
                    //TODO: srack->theFlt[col]->command->resetPointers->write(1);
                    //clear histogram (probably not really necessary with "automatic clear" -tb-) 
                    srack->theFlt[col]->command->resetPages->write(1);
                    //init page AB flag
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    GetDeviceSpecificData()[3]=pageAB;// runFlags is GetDeviceSpecificData()[3], so this clears the 'first time' flag -tb-
					//TODO: better use a local static variable and init it the first time, as changing GetDeviceSpecificData()[3] could be dangerous -tb-
                    //debug: fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
                    //debug: //sleep(1);
                }
                else{//check timing
                    //pagenr=srack->theFlt[col]->histNofMeas->read() & 0x3f;
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    oldpageAB = GetDeviceSpecificData()[3]; //
                    //pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
                    //pageAB = srack->theFlt[col]->periphStatus->histPageAB->read(0);
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    //fprintf(stdout,"FLT %i: oldpage  %i currpagenr %i\n",col+1, oldpagenr, pagenr  );fflush(stdout);  
                    //              sleep(1);
                    
                    if(oldpageAB != pageAB){
                        //debug: fprintf(stdout,"FLT %i:toggle now from %i to page %i\n",col+1, oldpageAB, pageAB  );fflush(stdout);    
                        GetDeviceSpecificData()[3] = pageAB; 
                        //read data
                        uint32_t chan=0;
                        uint32_t readoutSec;
                        unsigned long totalLength;
                        uint32_t last,first;
                        uint32_t fpgaHistogramID;
                        static uint32_t shipHistogramBuffer32[2048];
                        fpgaHistogramID     = currentFlt->histNofMeas->read();
                        // CHANNEL LOOP ----------------
                        for(chan=0;chan<kNumChan;chan++) {//read out histogram
                            if( !(triggerEnabledMask & (0x1L << chan)) ) continue; //skip channels with disabled trigger
                            currentFlt->histLastFirst->read(chan);//read to cache ...
                            //last = (lastFirst >>16) & 0xffff;
                            //first = lastFirst & 0xffff;
                            last  = currentFlt->histLastFirst->histLastEntry->getCache(chan);
                            first = currentFlt->histLastFirst->histFirstEntry->getCache(chan);
                            //debug: fprintf(stdout,"FLT %i: ch %i:first %i, last %i \n",col+1,chan,first,last);fflush(stdout);
                            
                            #if 1  //READ OUT HISTOGRAM -tb- -------------
							{
								//read sec
								readoutSec=currentFlt->secondCounter->read();
                                //prepare data record
                                katrinV4HistogramDataStruct theEventData;
                                theEventData.readoutSec = readoutSec;
                                theEventData.refreshTimeSec =  histoRefreshTime;//histoRunTime;   
								
								//read out histogram
								if(last<first){
									//no events, write out empty histogram -tb-
									theEventData.firstBin  = 2047;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 0;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =0;
								}
								else{
									//read histogram block
									srack->theFlt[col]->histogramData->readBlockAutoInc(chan,  (long unsigned int*)shipHistogramBuffer32, 0, 2048);
									theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 2047;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =2048;
								}
							
                                //theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
                                //if(theEventData.histogramLength < 0){// we had no counts ...
                                //    theEventData.histogramLength = 0;
                                //}
                                theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
                                theEventData.binSize    = histoBinWidth;        
                                theEventData.offsetEMin = histoEnergyOffset;
                                theEventData.histogramID    = fpgaHistogramID;
                                theEventData.histogramInfo  = pageAB & 0x1;//one bit
                                
                                //ship data record
                                totalLength = 2 + (sizeof(katrinV4HistogramDataStruct)/sizeof(uint32_t)) + theEventData.histogramLength;// 2 = header + locationWord
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
										data[dataIndex++] = shipHistogramBuffer32[i];
								}
								//debug: fprintf(stdout," Shipping histogram with ID %i\n",histogramID);     fflush(stdout);  
								
								//add histogram to sum histogram
								if( histoShipSumHistogram & kShipSumHistogramFlag ){
									recordingTimeSum[chan] += theEventData.refreshTimeSec;
									if(theEventData.histogramLength>0){//don't fill in empty histograms
										for(i=0; i<theEventData.histogramLength;i++){//TODO: need to use firstBin...lastBin for parts of histograms -tb-
											sumHistogram[chan][i] += shipHistogramBuffer32[i];
										}
									}
								}
                            }
                            #endif
                            
                        }
                    } 
                }
        }
        // --- BAD MODE ------------------------------
        else{
            fprintf(stdout,"ORFLTv4Readout.cc: WARNING: received unknown DAQ mode (%i)!\n",daqRunMode); fflush(stdout);
        }

    }
    }
	
	// 2013-11-14 bipolar energy update - changes in SLT registers (for versionCFPGA  >= 0x20010300  &&  versionFPGA8 >= 0x20010300) -tb-
	//===================================================================================================================
    if(srack->theFlt[col]->isPresent()){
		
		//static uint32_t currFlt = col;// only for better readability (started using it since EnergyTraceSync mode for HW data buffering)  -tb-
		
        
        //READOUT MODES (energy, energy+trace, histogram)
        ////////////////////////////////////////////////////
        
        
        // --- ENERGY MODE ------------------------------
        if((daqRunMode == kIpeFltV4_EnergyDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //not needed for now - uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();//TODO: then we should read more than 10 events? -tb-
                //not needed for now - uint32_t fifoFullFlag = eventFIFOStatus->fullFlag->getCache();//TODO: then we should clear the fifo and leave? -tb-

                if(!fifoEmptyFlag){
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
								
                    //depending on 'diff' the loop should start here -tb-
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        f1=eventFIFO1->read();
                        f2=eventFIFO2->read();
                        //uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                        //uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        uint32_t evsec      = f4;//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                uint32_t energy        = f3 & 0xfffff;
                                
                                ensureDataCanHold(7); 
                                data[dataIndex++] = dataId | 7;    
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit); fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave ...
            }//for(eventN=0; ...
        }
        // --- 'ENERGY+TRACE' MODE -------------------------tb-------   2013-05-29: THIS MODE NOW replaces 'ENERGY+TRACE' and 'ENERGY+TRACE (SYNC)'!!-tb-
        else if((daqRunMode == kIpeFltV4_EnergyTraceDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
        //TODO: else if((daqRunMode == kIpeFltV4_EnergyTraceSyncDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceSyncDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
			
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){

                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                    if(diff>0){
						//first buffer the data in the FIFO and the ADC pages ...
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        FIFO1[col] =eventFIFO1->read();
                        FIFO2[col] =eventFIFO2->read();
                        f1 = FIFO1[col];
                        f2 = FIFO2[col];
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
						//if in DMA mode we need to leave some time (postTriggerTime) until the ADC trace is written to the FLT RAM
						#if 1
						if(useDmaBlockRead){//we poll the FIFO; typically we detect a event after 200 subsecs (=10 micro sec/usec) (150-250 subsec) (sometimes 1200-4000 subsec=60-200 usec - is Orca busy here?)
						                    //as the HW is still recording the ADC trace (post trigg part with typically 1024 and up to 2048 subsec = 51,2-102,4 usec)
							uint32_t sltsubseccount,sltsubsec1,sltsubsec2,sltsubsec;
							int32_t diffsubsec;
							sltsubseccount   = srack->theSlt->subSecCounter->read();
							sltsubsec1 = sltsubseccount & 0x7ff;
							sltsubsec2 = (sltsubseccount>>11) & 0x3fff;
							sltsubsec   =  sltsubsec2 * 2000 + sltsubsec1;
							diffsubsec = (sltsubsec-evsubsec+20000000) % 20000000;
//							if(evsubsec>sltsubsec) fprintf(stderr,"---==============-------------------==============================_-----------------______________===========================\n");
//							fprintf(stderr,"---  diffsubsec is %i\n",diffsubsec);
//							fprintf(stderr,"---  diffsubsec is %i, post trigg: %i  (  ((0x%08x=%i))  sltsubsec %i, evsubsec %i)\n",diffsubsec,postTriggerTime,sltsubseccount,sltsubseccount,sltsubsec,evsubsec);
//							if(diffsubsec<postTriggerTime) fprintf(stderr,"---=============break\n");
							if(diffsubsec<(int32_t)postTriggerTime) break; //FLT still recording ADC trace -> leave for later for(eventN ...)-loop cycle ... -tb-
						}
						#endif
						
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
						uint32_t traceStart16;//start of trace in short array
                                //if(wfRecordVersion == 0x2){ 
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;  //TODO: take this as standard from FW 2.1.1.4 on -tb-
								//}
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache(); //TODO: we would need this for every channel in the channel mask -> move to FIFO3!!!! -tb-   !!!!!!!!
						
						uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                        //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger - OBSOLETE (I think this never was used ...)
                        wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
						//TODO: I would like to store the version of the readout code <------------------------------------!!!! use new functions "generalRead/Write   -tb-
                        //else: full trigger search (not recommended)

                        uint32_t eventchan, eventchanmask;
						//now start loop to buffer FIFO and the ADC pages ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
								FIFO3[col][eventchan] = f3;
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                //uint32_t energy        = f3 & 0xfffff;
				
                                //static uint32_t waveformBuffer32[64*1024];
                                //static uint32_t shipWaveformBuffer32[64*1024];
                                //static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                //static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                //uint32_t searchTrig;
                                //uint32_t triggerPos = 0xffffffff;
                                //int32_t appendFlagPos = -1;
                                
                                //Auger Registers Removed for Bipolar Filter Upgrade 2013 -tb-
                                /*      they were actually never used for KATRIN, but will result in Pbus timeouts -tb-
TODO                            */
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read the raw trace
								if(useDmaBlockRead){
								    //DMA: readBlock
								    //srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								    srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA, memcopy without
								}else{
								    //single access mode
								    //read raw trace (use two loops as otherwise the FLT maybe has not yet written 'postTrigTIme' traces ... then we would read old data - see Elog XXX Florian)
                                    uint32_t adccount, trigSlot;
								    trigSlot = adcoffset/2;
								    for(adccount=trigSlot; adccount<1024;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								    for(adccount=0; adccount<trigSlot;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								}
								
								//this was the old code (before 2012-03, DMA):
							   #if 0
								#if 1
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								#else
								//DMA: readBlock
								#pragma message Using DMA mode!
								;
								//srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA
								//srack->theFlt[col]->histogramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //PCI burst  w/o libPCIDMA
								#endif
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
							   #endif
							}
						}
						//if FIFO is full this (reading FIFO4) will release the current entry in the FIFO to allow the HW to record the next event -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						FIFO4[col]=f4;
						
						//now ship the buffered data ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3		= FIFO3[col][eventchan];
                                uint32_t pagenr = (f3 >> 24) & 0x3f;
                                uint32_t energy = f3 & 0xfffff;
								uint32_t evsec	= FIFO4[col];//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
       
                                uint32_t waveformLength = 2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
								
                                uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-

                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength32);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                                //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = adctrace32[col][eventchan][i];
                                }
                                
                            }
                        }
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }
        // --- 'ENERGY+TRACE (SYNC)' MODE ------------------------NEW: 2011-01-tb-------   2013-05-29: THIS MODE NOW IS OBSOLETE!! (make all changes manually) -tb-
        else if((daqRunMode == kIpeFltV4_EnergyTraceSyncDaqMode) ){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
        //TODO: else if((daqRunMode == kIpeFltV4_EnergyTraceSyncDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceSyncDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
			// this mode ensures to read out according energy and trace (but will not catch all events at high rates)
			#if 0
            {//TODO: remove debugging output -tb-
			static int firsttimeflag=0;
			if(firsttimeflag<5){fprintf(stdout,"ORFLTv4Readout.cc:   DAQ mode kIpeFltV4_EnergyTraceSyncDaqMode!\n"); fflush(stdout);}
			firsttimeflag++;
			}
			//return true;
			#endif
			
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                //uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){

                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                    if(diff>0){
						//first buffer the data in the FIFO and the ADC pages ...
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        FIFO1[col] =eventFIFO1->read();
                        FIFO2[col] =eventFIFO2->read();
                        f1 = FIFO1[col];
                        f2 = FIFO2[col];
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
						//if in DMA mode we need to leave some time (postTriggerTime) until the ADC trace is written to the FLT RAM
						#if 1
						if(useDmaBlockRead){//we poll the FIFO; typically we detect a event after 200 subsecs (=10 micro sec/usec) (150-250 subsec) (sometimes 1200-4000 subsec=60-200 usec - is Orca busy here?)
						                    //as the HW is still recording the ADC trace (post trigg part with typically 1024 and up to 2048 subsec = 51,2-102,4 usec)
							uint32_t sltsubseccount,sltsubsec1,sltsubsec2,sltsubsec;
							int32_t diffsubsec;
							sltsubseccount   = srack->theSlt->subSecCounter->read();
							sltsubsec1 = sltsubseccount & 0x7ff;
							sltsubsec2 = (sltsubseccount>>11) & 0x3fff;
							sltsubsec   =  sltsubsec2 * 2000 + sltsubsec1;
							diffsubsec = (sltsubsec-evsubsec+20000000) % 20000000;
//							if(evsubsec>sltsubsec) fprintf(stderr,"---==============-------------------==============================_-----------------______________===========================\n");
//							fprintf(stderr,"---  diffsubsec is %i\n",diffsubsec);
//							fprintf(stderr,"---  diffsubsec is %i, post trigg: %i  (  ((0x%08x=%i))  sltsubsec %i, evsubsec %i)\n",diffsubsec,postTriggerTime,sltsubseccount,sltsubseccount,sltsubsec,evsubsec);
//							if(diffsubsec<postTriggerTime) fprintf(stderr,"---=============break\n");
							if(diffsubsec<(int32_t)postTriggerTime) break; //FLT still recording ADC trace -> leave for later for(eventN ...)-loop cycle ... -tb-
						}
						#endif
						
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
						uint32_t traceStart16;//start of trace in short array
                                //if(wfRecordVersion == 0x2){ 
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;  //TODO: take this as standard from FW 2.1.1.4 on -tb-
								//}
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache(); //TODO: we would need this for every channel in the channel mask -> move to FIFO3!!!! -tb-   !!!!!!!!
						
						uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                        //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger - OBSOLETE (I think this never was used ...)
                        wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
						//TODO: I would like to store the version of the readout code <------------------------------------!!!! use new functions "generalRead/Write   -tb-
                        //else: full trigger search (not recommended)

                        uint32_t eventchan, eventchanmask;
						//now start loop to buffer FIFO and the ADC pages ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
								//DEBUG:// for checking the peripheral page counters (debugging) -tb-
								//DEBUG://test page#
                                //DEBUG:uint32_t pageN            = (srack->theFlt[col]->eventFIFO3)->Pbus::read(0x20200c>>2); 
								//DEBUG:debugbuffer[col][eventchan] = pageN;
								//DEBUG:
								FIFO3[col][eventchan] = f3;
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                //uint32_t energy        = f3 & 0xfffff;
//fprintf(stdout,"col:%i, rp: %i wp: %i , chmap: %i pagenr:%i energy: %i \n\r",col+1,readptr,writeptr, chmap,pagenr, energy); fflush(stdout);
//fprintf(stdout,"-----------------------------                                  \n\r"); fflush(stdout);
				
                                //static uint32_t waveformBuffer32[64*1024];
                                //static uint32_t shipWaveformBuffer32[64*1024];
                                //static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                //static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                //uint32_t searchTrig,triggerPos = 0xffffffff;
                                //int32_t appendFlagPos = -1;
                                
                                //Auger Registers Removed for Bipolar Filter Upgrade 2013 -tb-
                                /*      they were actually never used for KATRIN, but will result in Pbus timeouts -tb-
TODO                                */
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                
								//read the raw trace
								if(useDmaBlockRead){
								    //DMA: readBlock
								    //srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								    srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA, memcopy without
								}else{
								    //single access mode
								    //read raw trace (use two loops as otherwise the FLT maybe has not yet written 'postTrigTIme' traces ... then we would read old data - see Elog XXX Florian)
                                    uint32_t adccount, trigSlot;
								    trigSlot = adcoffset/2;
								    for(adccount=trigSlot; adccount<1024;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								    for(adccount=0; adccount<trigSlot;adccount++){
									    adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									    //shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								    }
								}
								
								//this was the old code (before 2012-03, DMA):
							   #if 0
								#if 1
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									adctrace32[col][eventchan][adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
									//shipWaveformBuffer32[adccount]= adctrace32[col][eventchan][adccount]; //TODO: not necessary any more? -tb-
								}
								#else
								//DMA: readBlock
								#pragma message Using DMA mode!
								;
								//srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //memcopy w/o libPCIDMA
								srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //DMA with libPCIDMA
								//srack->theFlt[col]->histogramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024); //PCI burst  w/o libPCIDMA
								#endif
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
							   #endif
							}
						}
						//if FIFO is full this (reading FIFO4) will release the current entry in the FIFO to allow the HW to record the next event -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						FIFO4[col]=f4;
						
						//now ship the buffered data ...
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3		= FIFO3[col][eventchan];
                                uint32_t pagenr = (f3 >> 24) & 0x3f;
                                uint32_t energy = f3 & 0xfffff;
								uint32_t evsec	= FIFO4[col];//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
       
                                uint32_t waveformLength = 2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
								
                                uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-

                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength32);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                                //DEBUG:data[dataIndex++] = debugbuffer[col][eventchan];   //TODO: debug ... energy; for checking page counter I wrote out page counter instead of energy -tb-
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) |  (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = adctrace32[col][eventchan][i];
                                }
                                
                            }
                        }
#if 0
						//f4            = 
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"3x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
						srack->theFlt[col]->eventFIFO4->read(0);
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"4x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
#endif
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }

#if 0 //old ENERGY+TRACE MODE (without waiting until postTriggerTime has elapsed) - commented out 2013-05-29   --> REMOVE IT 2015-05 -tb-
        // --- ENERGY+TRACE MODE ------------------------------
        else if((daqRunMode == kIpeFltV4_EnergyTraceDaqMode) || (daqRunMode == kIpeFltV4_VetoEnergyTraceDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
            //uint32_t status         = srack->theFlt[col]->status->read();
            //uint32_t fifoStatus;// = (status >> 24) & 0xf;
            uint32_t fifoFlags;// =   FF, AF, AE, EF
            uint32_t f1, f2;
            
            //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
            uint32_t eventN;
            for(eventN=0;eventN<10;eventN++){
                hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                eventFIFOStatus->read();//reads to cache
                //uint32_t fifoEmptyFlag = (fifoStatus>>28)&1;//srack->theFlt[col]->eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
                uint32_t fifoAlmostFull = eventFIFOStatus->almostFullFlag->getCache();
                if(!fifoEmptyFlag){

                    
                    //should be something in the fifo, check the read/write pointers and read and package up to 10 events.
                    //uint32_t writeptr = fifoStatus & 0x3ff;      //srack->theFlt[col]->eventFIFOStatus->writePointer->getCache();
                    //uint32_t readptr = (fifoStatus >>16) & 0x3ff;//srack->theFlt[col]->eventFIFOStatus->readPointer->getCache();
                    uint32_t writeptr = eventFIFOStatus->writePointer->getCache();
                    uint32_t readptr  = eventFIFOStatus->readPointer->getCache();
					//{//DEBUGGING CODE
					//	eventFIFOStatus->read();
					//	uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
					//	uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
					//	fprintf(stdout,"0 - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
					//}//DEBUGGING CODE END
                    uint32_t diff = (writeptr-readptr+1024) % 512;
					fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
								(eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
								(eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
								(eventFIFOStatus->emptyFlag->getCache());
                    
                    //depending on 'diff' the loop should start here -tb-
					//TODO: maybe checking 'diff' is not necessary any more? (I used it at the beginning due to bad fifo counter problems) -tb-  2010/11/08
                    
                    if(diff>0){
                        hw4::FltKatrinEventFIFO1 *eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                        hw4::FltKatrinEventFIFO2 *eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                        f1=eventFIFO1->read();
                        f2=eventFIFO2->read();
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						//uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
						uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                        //uint32_t chmap = f1 >> 8;
                        uint32_t chmap = eventFIFO1->channelMap->getCache();
                        uint32_t fifoEventID      = ((f1&0xff)<<4) | (f2>>28);//( (f1 & 0xff) <<5 )  |  (f2 >>28);  //12 bit
                        uint32_t evsec      = f4;//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        //uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                        uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
                                //evsec      = srack->theSlt->secCounter->read();
                        uint32_t precision  = eventFIFO2->timePrecision->getCache();
                        uint32_t sltsubsec;
                        uint32_t sltsec;
                        int32_t timediff2slt;
                        uint32_t eventchan, eventchanmask;
                        for(eventchan=0;eventchan<kNumChan;eventchan++){
                            eventchanmask = (0x1L << eventchan);
                            if((chmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                uint32_t energy        = f3 & 0xfffff;
                                //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: page %i\n",col,eventchan,pagenr);fflush(stdout);
                                uint32_t eventFlags=0;//append page, append next page
                                uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                                uint32_t traceStart16;//start of trace in short array
                                
                                //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger
                                wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                //else: full trigger search (not recommended)
								
                                #if 0
                                //check timing
                                readSltSecSubsec(sltsec,sltsubsec);
                                timediff2slt = (sltsec-evsec)*(int32_t)20000000 + ((int32_t)sltsubsec-(int32_t)evsubsec);//in 50ns units
//fprintf(stdout,"FLT%i>%i,%i<Timediff ev2slttime is %i (sec slt %i  ev %i) (subsec slt %i  ev  %i))   \n\r",col+1,readptr,writeptr,timediff2slt,sltsec,evsec,sltsubsec,evsubsec); fflush(stdout);
//fprintf(stdout,"-----------------------------                                  \n\r"); fflush(stdout);
                                #endif

                                uint32_t waveformLength = 2048; 
                                static uint32_t waveformBuffer32[64*1024];
                                static uint32_t shipWaveformBuffer32[64*1024];
                                static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                uint32_t searchTrig,triggerPos = 0xffffffff;
                                int32_t appendFlagPos = -1;
                                
                                //Auger Registers Removed for Bipolar Filter Upgrade 2013 -tb-
                                /*      they were actually never used for KATRIN, but will result in Pbus timeouts -tb-
                                srack->theSlt->pageSelect->write(0x100 | pagenr);
                                */
                                
								//read raw trace
                                uint32_t adccount, trigSlot;
								trigSlot = adcoffset/2;
								for(adccount=trigSlot; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
								for(adccount=0; adccount<trigSlot;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}
								/* old version; 2010-10-gap-in-trace-bug: PMC was reading too fast, so data was read faster than FLT could write -tb-
								for(adccount=0; adccount<1024;adccount++){
									shipWaveformBuffer32[adccount]= srack->theFlt[col]->ramData->read(eventchan,adccount);
								}*/
                                if(wfRecordVersion == 0x2){
                                    traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;  //TODO: take this as standard from FW 2.1.1.4 on -tb-
								}
                                else if(wfRecordVersion == 0x1){
                                     //search trigger flag (usually in the same or adcoffset+2 bin 2009-12-15)
                                    searchTrig=adcoffset; //+2;
                                    searchTrig = searchTrig & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    searchTrig = (searchTrig+1) & 0x7ff;
                                    if(shipWaveformBuffer16[searchTrig] & 0x08000) triggerPos = searchTrig;
                                    //printf("FLT%i: FOund triggerPos %i , diff> %i<  (adcoffset was %i, searchtrig %i)\n",col+1,triggerPos,triggerPos-adcoffset, adcoffset,searchTrig);
									//printf("FLT%i: FOund triggerPos %i , diff> %i<  \n",col+1,triggerPos,triggerPos-adcoffset);fflush(stdout);
                                    //uint32_t copyindex = (adcoffset + postTriggerTime) % 2048;
#if 0  //TODO: testcode - I will remove it later -tb-
             fprintf(stdout,"triggerPos is %x (%i)  (last search pos %i)\n",triggerPos,triggerPos,searchTrig);fflush(stdout);
             fprintf(stdout,"srack->theFlt[col]->postTrigTime->read() %x \n",srack->theFlt[col]->postTrigTime->read());fflush(stdout);
           if(srack->theFlt[col]->postTrigTime->read() == 0x12c){
           for(adccount=0; adccount<2*1024;adccount++){
                   uint16_t adcval = shipWaveformBuffer16[adccount] & 0xffff;
                        if(adcval & 0xf000){
                         fprintf(stdout,"adcval[%i] has flags %x \n",adccount,adcval);fflush(stdout);
                        }
           }
           }
#endif
                                    traceStart16 = (triggerPos + postTriggerTime ) % 2048;
                                }
                                else {
                                    //search trigger pos
                                    for(adccount=0; adccount<1024;adccount++){
                                        uint32_t adcval = waveformBuffer32[adccount];
                                        #if 1
                                        uint32_t adcval1 = adcval & 0xffff;
                                        uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                        if(adcval1 & 0x8000) triggerPos = adccount*2;
                                        if(adcval2 & 0x8000) triggerPos = adccount*2+1;
                                        if(adcval1 & 0x2000) appendFlagPos = adccount*2;
                                        if(adcval2 & 0x2000) appendFlagPos = adccount*2+1;
                                        #endif
                                    }
                                    //printf("FLT%i:triggerPos %i\n",col+1, triggerPos);
                                    //set append page flag
                                    if(appendFlagPos>=0) eventFlags |= 0x20;
                                    //uint32_t copyindex = (triggerPos + 1024) % 2048; //<- this aligns the trigger in the middle (from Mark)
                                    //uint32_t copyindex = (triggerPos + postTriggerTime) % 2048 ;// this was the workaround without time info -tb-
                                    traceStart16 = (adcoffset + postTriggerTime) % 2048 ;
								}
                                
                                //ship data record
                                ensureDataCanHold(9 + waveformLength/2); 
                                data[dataIndex++] = waveformId | (9 + waveformLength/2);    
                                //printf("FLT%i: waveformId is %i  loc+ev.chan %i\n",col+1,waveformId,  location | eventchan<<8);
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = chmap;
                                data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                                data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                                //data[dataIndex++] = 0;    //spare to remain byte compatible with the v3 record
                                data[dataIndex++] = postTriggerTime /*for debugging -tb-*/   ;    //spare to remain byte compatible with the v3 record
                                
                                //TODO: SHIP TRIGGER POS and POSTTRIGG time !!! -tb-
                                
                                //ship waveform
                                uint32_t waveformLength32=waveformLength/2; //the waveform length is variable    
                                for(uint32_t i=0;i<waveformLength32;i++){
                                    data[dataIndex++] = shipWaveformBuffer32[i];
                                }
                                
                            }
                        }
#if 0
						//f4            = 
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"3x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
						srack->theFlt[col]->eventFIFO4->read(0);
{eventFIFOStatus->read();
uint32_t writeptrx = eventFIFOStatus->writePointer->getCache();
uint32_t readptrx  = eventFIFOStatus->readPointer->getCache();
fprintf(stdout,"4x - readpr:%i, writeptr:%i\n",readptrx,writeptrx);fflush(stdout);
}
#endif
                    }
                }//if(!fifoEmptyFlag)...
                else break;//fifo is empty, leave loop ...
            }//for(eventN=0; ...
        }
#endif
        // --- HISTOGRAM MODE ------------------------------
        else if(fltRunMode == kIpeFltV4Katrin_Histo_Mode) {    //then fltRunMode == kIpeFltV4Katrin_Histo_Mode
                // buffer some data:
                hw4::FltKatrin *currentFlt = srack->theFlt[col];
                //hw4::SltKatrin *currentSlt = srack->theSlt;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);    
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout); 
                //sleep(1);   
                if(runFlags & kFirstTimeFlag){// firstTime   
                    //make some plausability checks
                    currentFlt->histogramSettings->read();//read to cache
                    if(currentFlt->histogramSettings->histModeStopUncleared->getCache() ||
                       currentFlt->histogramSettings->histClearModeManual->getCache()){
                        fprintf(stdout,"ORFLTv4Readout.cc: WARNING: histogram readout is designed for continous and auto-clear mode only! Change your FLTv4 settings!\n");
                        fflush(stdout);
                    }
                    //store some static data which is constant during run
                    histoBinWidth       = currentFlt->histogramSettings->histEBin->getCache();
                    histoEnergyOffset   = currentFlt->histogramSettings->histEMin->getCache();
                    histoRefreshTime    = currentFlt->histMeasTime->read();
					histoShipSumHistogram = runFlags & kShipSumHistogramFlag;

					//clear the buffers for the sum histogram
					ClearSumHistogramBuffer();
				
					//set page manager to automatic mode
					//srack->theSlt->pageSelect->write(0x100 | 3); //TODO: this flips the two parts of the histogram - FPGA bug? -tb-
                                //Auger Registers Removed for Bipolar Filter Upgrade 2013 -tb-
                                /*      they were actually never used for KATRIN, but will result in Pbus timeouts -tb-
TODO                                */
					            srack->theSlt->pageSelect->write((long unsigned int)0x0);
                    //reset histogram time counters (=histRecTime=refresh time -tb-) //TODO: unfortunately there is no such command for the histogramming -tb- 2010-07-28
                    //TODO: srack->theFlt[col]->command->resetPointers->write(1);
                    //clear histogram (probably not really necessary with "automatic clear" -tb-) 
                    srack->theFlt[col]->command->resetPages->write(1);
                    //init page AB flag
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    GetDeviceSpecificData()[3]=pageAB;// runFlags is GetDeviceSpecificData()[3], so this clears the 'first time' flag -tb-
					//TODO: better use a local static variable and init it the first time, as changing GetDeviceSpecificData()[3] could be dangerous -tb-
                    //debug: fprintf(stdout,"FLT %i: first cycle\n",col+1);fflush(stdout);
                    //debug: //sleep(1);
                }
                else{//check timing
                    //pagenr=srack->theFlt[col]->histNofMeas->read() & 0x3f;
                    //srack->theFlt[col]->periphStatus->readBlock((long unsigned int*)pStatus);//TODO: fdhwlib will change to uint32_t in the future -tb-
                    //pageAB = (pStatus[0] & 0x10) >> 4;
                    oldpageAB = GetDeviceSpecificData()[3]; //
                    //pageAB = (srack->theFlt[col]->periphStatus->read(0) & 0x10) >> 4;
                    //pageAB = srack->theFlt[col]->periphStatus->histPageAB->read(0);
                    pageAB = srack->theFlt[col]->status->histPageAB->read();
                    //fprintf(stdout,"FLT %i: oldpage  %i currpagenr %i\n",col+1, oldpagenr, pagenr  );fflush(stdout);  
                    //              sleep(1);
                    
                    if(oldpageAB != pageAB){
                        //debug: fprintf(stdout,"FLT %i:toggle now from %i to page %i\n",col+1, oldpageAB, pageAB  );fflush(stdout);    
                        GetDeviceSpecificData()[3] = pageAB; 
                        //read data
                        uint32_t chan=0;
                        uint32_t readoutSec;
                        unsigned long totalLength;
                        uint32_t last,first;
                        uint32_t fpgaHistogramID;
                        static uint32_t shipHistogramBuffer32[2048];
                        fpgaHistogramID     = currentFlt->histNofMeas->read();
                        // CHANNEL LOOP ----------------
                        for(chan=0;chan<kNumChan;chan++) {//read out histogram
                            if( !(triggerEnabledMask & (0x1L << chan)) ) continue; //skip channels with disabled trigger
                            currentFlt->histLastFirst->read(chan);//read to cache ...
                            //last = (lastFirst >>16) & 0xffff;
                            //first = lastFirst & 0xffff;
                            last  = currentFlt->histLastFirst->histLastEntry->getCache(chan);
                            first = currentFlt->histLastFirst->histFirstEntry->getCache(chan);
                            //debug: fprintf(stdout,"FLT %i: ch %i:first %i, last %i \n",col+1,chan,first,last);fflush(stdout);
                            
                            #if 1  //READ OUT HISTOGRAM -tb- -------------
							{
								//read sec
								readoutSec=currentFlt->secondCounter->read();
                                //prepare data record
                                katrinV4HistogramDataStruct theEventData;
                                theEventData.readoutSec = readoutSec;
                                theEventData.refreshTimeSec =  histoRefreshTime;//histoRunTime;   
								
								//read out histogram
								if(last<first){
									//no events, write out empty histogram -tb-
									theEventData.firstBin  = 2047;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 0;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =0;
								}
								else{
									//read histogram block
									srack->theFlt[col]->histogramData->readBlockAutoInc(chan,  (long unsigned int*)shipHistogramBuffer32, 0, 2048);
									theEventData.firstBin  = 0;//histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
									theEventData.lastBin   = 2047;//histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
									theEventData.histogramLength =2048;
								}
							
                                //theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
                                //if(theEventData.histogramLength < 0){// we had no counts ...
                                //    theEventData.histogramLength = 0;
                                //}
                                theEventData.maxHistogramLength = 2048; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
                                theEventData.binSize    = histoBinWidth;        
                                theEventData.offsetEMin = histoEnergyOffset;
                                theEventData.histogramID    = fpgaHistogramID;
                                theEventData.histogramInfo  = pageAB & 0x1;//one bit
                                
                                //ship data record
                                totalLength = 2 + (sizeof(katrinV4HistogramDataStruct)/sizeof(uint32_t)) + theEventData.histogramLength;// 2 = header + locationWord
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
										data[dataIndex++] = shipHistogramBuffer32[i];
								}
								//debug: fprintf(stdout," Shipping histogram with ID %i\n",histogramID);     fflush(stdout);  
								
								//add histogram to sum histogram
								if( histoShipSumHistogram & kShipSumHistogramFlag ){
									recordingTimeSum[chan] += theEventData.refreshTimeSec;
									if(theEventData.histogramLength>0){//don't fill in empty histograms
										for(i=0; i<theEventData.histogramLength;i++){//TODO: need to use firstBin...lastBin for parts of histograms -tb-
											sumHistogram[chan][i] += shipHistogramBuffer32[i];
										}
									}
								}
                            }
                            #endif
                            
                        }
                    } 
                }
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
		//uint32_t daqRunMode = GetDeviceSpecificData()[5];
		//data to ship
		uint32_t chan=0;
		uint32_t readoutSec;
		unsigned long totalLength=kMaxHistoLength;
		//uint32_t last=kMaxHistoLength-1,first=0;
		//uint32_t fpgaHistogramID;
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
				totalLength = 2 + (sizeof(katrinV4HistogramDataStruct)/sizeof(uint32_t)) + theEventData.histogramLength;// 2 = header + locationWord
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
    //static long int counter=0;
    static long int secCounter=0;
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
        printf("PrPMC (FLTv4 simulation mode) sec %ld: 1 sec is over ...\n",secCounter);
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
