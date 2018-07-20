#include "ORSLTv4Readout.hh"
#include "KatrinV4_HW_Definitions.h"
#include "readout_code.h"
#include <errno.h>

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>


#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORSLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif


#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------
extern hw4::SubrackKatrin* srack; 
extern Pbus* pbus;

static const uint32_t FIFO0Addr         = 0xd00000 >> 2;
static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;//obsolete 2012-10
static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;//obsolete 2012-10  

extern int debug;
extern int nSendToOrca;


ORSLTv4Readout::ORSLTv4Readout(SBC_card_info* ci) : ORVCard(ci)
{
    const char*  sMode[] = { "Standard mode - data transport via SBC protocol to Orca",
        "Local readout mode - local storage of events at the crate PC",
        "Simulation mode - shipping simulation records via SBC protocol to Orca"};
    
    //
    // Warning:
    //
    // Don't have here other than kStandard selected, when checking code in to the repositories
    // Do change this flag only for test purpose at the crate PC and start OrcaReadout manually
    // by ./orcaReadout 44667
    //
    
    mode = kStandard;
    //mode = kLocal;
    //mode = lSimulation;
    
    // Start message
    if (debug) printf("ORSLTv4Readout: %s\n", sMode[mode%3]);
    
    // Initiolize analysis variables
    maxLoopsPerSec = 0;
    
}

bool ORSLTv4Readout::Start()
{
    struct timezone tz;
    const char *sEnable[] = {"no", "yes"};
    
    switch (mode){
        case kStandard:
            break;
        case kLocal:
            LocalReadoutInit();
            break;
        case kSimulation:
            SimulationInit();
            break;
    }
    
    // Start readout performance measurement
    nWords = 0;
    nLoops = 0;
    nReadout = 0;
    nReducedSize = 0;
    nWaitingForReadout = 0;
    nInhibit = 0;
    nNoReadout = 0;
    
    gettimeofday(&t0, &tz);
    
    // Prepare the header
    uint32_t energyId   = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ;
    
    header[0] = energyId; // id, put in the length later
    header[1] = location;
    header[2] = 0; //spare
    header[3] = 0; //spare
    
    //printf("Header: %08x %08x %08x %08x\n", header[0], header[1], header[2], header[3]);
    
    
    // Select the readoutfunction depending on the mode
    //uint32_t runFlags    = GetDeviceSpecificData()[3];
    
    uint32_t sltRevision = GetDeviceSpecificData()[6];
    if(sltRevision>=0x3010004){
        
        switch (mode){
            case kStandard:
                readoutCall = &ORSLTv4Readout::ReadoutEnergyV31;
                break;
            case kLocal:
                readoutCall = &ORSLTv4Readout::LocalReadoutEnergyV31;
                break;
            case kSimulation:
                readoutCall = &ORSLTv4Readout::SimulationReadoutEnergyV31;
                break;
        }
        
    } else {
    
        readoutCall = &ORSLTv4Readout::ReadoutLegacyCode;
    }
    
    if (debug) printf("%ld.%06ld: Start readout loop, Flt readout = %s, debug = %d\n",
           t0.tv_sec, t0.tv_usec, sEnable[activateFltReadout%2], debug);

    
    return true;
}


bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    nLoops = nLoops + 1;

    (*this.*readoutCall)(lamData);

    // Read out the children flts that are in the readout list
    // Leave out for the high rate tests
    int32_t leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    
    return true; 
}

