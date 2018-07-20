#include "ORFLTv4Readout.hh"
#include "KatrinV4_HW_Definitions.h"

#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#include <sys/time.h> // for gettimeofday on MAC OSX -tb-

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif

//init static members and globals
uint32_t histoShipSumHistogram = 0;
uint32_t histoShipSumOnly = 0;



#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------

extern hw4::SubrackKatrin* srack; 

bool ORFLTv4Readout::Start() {
    firstTime = true;
    return true;
    
    runEndSec = 0;
    
    // Histogram - clear buffers !!!
    // Read histogramm parameters here !!!
    
}

bool ORFLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t col                    = GetSlot() - 1;
    uint32_t daqRunMode             = GetDeviceSpecificData()[5];
    uint32_t versionCFPGA           = GetDeviceSpecificData()[7];
    uint32_t versionFPGA8           = GetDeviceSpecificData()[8];

    if ((versionCFPGA>0x20010300 ) && (versionFPGA8>0x20010300) ){
        //===================================================================================================================
        // 2013-11-14 bipolar energy update - changes in SLT registers (for versionCFPGA  >= 0x20010300  &&  versionFPGA8 >= 0x20010300) -tb-
        //===================================================================================================================
        if(srack->theFlt[col]->isPresent()){
            
            ////////////////////////////////////////////////////
            //READOUT MODES (energy, energy+trace, histogram)
            ////////////////////////////////////////////////////
            
            // --- ENERGY MODE ------------------------------
            if((daqRunMode == kKatrinV4Flt_EnergyDaqMode)       ||
               (daqRunMode == kKatrinV4Flt_VetoEnergyDaqMode)   ||
               (daqRunMode == kKatrinV4Flt_BipolarEnergyDaqMode)   ){
                
                ReadoutEnergyV31(lamData);
                
            }
            // --- 'ENERGY+TRACE' MODE -------------------------tb-------   2013-05-29: THIS MODE NOW replaces 'ENERGY+TRACE' and 'ENERGY+TRACE (SYNC)'!!-tb-
            else if((daqRunMode == kKatrinV4Flt_EnergyTraceDaqMode)     ||
                    (daqRunMode == kKatrinV4Flt_VetoEnergyTraceDaqMode) ||
                    (daqRunMode == kKatrinV4Flt_BipolarEnergyTraceDaqMode)){
 
                ReadoutTraceV31(lamData);
 
            }
  
            // --- HISTOGRAM MODE ------------------------------
            else if(daqRunMode == kKatrinV4Flt_Histogram_DaqMode) {
                
                ReadoutHistogramV31(lamData);
          
            }
                
        }
        
    } else {
        
        ReadoutLegacy(lamData);
        
    }
    return true;
}