bool ORSLTv4Readout::Stop()
{
    float runTime;
    float loopsPerSec;
    unsigned long long int tReadoutTime;
    uint32_t meanBlockSize;
    float load;
    
    struct timezone tz;
    unsigned long long int t0Ticks, t1Ticks;
    float rate;
    float tLoop;
    
    switch (mode){
        case kStandard:
            break;
        case kLocal:
            LocalReadoutClose();
            break;
        case kSimulation:
            break;
    }

    
    if (debug) {
        
        // Measure readout time
        gettimeofday(&t1, &tz);
        t0Ticks = (long long int) t0.tv_sec * 1000000 + t0.tv_usec;
        t1Ticks = (long long int) t1.tv_sec * 1000000 + t1.tv_usec;
        runTime = (float) (t1Ticks - t0Ticks) / 1000000;
        
        try {
            tReadoutTime = srack->theSlt->runTime->read();
        } catch (PbusError &perr) {
            printf("ORSLTv4Readout::Stop Error %s\n", perr.what());
            perr.displayMsg(stdout);
            fflush(stdout);
        }

        rate = 0;
        if (tReadoutTime>0) rate = (float) nWords * 40 / tReadoutTime; // MB/s
        
        printf("%ld.%06ld: Stop readout loop, run %.3f s, readout %lld s, data %.1f MB, rate %.1f MB/s\n",
            t1.tv_sec, t1.tv_usec, runTime, tReadoutTime / 10000000,
            (float) nWords * 4 / 1000 / 1000, rate);
        
        // Readout loops
        
        // For performance testing always run the first run without signal, to measure the loop time
        loopsPerSec = 0;
        if (runTime > 0) loopsPerSec = (float) nLoops / runTime;
        if ((unsigned ) loopsPerSec > maxLoopsPerSec) maxLoopsPerSec = (unsigned long long int) loopsPerSec;
        
        tLoop = 0;
        if (nLoops > 0) tLoop = (float) (t1Ticks - t0Ticks) / nLoops;
        
        printf("%17s: loops total %lld, readout %lld, red size %lld, wait %lld, inhibit %lld, loop time %.3f us\n", "",
               nLoops, nReadout, nReducedSize, nWaitingForReadout, nInhibit, tLoop);
        
        // Estimation of readout load
        // Todo: Add time measurements
        
        load = 0;
        meanBlockSize = 0;
        if (nReadout > 0) {
            meanBlockSize =  nWords / nReadout;
            load = (float) 100 * nWords / nReadout / 8160;
        }
        
         printf("%17s: mean block size %d, load %.2f %s, loops/s %lld\n", "",
               meanBlockSize, load, "%", maxLoopsPerSec);

        }
    
    return true;
}


bool ORSLTv4Readout::ReadoutEnergyV31(SBC_LAM_Data* lamData)
{
    uint32_t firstIndex = dataIndex; //so we can insert the length and/or if we have to flush
    try {
        uint32_t headerLen  = 4;
        uint32_t numWordsToRead  = srack->theSlt->fifoSize->read();
        //uint32_t numWordsToRead  = pbus->read(FIFO0ModeReg) & 0x3fffff;

        if (numWordsToRead >= 8160){ // full block readout
            nNoReadout = 0; // Clear no readout
            nReadout   = nReadout + 1;
            
            numWordsToRead = 8160;
            ensureDataCanHold(numWordsToRead + headerLen);
            
            memcpy(&data[dataIndex], header, headerLen * sizeof(uint32_t));
            dataIndex += headerLen;
            
            pbus->readBlock(FIFO0Addr, (unsigned long*)(&data[dataIndex]), numWordsToRead);
            //srack->theSlt->fifoData->readBlock((unsigned long*)(&data[dataIndex]), numWordsToRead);
            dataIndex += numWordsToRead;
            
            data[firstIndex] |= (numWordsToRead+headerLen); //fill in the record length

            nWords = nWords + numWordsToRead;
        }
        else if (numWordsToRead > 0) { // partial readout
            nNoReadout   = 0; // Clear no readout
            nReadout     = nReadout + 1;
            nReducedSize = nReducedSize + 1;
            
            ensureDataCanHold(numWordsToRead + headerLen);
            
            memcpy(&data[dataIndex], header, headerLen * sizeof(uint32_t));
            dataIndex += headerLen;

            if (numWordsToRead < 48) {
                numWordsToRead = (numWordsToRead/6)*6; //make sure we are on event boundary
                for(uint32_t i=0;i<numWordsToRead; i++){
                    //data[dataIndex++] = srack->theSlt->fifoData->read();
                    data[dataIndex++] = pbus->read(FIFO0Addr);
                }
            }
            else {
                numWordsToRead  = (numWordsToRead/48)*48;//always read multiple of 48 word32s
                pbus->readBlock(FIFO0Addr, (unsigned long*)(&data[dataIndex]), numWordsToRead);
                //srack->theSlt->fifoData->readBlock((unsigned long*)(&data[dataIndex]), numWordsToRead);
                dataIndex += numWordsToRead;
            }
        
            data[firstIndex] |= (numWordsToRead+headerLen); //fill in the record length
            
            nWords = nWords + numWordsToRead;
        }
        else { // no readout
            nNoReadout = nNoReadout + 1;
            if (srack->theSlt->status->inhibit->read()) nInhibit = nInhibit + 1;
        }
    }
    catch (PbusError &perr) {
        LogBusErrorForCard(GetSlot(),"PBus Err: %s",perr.what());
        dataIndex = firstIndex; //can't rely on the data buffer. flush it
        if (debug){
            printf("ORSLTv4Readout::ReadoutEnergyV31: Error %s\n", perr.what());
            perr.displayMsg(stdout);
            fflush(stdout);
        }
    }
    
    catch(...){
        LogBusErrorForCard(GetSlot(),"Bus Err: %s",strerror(errno));
        dataIndex = firstIndex; //can't rely on the data buffer. flush it
        if (debug){
            printf("ORSLTv4Readout::ReadoutEnergyV31: Unexpected Error\n");
            fflush(stdout);
        }
    }
    
    return true;
}

bool ORSLTv4Readout::LocalReadoutEnergyV31(SBC_LAM_Data* lamData)
{
    // Write the Orca data blocks to file; do not transmit anything to Orca

    uint32_t bufferIndex = 0;
    
    try {
        uint32_t headerLen  = 4;
        uint32_t numWordsToRead  = pbus->read(FIFO0ModeReg) & 0x3fffff;
        
        if (numWordsToRead >= 8160){ // full block readout
            nNoReadout = 0; // Clear no readout
            nReadout = nReadout + 1;
            
            numWordsToRead = 8160;
            
            uint32_t firstIndex = bufferIndex; //so we can insert the length
            memcpy(&dataBuffer[dataIndex], header, headerLen * sizeof(uint32_t));
            bufferIndex += headerLen;
            
            pbus->readBlock(FIFO0Addr, (unsigned long*)(&dataBuffer[bufferIndex]), numWordsToRead);
            dataBuffer[firstIndex] = (header[0] & 0xfffc0000) | (numWordsToRead+headerLen); //fill in the record length

            nWords = nWords + numWordsToRead;

        } else if ((numWordsToRead > 0) && (nNoReadout > 10)) { // partial readout
            nNoReadout = 0; // Clear no readout
            nReadout = nReadout + 1;
            nReducedSize = nReducedSize + 1;
            
            uint32_t firstIndex = bufferIndex; //so we can insert the length
            
            memcpy(&dataBuffer[dataIndex], header, headerLen * sizeof(uint32_t));
            bufferIndex += headerLen;
            
            if (numWordsToRead < 48) {
                numWordsToRead = (numWordsToRead/6)*6; //make sure we are on event boundary
                for(uint32_t i=0;i<numWordsToRead; i++){
                    dataBuffer[dataIndex++] = pbus->read(FIFO0Addr);
                }
            }
            else {
                numWordsToRead  = (numWordsToRead/48)*48;//always read multiple of 48 word32s
                pbus->readBlock(FIFO0Addr, (unsigned long*)(&dataBuffer[bufferIndex]), numWordsToRead);
                bufferIndex += numWordsToRead;
            }
            
            dataBuffer[firstIndex] = (header[0] & 0xfffc0000) | (numWordsToRead+headerLen); //fill in the record length
            
            nWords = nWords + numWordsToRead;
            
        } else { // no readout
            nNoReadout = nNoReadout + 1;
            
            // Todo: Better check for inhibit here?! Are these the same values???
            if (numWordsToRead > 0) nWaitingForReadout = nWaitingForReadout + 1;
            
            if (srack->theSlt->status->inhibit->read()) nInhibit = nInhibit + 1;
            
        }
        
        // Write block to local file
        // Merge late with the Orca readout file
        //write(filePtr, dataBuffer, (numWordsToRead+headerLen) * sizeof(uint32_t));


        // Send a few blocks to Orca - just to validate that still correct data is recorded)
        if ((nNoReadout == 0) && (nReadout > 0) && (nSendToOrca > 0) && (nReadout % nSendToOrca == 0)){
            
            ensureDataCanHold(numWordsToRead + headerLen);
            memcpy(&data[dataIndex], dataBuffer, (numWordsToRead + headerLen) * sizeof(uint32_t));
            dataIndex += (numWordsToRead + headerLen);
            
        }

        // Save single blocks to a file for usage in simulation mode
        if ((nNoReadout == 0) && (fileSnapshotPtr > 0) && (nReadout == 1234)) {
            if (debug) printf("Save sample block for simulation mode, nReadout %lld, block size %d\n",
                              nReadout, numWordsToRead);
            write(fileSnapshotPtr, dataBuffer, (numWordsToRead + headerLen) * sizeof(uint32_t));
        }
        
        
    } catch (PbusError &perr) {
        if (debug){
             printf("ORSLTv4Readout::ReadoutEnergyV31: Error %s\n", perr.what());
            perr.displayMsg(stdout);
            fflush(stdout);
        }
    }
    
    catch(...){
        if (debug){
            printf("ORSLTv4Readout::ReadoutEnergyV31: Unexpected Error\n");
            fflush(stdout);
        }
    }
    
    return true;
    
}