bool ORFLTv4Readout::Stop()
{

    // Energy mode - nothing to do
    
    // Trace mode - nothing to do

    
    //
    // Histogram mode - ship the sum histogram
    //
    
    uint32_t daqRunMode         = GetDeviceSpecificData()[5];
    if(daqRunMode == kKatrinV4Flt_Histogram_DaqMode){

        
        //
        // Readout active page if necessary
        //
        uint32_t crate                  = GetCrate();
        uint32_t col                    = GetSlot() - 1;
        
        //uint32_t runFlags               = GetDeviceSpecificData()[3];  //this is runFlagsMask of ORKatrinV4FLTModel.m,
        
        uint32_t triggerEnabledMask     = GetDeviceSpecificData()[4];
        uint32_t filterShapingLength    = GetDeviceSpecificData()[9];       //TODO: need to change in the code below! -tb-
        uint32_t boxcarLen              = GetDeviceSpecificData()[11];
        
        uint32_t histogramId            = GetHardwareMask()[2];
        
        uint32_t location   =   ((crate     & 0x0000001e)<<21) |
        (((col+1)   & 0x0000001f)<<16) |
        ((boxcarLen & 0x00000003)<<4)  |
        (filterShapingLength & 0xf);  //TODO:  remove filterIndex (remove in decoders, too!) -tb-
        
        uint32_t tRec;
        uint32_t histoRefreshTime;
        uint32_t fpgaHistogramID;
        uint32_t pageAB;
        uint32_t histoBuffer[2048];
        uint32_t *ptrHistoBuffer;
        
        
        histoRefreshTime    = srack->theFlt[col]->histMeasTime->read();
        tRec = srack->theFlt[col]->histRecTime->read();
        
        // Check if all histogram have been read for this second!
        runEndSec = srack->theFlt[col]->secondCounter->read();
        
        //printf("Rec time %d / %d sec \n", tRec, histoRefreshTime);
        
        if ((tRec > 0) || (histoReadoutSec < runEndSec)) {
        
            pageAB    = srack->theFlt[col]->status->histPageAB->read();
            if (tRec == 0) {
                printf("Warning: Detected missing histogram at the end of the run - will read it now!\n");
                // But we need to read the other page !!!
                pageAB = (pageAB+1)%2;
                // Do we need a sleep for safety?!
            }
            
            fpgaHistogramID = srack->theFlt[col]->histNofMeas->read();
            histoReadoutSec  = srack->theFlt[col]->secondCounter->read();

            for(int chan=0;chan<kNumChan;chan++) {
                if((triggerEnabledMask & (0x1L << chan)) ){
                    //currentFlt->histLastFirst->read(chan);  //read to cache ... Must do!!!
                    //uint32_t first       = currentFlt->histLastFirst->histFirstEntry->getCache(chan);
                    // uint32_t last        = currentFlt->histLastFirst->histLastEntry->getCache(chan);
                    
                    if( !histoShipSumOnly ){
                        
                        uint32_t totalLength = 12 + 2048;
                        ensureDataCanHold(totalLength);
                        data[dataIndex++] = histogramId | totalLength;
                        data[dataIndex++] = location | chan<<8;
                        data[dataIndex++] = histoReadoutSec - tRec;
                        data[dataIndex++] = tRec;
                        data[dataIndex++] = 0;                  //first bin
                        data[dataIndex++] = 2047;               //last bin
                        data[dataIndex++] = 2048;               //histo len
                        data[dataIndex++] = 2048;               //max histo len
                        data[dataIndex++] = histoBinWidth;
                        data[dataIndex++] = histoEnergyOffset;
                        data[dataIndex++] = fpgaHistogramID;    //from HW
                        data[dataIndex++] = pageAB & 0x1;

                        // Select page before readout
                        srack->theSlt->pageSelect->write(0x100 | (pageAB << 1));
                        
                        ptrHistoBuffer = (uint32_t *) &data[dataIndex];
                        srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*) ptrHistoBuffer, 0, 2048);
                        dataIndex += 2048;
                        
                    } else {
                        srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*) histoBuffer, 0, 2048);
                        ptrHistoBuffer = histoBuffer;
                        
                    }

                    //printf("%d: t %d histogram counts %lld final\n", histoReadoutSec, tRec, Counts(ptrHistoBuffer));

                    
                    // Add histogram to sum histogram
                    if( histoShipSumHistogram || histoShipSumOnly ){
                        recordingTimeSum[chan] += histoRefreshTime;
                        for(int i=0; i<2048;i++){//TODO: need to use firstBin...lastBin for parts of histograms -tb-
                            sumHistogram[chan][i] += ptrHistoBuffer[i];
                        }
                    }

                }
        
            }
        }
        
        
        //
        // Ship sum histogram
        //
        if (histoShipSumHistogram || histoShipSumOnly ){
            
            uint32_t crate                  = GetCrate();
            uint32_t col                    = GetSlot() - 1;
            
            // Todo: Use the run flags tofind out if automatic clear is deactivated?
            //       In this case the sum histogram can be read from hardware at the end of the run !! -ak-
            
            //uint32_t runFlags               = GetDeviceSpecificData()[3];  //this is runFlagsMask of ORKatrinV4FLTModel.m,
        
            uint32_t triggerEnabledMask     = GetDeviceSpecificData()[4];
            uint32_t filterShapingLength    = GetDeviceSpecificData()[9];       //TODO: need to change in the code below! -tb-
            uint32_t boxcarLen              = GetDeviceSpecificData()[11];
            
            uint32_t histogramId            = GetHardwareMask()[2];
            
            uint32_t location   =   ((crate     & 0x0000001e)<<21) |
            (((col+1)   & 0x0000001f)<<16) |
            ((boxcarLen & 0x00000003)<<4)  |
            (filterShapingLength & 0xf);  //TODO:  remove filterIndex (remove in decoders, too!) -tb-

            
            srack->theSlt->pageSelect->write((long unsigned int)0x0); //flip the page so we get the last bit of data
            
            uint32_t chan;
            for(chan=0; chan < kNumChan ; chan++) {
                if((triggerEnabledMask & (0x1L << chan)) ){
                    unsigned long totalLength = 12 + 2048;
                    ensureDataCanHold(totalLength);
                    data[dataIndex++] = histogramId | totalLength;
                    data[dataIndex++] = location | chan<<8;
                    data[dataIndex++] = histoReadoutSec - recordingTimeSum[chan];
                    data[dataIndex++] = recordingTimeSum[chan];
                    data[dataIndex++] = 0;                  //first bin
                    data[dataIndex++] = 2047;               //last bin
                    data[dataIndex++] = 2048;               //histo len
                    data[dataIndex++] = 2048;               //max histo len
                    data[dataIndex++] = histoBinWidth;
                    data[dataIndex++] = histoEnergyOffset;
                    data[dataIndex++] = (col+1)*100+chan;   //histo 'tag' number
                    data[dataIndex++] = 0x2;                //a 'sum' histo
                    for (int i=0; i<2048; i++)
                        data[dataIndex++] = sumHistogram[chan][i];
                }
            }
        }
		
	}
	
	return true;
}