void ORSLTv4Readout::LocalReadoutInit()
{
    // Read the file name from inifile
    // Get the run number from Orca
    
    // Open the readout file
    // Todo: Add start second in the file name
    system("mkdir -p /home/katrin/data");
    filePtr = open("/home/katrin/data/Run000.part", O_WRONLY | O_CREAT, 0777);
    fileSnapshotPtr = open("/home/katrin/data/SingleBlock.snap", O_WRONLY | O_CREAT, 0777);
    
}

void ORSLTv4Readout::LocalReadoutClose()
{
    // Close the readout files
    if (filePtr) {
        close(filePtr);
        filePtr = 0;
    }
    
    if (fileSnapshotPtr) {
        close(fileSnapshotPtr);
        fileSnapshotPtr = 0;
    }
    
}

bool ORSLTv4Readout::SimulationReadoutEnergyV31(SBC_LAM_Data*)
{
 
    
    // Send the simulated data to Orca
    // Parameter: block size; data rate
    
    // Check time
    
    // Check space in the buffer
    
    // Copy data packet
    
    // Update length
    
    
    return true;
}

void ORSLTv4Readout::SimulationInit()
{
    uint32_t i;
    uint32_t bufferIndex;
    
    // Write usefull data ti the simulation data block
    // Each block has a header of 4 words and upto 8160 words of data
    
    // Parameter: block size
   
    //
    // Todo: Set this paraeters by any other measns (e.g. preprocessor, inifile, etc)
    //
    simBlockSize = 1365; // max 8160 / 6
    simDataRate = 10;    // MB/s
    
    
    bufferIndex = 0;
    if (simBlockSize > 1365) simBlockSize = 1365;
    
    
    uint32_t energyId   = GetHardwareMask()[3];
    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ;
    
    
    uint32_t time       = 1510872785; // Put always the same time in the data
                                     // having real time take too long to prepare
    
    uint32_t headerLen  = 4;
    uint32_t firstIndex = bufferIndex; //so we can insert the length
    
    dataBuffer[bufferIndex++] = energyId | 0; //fill in the length below
    dataBuffer[bufferIndex++] = location  ;
    dataBuffer[bufferIndex++] = 0; //spare
    dataBuffer[bufferIndex++] = 0; //spare
    
    
    for (i=0;i<simBlockSize;i++)
    {
        // Todo: Fill data according to the hardware specification
        dataBuffer[bufferIndex++] = (0x1 << 29) | (1234567 << 3) | ((time) >> 29); // sub seconds 3:27
        dataBuffer[bufferIndex++] = (0x2 << 29) | (time & 0x1fffffff) ; // seconds
        dataBuffer[bufferIndex++] = (0x3 << 29) | ((i%4) << 24) | ((i%24) << 19) | (i+1); // flt ch eventId
        dataBuffer[bufferIndex++] = (0x4 << 29) | 0; // pileup peak
        dataBuffer[bufferIndex++] = (0x5 << 29) | 0; // pileup valley
        dataBuffer[bufferIndex++] = (0x6 << 29) | (2000-(i*i)%20) * 32 ; //energy, 1,6us filer
    }
    
    dataBuffer[firstIndex] |=  (simBlockSize*6 + headerLen); //fill in the record length
    
    return;
}