bool ORFLTv4Readout::ReadoutEnergyV31(SBC_LAM_Data*){

    uint32_t crate                  = GetCrate();
    uint32_t col                    = GetSlot() - 1;

    uint32_t fltRunMode             = GetDeviceSpecificData()[2];
    uint32_t runFlags               = GetDeviceSpecificData()[3];  //this is runFlagsMask of ORKatrinV4FLTModel.m,
    uint32_t triggerEnabledMask     = GetDeviceSpecificData()[4];
    uint32_t filterShapingLength    = GetDeviceSpecificData()[9];       //TODO: need to change in the code below! -tb-
    uint32_t boxcarLen              = GetDeviceSpecificData()[11];
    
    uint32_t dataId                 = GetHardwareMask()[0];             //this is energy record
    
    uint32_t forceFltReadoutFlag    = runFlags & kForceFltReadoutFlag;  //kForceFltReadoutFlag is 0x200000
    uint32_t location   =   ((crate     & 0x0000001e)<<21) |
                            (((col+1)   & 0x0000001f)<<16) |
                            ((boxcarLen & 0x00000003)<<4)  |
                            (filterShapingLength & 0xf);  //TODO:  remove filterIndex (remove in decoders, too!) -tb-

    
    if (forceFltReadoutFlag==kForceFltReadoutFlag) {
        
        hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = srack->theFlt[col]->eventFIFOStatus;
        eventFIFOStatus->read();//reads once..important!!! Other calls below get values from this read using a cache.
        uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
        //MAH 6/29/17 removed a 0 - 10 loop here.. found the speed was the same because the loop is already implicit in the readout loop. code is simpler this way
        if(!fifoEmptyFlag){
            uint32_t readptr   = eventFIFOStatus->readPointer->getCache();
            uint32_t fifoFlags = (eventFIFOStatus->fullFlag->getCache()			<< 3) |
            (eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
            (eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
            (eventFIFOStatus->emptyFlag->getCache());
            
            hw4::FltKatrinEventFIFO1* eventFIFO1 = srack->theFlt[col]->eventFIFO1;
            hw4::FltKatrinEventFIFO2* eventFIFO2 = srack->theFlt[col]->eventFIFO2;
            uint32_t f1          = eventFIFO1->read();
            uint32_t f2          = eventFIFO2->read();
            uint32_t eventSec    = srack->theFlt[col]->eventFIFO4->read(0);
            uint32_t channelmap  = eventFIFO1->channelMap->getCache();
            uint32_t fifoEventID = ((f1&0xff)<<4) | (f2>>28);
            uint32_t eventSubsec = eventFIFO2->subSec->getCache();
            uint32_t precision   = eventFIFO2->timePrecision->getCache();
            uint32_t eventchan;
            for(eventchan=0;eventchan<kNumChan;eventchan++){
                uint32_t eventchanmask = (0x1L << eventchan);
                if((channelmap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                    uint32_t f3        = srack->theFlt[col]->eventFIFO3->read(eventchan);
                    uint32_t pagenr    = (f3 >> 24) & 0x3f;
                    uint32_t energy    = f3 & 0xfffff;
                    
                    ensureDataCanHold(7);
                    data[dataIndex++] = dataId   | 7;
                    data[dataIndex++] = location | eventchan<<8;
                    data[dataIndex++] = eventSec;
                    data[dataIndex++] = eventSubsec;
                    data[dataIndex++] = channelmap;
                    data[dataIndex++] = (readptr      & 0x3ff)        |
                    ((pagenr      & 0x03f) << 10) |
                    ((precision   & 0x003) << 16) |
                    ((fifoFlags   & 0x00f) << 20) |
                    ((fltRunMode  & 0x00f) << 24);
                    data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                }
            }
        }
    }
    
    return true;
}


bool ORFLTv4Readout::ReadoutTraceV31(SBC_LAM_Data*){

    uint32_t crate                  = GetCrate();
    uint32_t col                    = GetSlot() - 1;

    uint32_t postTriggerTime        = GetDeviceSpecificData()[0];
    uint32_t fltRunMode             = GetDeviceSpecificData()[2];
    uint32_t triggerEnabledMask     = GetDeviceSpecificData()[4];
    uint32_t filterShapingLength    = GetDeviceSpecificData()[9];       //TODO: need to change in the code below! -tb-
    uint32_t boxcarLen              = GetDeviceSpecificData()[11];
    
    uint32_t waveformId             = GetHardwareMask()[1];

    uint32_t location   =   ((crate     & 0x0000001e)<<21) |
                            (((col+1)   & 0x0000001f)<<16) |
                            ((boxcarLen & 0x00000003)<<4)  |
                            (filterShapingLength & 0xf);  //TODO:  remove filterIndex (remove in decoders, too!) -tb-
    
    
    hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = srack->theFlt[col]->eventFIFOStatus;
    eventFIFOStatus->read();//reads once..important!!! Other calls below get values from this read using a cache.
    uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
    if(!fifoEmptyFlag){
        
        uint32_t readptr   = eventFIFOStatus->readPointer->getCache();
        uint32_t fifoFlags = (eventFIFOStatus->fullFlag->getCache()        << 3) |
        (eventFIFOStatus->almostFullFlag->getCache()  << 2) |
        (eventFIFOStatus->almostEmptyFlag->getCache() << 1) |
        (eventFIFOStatus->emptyFlag->getCache());
        
        hw4::FltKatrinEventFIFO1* eventFIFO1 = srack->theFlt[col]->eventFIFO1;
        hw4::FltKatrinEventFIFO2* eventFIFO2 = srack->theFlt[col]->eventFIFO2;
        uint32_t f1                 = eventFIFO1->read();
        uint32_t f2                 = eventFIFO2->read();
        
        uint32_t eventSec           = srack->theFlt[col]->eventFIFO4->read(0);
        uint32_t channelMap         = eventFIFO1->channelMap->getCache();
        uint32_t fifoEventID        = ((f1&0xff)<<4) | (f2>>28);
        uint32_t eventSubsec        = eventFIFO2->subSec->getCache();
        uint32_t adcoffset          = eventSubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)
        uint32_t traceStart16       = (adcoffset + postTriggerTime) % 2048;   //TODO: take this as standard from FW 2.1.1.4 on -tb-
        uint32_t precision          = eventFIFO2->timePrecision->getCache();
        uint32_t waveformLength     = 2048;               //in shorts
        uint32_t waveformLength32   = waveformLength/2;   //in longs
        uint32_t wfRecordVersion    = 0x2;
        uint32_t eventchan;
        for(eventchan=0;eventchan<kNumChan;eventchan++){
            uint32_t eventchanmask = (0x1L << eventchan);
            if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                uint32_t f3     = srack->theFlt[col]->eventFIFO3->read(eventchan);
                uint32_t pagenr = (f3 >> 24) & 0x3f;
                uint32_t energy = f3 & 0xfffff;
                
                ensureDataCanHold(9 + waveformLength/2);
                data[dataIndex++] = waveformId | (9 + waveformLength32);
                data[dataIndex++] = location   | eventchan<<8;
                data[dataIndex++] = eventSec;
                data[dataIndex++] = eventSubsec;
                data[dataIndex++] = channelMap;
                data[dataIndex++] = (readptr     & 0x3ff)       |
                ((pagenr     & 0x03f)<<10)  |
                ((precision  & 0x003)<<16)  |
                ((fifoFlags  & 0x00f)<<20)  |
                ((fltRunMode & 0x00f)<<24);
                data[dataIndex++] = ((fifoEventID  & 0xfff) << 20) | energy;
                data[dataIndex++] = ((traceStart16 & 0x7ff) << 8)  | (wfRecordVersion & 0xf);
                data[dataIndex++] = 0; //spare
                
                // Todo: Remove this sleep !!!
                //if (postTriggerTime > 1024)
                 //   usleep(50); // only for test purpose !!!
                
                //select the page and dma the waveform into the data buffer ... should have a safety check here in case need to dump record
                srack->theSlt->pageSelect->write(0x100 | pagenr);
                
                
                // Warning: This command does only work in DMA block readout and
                //          will fail, if the command is splitt in a sequence of single
                //          read operations !!!
                
                srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)&data[dataIndex],(traceStart16/2)%1024,1024);
                dataIndex+=1024;
            }
        }
        
    }

    return true;
    
}