bool ORSLTv4Readout::ReadoutLegacyCode(SBC_LAM_Data* lamData)
{
    uint32_t i;
    
    //init
    uint32_t eventFifoId = GetHardwareMask()[2];
    //uint32_t energyId    = GetHardwareMask()[3];
    //uint32_t runFlags    = GetDeviceSpecificData()[3];
    uint32_t sltRevision = GetDeviceSpecificData()[6];
    
    uint32_t col        = GetSlot() - 1; //(1-24)
    uint32_t crate      = GetCrate();
    uint32_t location   = ((crate & 0x01e)<<21) | (((col+1) & 0x0000001f)<<16) ;
    
    //SLT read out
    //
    //extern Pbus *pbus;              //for register access with fdhwlib
    //pbus = srack->theSlt->version;
    //uint32_t sltversion=sltRevision;
    
    
    if(sltRevision==0x3010003){//we have SLT event FIFO since this revision -> read FIFO (one event = 4 words)
        uint32_t headerLen  = 4;
        uint32_t numWordsToRead = pbus->read(FIFO0ModeReg) & 0x3fffff;
        if(numWordsToRead>8192) numWordsToRead=8192;
        if(numWordsToRead % 4)  numWordsToRead = (numWordsToRead>>2)<<2;//always read multiple of 4 word32s
        if(numWordsToRead>0){
            uint32_t firstIndex   = dataIndex; //so we can insert the length
            ensureDataCanHold(numWordsToRead+headerLen);
            
            data[dataIndex++] = eventFifoId | 0;//fill in the length below
            data[dataIndex++] = location  ;
            data[dataIndex++] = 0; //spare
            data[dataIndex++] = 0; //spare
            
            //there are more than 48 words -> use DMA
            if(numWordsToRead<48) {
                for(i=0;i<numWordsToRead; i++){
                    data[dataIndex++]=pbus->read(FIFO0Addr);
                }
            }
            else {
                numWordsToRead = (numWordsToRead>>3)<<3;//always read multiple of 8 word32s
                pbus->readBlock(FIFO0Addr, (unsigned long *)(&data[dataIndex]), numWordsToRead);//read 2048 word32s
                dataIndex += numWordsToRead;
            }
            data[firstIndex] |=  (numWordsToRead+headerLen); //fill in the record length
            
        }
    }
    
    return true;
}


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------
bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    static int currentSec   = 0;
    static int currentUSec  = 0;
    static int lastSec      = 0;
    static int lastUSec     = 0;
    //static long int counter =0; //for debugging
    static long int secCounter=0;
    
    struct timeval t;
    gettimeofday(&t,NULL);
    currentSec  = t.tv_sec;
    currentUSec = t.tv_usec;  
    double diffTime = (double)(currentSec  - lastSec) + ((double)(currentUSec - lastUSec)) * 0.000001;
    
    if(diffTime >1.0){
        secCounter++;
        printf("PrPMC (SLTv4 simulation mode) sec %ld: 1 sec is over ...\n",secCounter);
        fflush(stdout);
        lastSec      = currentSec;
        lastUSec     = currentUSec; 
    }
    else {
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }
    
    //read out the children flts that are in the readout list
    int32_t leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    return true; 
}

#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------