bool ORFLTv4Readout::ReadoutHistogramV31(SBC_LAM_Data*){
    
    uint32_t crate                  = GetCrate();
    uint32_t col                    = GetSlot() - 1;
    
    uint32_t runFlags               = GetDeviceSpecificData()[3];  //this is runFlagsMask of ORKatrinV4FLTModel.m,
    uint32_t triggerEnabledMask     = GetDeviceSpecificData()[4];
    uint32_t filterShapingLength    = GetDeviceSpecificData()[9];       //TODO: need to change in the code below! -tb-
    uint32_t boxcarLen              = GetDeviceSpecificData()[11];
    
    uint32_t histogramId            = GetHardwareMask()[2];
    
    uint32_t location   =   ((crate     & 0x0000001e)<<21) |
                            (((col+1)   & 0x0000001f)<<16) |
                            ((boxcarLen & 0x00000003)<<4)  |
                            (filterShapingLength & 0xf);  //TODO:  remove filterIndex (remove in decoders, too!) -tb-
    
    uint32_t  histoBuffer[2048];
    uint32_t  *ptrHistoBuffer;
    uint32_t  pageReadout;
    
    hw4::FltKatrin *currentFlt = srack->theFlt[col];
    //if(runFlags && firstTime){// firstTime
    
    // Move to start procedure !!!
    
    if(firstTime){// firstTime
        firstTime = false;
        currentFlt->histogramSettings->read();//read to cache

        histoBinWidth       = currentFlt->histogramSettings->histEBin->getCache();
        histoEnergyOffset   = currentFlt->histogramSettings->histEMin->getCache();
        histoClearByUser    = currentFlt->histogramSettings->histClearModeManual->getCache();
        histoRefreshTime    = currentFlt->histMeasTime->read();
        histoShipSumHistogram = runFlags & kShipSumHistogramFlag;
        histoShipSumOnly    = runFlags & kShipSumOnlyHistogramFlag;
        
        //clear the buffers for the sum histogram
        ClearSumHistogramBuffer();
        
        
        pageAB    = srack->theFlt[col]->status->histPageAB->read();
        oldPageAB = pageAB;
  
        // Clear page - might not be necessary when starting with reset ?!
        if (histoClearByUser) {
            pageReadout = ((pageAB+1)%2) *2;
            srack->theSlt->pageSelect->write(0x100 | pageReadout);
            srack->theFlt[col]->command->resetPages->write(1);
        }
        
    }
    
    else {
        pageAB = srack->theFlt[col]->status->histPageAB->read();
        
        if(oldPageAB != pageAB){
            oldPageAB = pageAB;
            
            uint32_t fpgaHistogramID = currentFlt->histNofMeas->read();
            histoReadoutSec  = currentFlt->secondCounter->read();

            
            for(int chan=0;chan<kNumChan;chan++) {
                if((triggerEnabledMask & (0x1L << chan)) ){
                    //currentFlt->histLastFirst->read(chan);  //read to cache ... Must do!!!
                    //uint32_t first       = currentFlt->histLastFirst->histFirstEntry->getCache(chan);
                    // uint32_t last        = currentFlt->histLastFirst->histLastEntry->getCache(chan);

                    // Select readout page
                    pageReadout = ((pageAB+1)%2);
                    srack->theSlt->pageSelect->write(0x100 | (pageReadout << 1));
                    
                    if( !histoShipSumOnly ){
                        
                        uint32_t totalLength = 12 + 2048;
                        ensureDataCanHold(totalLength);
                        data[dataIndex++] = histogramId | totalLength;
                        data[dataIndex++] = location | chan<<8;
                        data[dataIndex++] = histoReadoutSec - histoRefreshTime;
                        data[dataIndex++] = histoRefreshTime;
                        data[dataIndex++] = 0;                  //first bin
                        data[dataIndex++] = 2047;               //last bin
                        data[dataIndex++] = 2048;               //histo len
                        data[dataIndex++] = 2048;               //max histo len
                        data[dataIndex++] = histoBinWidth;
                        data[dataIndex++] = histoEnergyOffset;
                        data[dataIndex++] = fpgaHistogramID;    //from HW
                        data[dataIndex++] = pageReadout;
                        ptrHistoBuffer = (uint32_t *) &data[dataIndex];
                            
                        srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*) ptrHistoBuffer, 0, 2048);
                        dataIndex += 2048;
                        
                    } else {
                        srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*) histoBuffer, 0, 2048);
                        ptrHistoBuffer = histoBuffer;
                        
                    }
                    
                    //printf("%d: t %d histogram id %d counts %lld\n", histoReadoutSec,
                    //      histoRefreshTime, fpgaHistogramID, Counts(ptrHistoBuffer));
                    
                    
                    // Clear the current page after readout
                    if (histoClearByUser) srack->theFlt[col]->command->resetPages->write(1);
                    
                    
                    // Add histogram to sum histogram
                    if( histoShipSumHistogram || histoShipSumOnly ){
                        recordingTimeSum[chan] += histoRefreshTime;
                        for(int i=0; i<2048;i++){//TODO: need to use firstBin...lastBin for parts of histograms -tb-
                            sumHistogram[chan][i] += ptrHistoBuffer[i];
                        }
                    }
                    
/*
                    // Check for readout errors
                    uint32_t histogram2[2048];
                    int diff;
                    
                    usleep(100);
                    srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*) histogram2, 0, 2048);
                    
                    diff = 0;
                    for (int i=0;i<2048;i++){
                        diff = histogram2[i] - ptrHistoBuffer[i];
                    }
                    printf("%d - Histogram readback diff = %d\n", histoReadoutSec - histoRefreshTime, diff);
*/

                }
            }
            
            
        }

    
    }

    return true;
    
}


unsigned long long ORFLTv4Readout::Counts(uint32_t *histogram)
{
    int i;
    unsigned long long sum;

    sum = 0;
    for (i=0;i<2048;i++)
        sum = sum + histogram[i];
    
    return(sum);
}


bool ORFLTv4Readout::ReadoutLegacy(SBC_LAM_Data* lamData)
{
    
#define kNumV4FLTs               20
#define kNumV4FLTChannels        24
#define kNumV4FLTADCPageSize16 2048
#define kNumV4FLTADCPageSize32 1024
    
    static uint32_t adctrace32[kNumV4FLTs][kNumV4FLTChannels][kNumV4FLTADCPageSize32];//shall I use a 4th index for the page number? -tb-
    //if sizeof(long unsigned int) != sizeof(uint32_t) we will come into troubles (64-bit-machines?) ... -tb-
    static uint32_t FIFO1[kNumV4FLTs];
    static uint32_t FIFO2[kNumV4FLTs];
    static uint32_t FIFO3[kNumV4FLTs][kNumV4FLTChannels];
    static uint32_t FIFO4[kNumV4FLTs];
    
    //this data must be constant during a run
    static uint32_t histoBinWidth       = 0;
    static uint32_t histoEnergyOffset   = 0;
    static uint32_t histoRefreshTime    = 0;
    
    //
    uint32_t dataId                 = GetHardwareMask()[0];             //this is energy record
    uint32_t waveformId             = GetHardwareMask()[1];
    uint32_t histogramId            = GetHardwareMask()[2];
    uint32_t col                    = GetSlot() - 1;                    //GetSlot() is in fact stationNumber, which goes from 1 to 24 (slots go from 0-9, 11-20)
    uint32_t crate                  = GetCrate();
    
    uint32_t postTriggerTime        = GetDeviceSpecificData()[0];
    //uint32_t eventType            = GetDeviceSpecificData()[1];
    uint32_t fltRunMode             = GetDeviceSpecificData()[2];
    uint32_t runFlags               = GetDeviceSpecificData()[3];       //this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:
    
    uint32_t triggerEnabledMask     = GetDeviceSpecificData()[4];
    uint32_t daqRunMode             = GetDeviceSpecificData()[5];
    //uint32_t filterIndex          = GetDeviceSpecificData()[6]; obsolete, changed 2012-11 -tb-
    uint32_t versionCFPGA           = GetDeviceSpecificData()[7];
    uint32_t versionFPGA8           = GetDeviceSpecificData()[8];
    uint32_t filterShapingLength    = GetDeviceSpecificData()[9];       //TODO: need to change in the code below! -tb- 2011-04-01
    uint32_t useDmaBlockReadSetting = GetDeviceSpecificData()[10];      //TODO: need to change in the code below! -tb- 2011-04-01
    uint32_t boxcarLen = GetDeviceSpecificData()[11];
    
    
    
    uint32_t useDmaBlockRead = 1; //if linked with DMA lib, force DMA mode -tb-
    if(useDmaBlockReadSetting){//0=auto detect, 1=yes, 2=no
        if(useDmaBlockReadSetting==2) useDmaBlockRead = 0;
    }
    else {//auto detect
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
    
    
    
    uint32_t location   =   ((crate     & 0x0000001e)<<21) |
    (((col+1)   & 0x0000001f)<<16) |
    ((boxcarLen & 0x00000003)<<4)  |
    (filterShapingLength & 0xf);  //TODO:  remove filterIndex (remove in decoders, too!) -tb-
    
    //for backward compatibility (before FLT versions2.1.1.4); shall be removed Jan. 2011 -tb-
    //===========================================================================================
    if((versionCFPGA>0x20010100 && versionCFPGA<0x20010104) || (versionFPGA8>0x20010100  && versionFPGA8<0x20010104) ){
        //this is for FPGA config. before FIFO redesign and 'sync' mode -tb-
        if(srack->theFlt[col]->isPresent()){
            
            
            
            //READOUT MODES (energy, energy+trace, histogram)
            ////////////////////////////////////////////////////
            
            
            // --- ENERGY MODE ------------------------------
            if((daqRunMode == kKatrinV4Flt_EnergyDaqMode) || (daqRunMode == kKatrinV4Flt_VetoEnergyDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
                //uint32_t status         = srack->theFlt[col]->status->read();
                //uint32_t fifoStatus;// = (status >> 24) & 0xf;
                uint32_t fifoFlags;// =   FF, AF, AE, EF
                
                //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                    //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                    //fifoStatus = eventFIFOStatus->read();//reads to cache
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
                            //uint32_t channelMap = f1 >> 8;
                            uint32_t channelMap = eventFIFO1->channelMap->getCache();
                            uint32_t evsec      = (eventFIFO1->sec12downto5->getCache()<<5) | (eventFIFO2->sec4downto0->getCache());//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                            uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                            //evsubsec   = srack->theSlt->subSecCounter->read();
                            //evsec      = srack->theSlt->secCounter->read();
                            uint32_t precision  = eventFIFO2->timePrecision->getCache();
                            uint32_t eventchan, eventchanmask;
                            for(eventchan=0;eventchan<kNumChan;eventchan++){
                                eventchanmask = (0x1L << eventchan);
                                if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                    uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                    uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                    uint32_t pagenr        = f3 & 0x3f;
                                    uint32_t energy        = f4 ;
                                    
                                    ensureDataCanHold(7);
                                    data[dataIndex++] = dataId | 7;
                                    data[dataIndex++] = location | eventchan<<8;
                                    data[dataIndex++] = evsec;        //sec
                                    data[dataIndex++] = evsubsec;     //subsec
                                    data[dataIndex++] = channelMap;
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
            else if((daqRunMode == kKatrinV4Flt_EnergyTraceDaqMode) || (daqRunMode == kKatrinV4Flt_VetoEnergyTraceDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
                //uint32_t status         = srack->theFlt[col]->status->read();
                //uint32_t fifoStatus;// = (status >> 24) & 0xf;
                uint32_t fifoFlags;// =   FF, AF, AE, EF
                
                //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
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
                            //uint32_t channelMap = f1 >> 8;
                            uint32_t channelMap = eventFIFO1->channelMap->getCache();
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
                                if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                    uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                    uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                    uint32_t pagenr        = f3 & 0x3f;
                                    uint32_t energy        = f4 ;
                                    uint32_t eventFlags=0;//append page, append next page
                                    uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                                    uint32_t traceStart16;//start of trace in short array
                                    
                                    //wfRecordVersion = 0x1 ;//0x1=raw trace, full length, search within 4 time slots for trigger
                                    wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                                    
                                    
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
                                        traceStart16 = (triggerPos + postTriggerTime ) % 2048;
                                    }
                                    else {
                                        //search trigger pos
                                        for(adccount=0; adccount<1024;adccount++){
                                            uint32_t adcval = waveformBuffer32[adccount];
                                            uint32_t adcval1 = adcval & 0xffff;
                                            uint32_t adcval2 = (adcval >> 16) & 0xffff;
                                            if(adcval1 & 0x8000) triggerPos = adccount*2;
                                            if(adcval2 & 0x8000) triggerPos = adccount*2+1;
                                            if(adcval1 & 0x2000) appendFlagPos = adccount*2;
                                            if(adcval2 & 0x2000) appendFlagPos = adccount*2+1;
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
                                    data[dataIndex++] = channelMap;
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
            else if(daqRunMode == kKatrinV4Flt_Histogram_DaqMode) {    //then fltRunMode == kIpeFltV4Katrin_Histo_Mode
                // buffer some data:
                hw4::FltKatrin *currentFlt = srack->theFlt[col];
                //hw4::SltKatrin *currentSlt = srack->theSlt;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout);
                //sleep(1);
                if(runFlags & firstTime){// firstTime
                    firstTime = false;
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
                            
                            //read sec
                            readoutSec=currentFlt->secondCounter->read();
                            //prepare data record
                            katrinV4FltHistogramDataStruct theEventData;
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
                                srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*)shipHistogramBuffer32, 0, 2048);
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
                            totalLength = 2 + (sizeof(katrinV4FltHistogramDataStruct)/sizeof(uint32_t)) + theEventData.histogramLength;// 2 = header + locationWord
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
                            if( ((dataIndex-checkDataIndexLength)*sizeof(int32_t)) != sizeof(katrinV4FltHistogramDataStruct) ){ fprintf(stdout,"ORFLTv4Readout: WARNING: bad record size!\n");fflush(stdout); }
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
    else if((versionCFPGA>=0x20010104 && versionCFPGA<0x20010300) || (versionFPGA8>=0x20010104  && versionFPGA8<0x20010300) ){
        if(srack->theFlt[col]->isPresent()){
            
            //static uint32_t currFlt = col;// only for better readability (started using it since EnergyTraceSync mode for HW data buffering)  -tb-
            
            
            //READOUT MODES (energy, energy+trace, histogram)
            ////////////////////////////////////////////////////
            
            
            // --- ENERGY MODE ------------------------------
            if((daqRunMode == kKatrinV4Flt_EnergyDaqMode) || (daqRunMode == kKatrinV4Flt_VetoEnergyDaqMode)){  //then fltRunMode == kIpeFltV4Katrin_Run_Mode resp. kIpeFltV4Katrin_Veto_Mode
                //uint32_t status         = srack->theFlt[col]->status->read();
                //uint32_t fifoStatus;// = (status >> 24) & 0xf;
                uint32_t fifoFlags;// =   FF, AF, AE, EF
                uint32_t f1, f2;
                
                //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                    //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                    //fifoStatus = eventFIFOStatus->read();//reads to cache
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
                            //uint32_t channelMap = f1 >> 8;
                            uint32_t channelMap = eventFIFO1->channelMap->getCache();
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
                                if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                    //fprintf(stdout,"  -->EVENT FLT %2i, chan %2i: ",col,eventchan);fflush(stdout);
                                    uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                    uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                    uint32_t energy        = f3 & 0xfffff;
                                    
                                    ensureDataCanHold(7);
                                    data[dataIndex++] = dataId | 7;
                                    data[dataIndex++] = location | eventchan<<8;
                                    data[dataIndex++] = evsec;        //sec
                                    data[dataIndex++] = evsubsec;     //subsec
                                    data[dataIndex++] = channelMap;
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
            else if((daqRunMode == kKatrinV4Flt_EnergyTraceDaqMode) || (daqRunMode == kKatrinV4Flt_VetoEnergyTraceDaqMode)){
                //uint32_t status         = srack->theFlt[col]->status->read();
                //uint32_t fifoStatus;// = (status >> 24) & 0xf;
                uint32_t fifoFlags;// =   FF, AF, AE, EF
                uint32_t f1, f2;
                
                //TO DO... the number of events to read could (should) be made variable <-- depending on the readptr/witeptr -tb-
                uint32_t eventN;
                for(eventN=0;eventN<10;eventN++){
                    hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;//TODO: typing error in fdhwlib - remove cast after correction -tb-
                    //fifoStatus = srack->theFlt[col]->eventFIFOStatus->read();//reads to cache
                    //fifoStatus = eventFIFOStatus->read();//reads to cache
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
                            //uint32_t channelMap = f1 >> 8;
                            uint32_t evsubsec   = eventFIFO2->subSec->getCache();//(f2 >> 2) & 0x1ffffff; // 25 bit
                            uint32_t adcoffset  = evsubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)                                //evsubsec   = srack->theSlt->subSecCounter->read();
                            //if in DMA mode we need to leave some time (postTriggerTime) until the ADC trace is written to the FLT RAM
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
                            
                            uint32_t channelMap = eventFIFO1->channelMap->getCache();
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
                                if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                                    uint32_t f3            = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                    FIFO3[col][eventchan] = f3;
                                    uint32_t pagenr        = (f3 >> 24) & 0x3f;
                                    //uint32_t energy        = f3 & 0xfffff;
                                    
                                    //static uint32_t waveformBuffer32[64*1024];
                                    //static uint32_t shipWaveformBuffer32[64*1024];
                                    //static uint16_t *waveformBuffer16 = (uint16_t *)(waveformBuffer32);
                                    //static uint16_t *shipWaveformBuffer16 = (uint16_t *)(shipWaveformBuffer32);
                                    //uint32_t searchTrig,triggerPos = 0xffffffff;
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
                                }
                            }
                            //if FIFO is full this (reading FIFO4) will release the current entry in the FIFO to allow the HW to record the next event -tb-
                            uint32_t f4            = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                            FIFO4[col]=f4;
                            
                            //now ship the buffered data ...
                            for(eventchan=0;eventchan<kNumChan;eventchan++){
                                eventchanmask = (0x1L << eventchan);
                                if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
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
                                    data[dataIndex++] = channelMap;
                                    data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                                    //data[dataIndex++] = energy; changed 2011-06-14 to add fifoEventID -tb-
                                    data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
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
            // --- HISTOGRAM MODE ------------------------------
            else if(daqRunMode == kKatrinV4Flt_Histogram_DaqMode) {    //then fltRunMode == kIpeFltV4Katrin_Histo_Mode
                // buffer some data:
                hw4::FltKatrin *currentFlt = srack->theFlt[col];
                //hw4::SltKatrin *currentSlt = srack->theSlt;
                uint32_t pageAB,oldpageAB;
                //uint32_t pStatus[3];
                //fprintf(stdout,"FLT %i:runFlags %x\n",col+1, runFlags );fflush(stdout);
                //fprintf(stdout,"FLT %i:runFlags %x  pn 0x%x\n",col+1, runFlags,srack->theFlt[col]->histNofMeas->read() );fflush(stdout);
                //sleep(1);
                if(runFlags & firstTime){// firstTime
                    firstTime = false;
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
                else {//check timing
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
                            
                            //read sec
                            readoutSec=currentFlt->secondCounter->read();
                            //prepare data record
                            katrinV4FltHistogramDataStruct theEventData;
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
                                srack->theFlt[col]->histogramData->readBlock(chan,  (long unsigned int*)shipHistogramBuffer32, 0, 2048);
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
                            totalLength = 2 + (sizeof(katrinV4FltHistogramDataStruct)/sizeof(uint32_t)) + theEventData.histogramLength;// 2 = header + locationWord
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
                            if( ((dataIndex-checkDataIndexLength)*sizeof(int32_t)) != sizeof(katrinV4FltHistogramDataStruct) ){ fprintf(stdout,"ORFLTv4Readout: WARNING: bad record size!\n");fflush(stdout); }
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
                    }
                }
            }
        }
    }
    
    return true;
}



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
    }
    else{
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }

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
                        uint32_t eventchan  = 2, channelMap = 0x4;
						uint32_t readptr  =  secCounter % 512;
						uint32_t pagenr   =  secCounter % 64;
                        uint32_t fifoFlags = 0;
                        uint32_t energy = 10000 + (col+1)*100 + eventchan;
						ensureDataCanHold(7); 
                                data[dataIndex++] = dataId | 7;    
                                data[dataIndex++] = location | eventchan<<8;
                                data[dataIndex++] = evsec;        //sec
                                data[dataIndex++] = evsubsec;     //subsec
                                data[dataIndex++] = channelMap;
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
        recordingTimeSum[i] = 0;
        for(j=0; j<kMaxHistoLength; j++) {
            sumHistogram[i][j] = 0;
        }
	}

    return;
}



#if 0  //till's saved code
//old -- keep until sure the rewrite works ok
// else if((daqRunMode == kKatrinV4Flt_EnergyTraceDaqMode) || (daqRunMode == kKatrinV4Flt_VetoEnergyTraceDaqMode) || (daqRunMode == kKatrinV4Flt_BipolarEnergyTraceDaqMode)){
else if((daqRunMode == 999999)){
    uint32_t eventN;
    hw4::FltKatrinEventFIFOStatus* eventFIFOStatus = (hw4::FltKatrinEventFIFOStatus*)srack->theFlt[col]->eventFIFOStatus;
    for(eventN=0;eventN<10;eventN++){
        eventFIFOStatus->read();//reads to cache. important!!!
        uint32_t fifoEmptyFlag = eventFIFOStatus->emptyFlag->getCache();
        if(!fifoEmptyFlag){
            uint32_t writeptr   = eventFIFOStatus->writePointer->getCache();
            uint32_t readptr    = eventFIFOStatus->readPointer->getCache();
            uint32_t diff       = (writeptr-readptr+1024) % 512;
            uint32_t fifoFlags  = (eventFIFOStatus->fullFlag->getCache()	    << 3) |
            (eventFIFOStatus->almostFullFlag->getCache()	<< 2) |
            (eventFIFOStatus->almostEmptyFlag->getCache()	<< 1) |
            (eventFIFOStatus->emptyFlag->getCache());
            
            if(diff>0){
                //first buffer the data in the FIFO and the ADC pages ...
                hw4::FltKatrinEventFIFO1* eventFIFO1 = srack->theFlt[col]->eventFIFO1;
                hw4::FltKatrinEventFIFO2* eventFIFO2 = srack->theFlt[col]->eventFIFO2;
                FIFO1[col]  = eventFIFO1->read();
                FIFO2[col]  = eventFIFO2->read();
                uint32_t f1 = FIFO1[col];
                uint32_t f2 = FIFO2[col];
                uint32_t eventSubsec = eventFIFO2->subSec->getCache();
                uint32_t adcoffset   = eventSubsec & 0x7ff; // cut 11 ls bits (equal to % 2048)
                //if in DMA mode we need to leave some time (postTriggerTime) until the ADC trace is written to the FLT RAM
                if(useDmaBlockRead){//we poll the FIFO; typically we detect a event after 200 subsecs (=10 micro sec/usec) (150-250 subsec) (sometimes 1200-4000 subsec=60-200 usec - is Orca busy here?)
                    //as the HW is still recording the ADC trace (post trigg part with typically 1024 and up to 2048 subsec = 51,2-102,4 usec)
                    uint32_t sltsubseccount = srack->theSlt->subSecCounter->read();
                    uint32_t sltsubsec1     = sltsubseccount & 0x7ff;
                    uint32_t sltsubsec2     = (sltsubseccount>>11) & 0x3fff;
                    uint32_t sltsubsec      =  sltsubsec2 * 2000 + sltsubsec1;
                    int32_t diffsubsec      = (sltsubsec-eventSubsec+20000000) % 20000000;
                    if(diffsubsec<(int32_t)postTriggerTime) break; //FLT still recording ADC trace -> leave for later for(eventN ...)-loop cycle ... -tb-
                }
                
                uint32_t channelMap = eventFIFO1->channelMap->getCache();
                uint32_t fifoEventID  = ((f1&0xff)<<4) | (f2>>28);
                uint32_t traceStart16 = (adcoffset + postTriggerTime + 1) % 2048;   //TODO: take this as standard from FW 2.1.1.4 on -tb-
                uint32_t precision  = eventFIFO2->timePrecision->getCache();        //TODO: we would need this for every channel in the channel mask -> move to FIFO3!!!! -tb-   !!!!!!!!
                
                uint32_t wfRecordVersion=0;//length: 4 bit (0..15) 0x1=raw trace, full length
                wfRecordVersion = 0x2 ;//0x2=always take adcoffset+post trigger time - recommended as default -tb-
                //TODO: I would like to store the version of the readout code <------------------------------------!!!! use new functions "generalRead/Write   -tb-
                //else: full trigger search (not recommended)
                
                uint32_t eventchan, eventchanmask;
                //now start loop to buffer FIFO and the ADC pages ...
                for(eventchan=0;eventchan<kNumChan;eventchan++){
                    eventchanmask = (0x1L << eventchan);
                    if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                        uint32_t f3           = srack->theFlt[col]->eventFIFO3->read(eventchan);
                        FIFO3[col][eventchan] = f3;
                        uint32_t pagenr       = (f3 >> 24) & 0x3f;
                        srack->theSlt->pageSelect->write(0x100 | pagenr);
                        srack->theFlt[col]->ramData->readBlock(eventchan,(long unsigned int*)adctrace32[col][eventchan],1024);
                    }
                }
                //if FIFO is full this (reading FIFO4) will release the current entry in the FIFO to allow the HW to record the next event -tb-
                uint32_t f4 = srack->theFlt[col]->eventFIFO4->read(0);//TODO: for blocking trace mode (FW 2.1.1.4 and larger) this need to be moved to the end -tb-
                FIFO4[col]  = f4;
                
                //now assemble the buffered data ...
                for(eventchan=0;eventchan<kNumChan;eventchan++){
                    eventchanmask = (0x1L << eventchan);
                    if((channelMap & eventchanmask) && (triggerEnabledMask & eventchanmask)){
                        uint32_t f3		  = FIFO3[col][eventchan];
                        uint32_t pagenr   = (f3 >> 24) & 0x3f;
                        uint32_t energy   = f3 & 0xfffff;
                        uint32_t eventSec = FIFO4[col];//( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                        
                        uint32_t waveformLength = 2048;
                        uint32_t waveformLength32=waveformLength/2; //the waveform length is variable
                        
                        uint32_t eventFlags=0;//append page, append next page  TODO: currently not used <--------------------remove it -tb-
                        
                        //ship data record
                        ensureDataCanHold(9 + waveformLength/2);
                        data[dataIndex++] = waveformId | (9 + waveformLength32);
                        data[dataIndex++] = location | eventchan<<8;
                        data[dataIndex++] = eventSec;
                        data[dataIndex++] = eventSubsec;
                        data[dataIndex++] = channelMap;
                        data[dataIndex++] = (readptr & 0x3ff) | ((pagenr & 0x3f)<<10) | ((precision & 0x3)<<16)  | ((fifoFlags & 0xf)<<20) | ((fltRunMode & 0xf)<<24);        //event flags: event ID=read ptr (10 bit); pagenr (6 bit);; fifoFlags (4 bit);flt mode (4 bit)
                        data[dataIndex++] = ((fifoEventID & 0xfff) << 20) | energy;
                        data[dataIndex++] = ((traceStart16 & 0x7ff)<<8) | eventFlags | (wfRecordVersion & 0xf);
                        data[dataIndex++] = postTriggerTime; //inserted into spare word for debugging
                        //ship waveform
                        for(uint32_t i=0;i<waveformLength32;i++){
                            data[dataIndex++] = adctrace32[col][eventchan][i];
                        }
                    }
                }
            }
        }
        else break;
    }
}

#endif

