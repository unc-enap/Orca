#ifndef _ORSLTv4Readout_hh_
#define _ORSLTv4Readout_hh_
#include "ORVCard.hh"
#include <iostream>
#include <sys/time.h>

typedef enum readoutModeType {
    kStandard,
    kLocal,
    kSimulation
} readoutMode;

/** For each IPE4 crate in the Orca configuration one instance of ORSLTv4Readout is constructed.
 *
 * Short firmware history:
 * - Project:1 Doc:0x214 Implementation:0xc063 - current version 2010 - 2011-06-16
 *
 * NOTE: UPDATE 'kCodeVersion': After all major changes in HW_Readout.cc, FLTv4Readout.cc, FLTv4Readout.hh, SLTv4Readout.cc, SLTv4Readout.hh
 * 'kCodeVersion' in HW_Readout.cc should be increased!
 *
 *
 */
class ORSLTv4Readout : public ORVCard
{
public:
    ORSLTv4Readout(SBC_card_info* ci);
    virtual ~ORSLTv4Readout() {}
    virtual bool Start();
    virtual bool Readout(SBC_LAM_Data*);
    
    virtual bool Stop();
    
    /** Readout energy mode with firmware 3.1 */
    bool ReadoutEnergyV31(SBC_LAM_Data*);
    
    /** Code for older firmaware version */
    bool ReadoutLegacyCode(SBC_LAM_Data*);
    
    /** Readout energies and write to local disk */
    bool LocalReadoutEnergyV31(SBC_LAM_Data*);
    
    /** Open readout file */
    void LocalReadoutInit();
    
    /** Open readout file */
    void LocalReadoutClose();
    
    /** Simulate readout for performnace tests.
     * Parameter: block size, data rate
     */
    bool SimulationReadoutEnergyV31(SBC_LAM_Data*);
    
    /** Generate a template readout block */
    void SimulationInit();
    
    
private:
    bool firstTime;
    unsigned long long int nNoData; //< Number of loops where no data was read
    
    struct timeval t0;
    struct timeval t1;
    uint32_t numWordsToRead; //< Number of word read in the last cycle
    unsigned long long int nWords; //< Number of raw bytes recorded
    unsigned long long int nLoops; //< Number of calls to the readout function
    unsigned long long int nReadout; //< Number of calls with readout of data
    unsigned long long int nReducedSize; //< Number of calls and readout of less than maximum block size
    unsigned long long int nWaitingForReadout; //< Number of loops waiting for data
    unsigned long long int nInhibit; //< Number of loops with inhibit active
    unsigned long long int nNoReadout; //<  Number of loops without readout
    unsigned long long int maxLoopsPerSec; //< Speed of the readout loop; used for analysis
    
    bool activateFltReadout; //< Loop over Flts only trace and histogram mode
    
    readoutMode mode; //< control the readout function (standard, local storage, simulation)
    
    int filePtr; //< File pointer
    int fileSnapshotPtr; //< File pointer for single block file (used by simulation mode)
    uint32_t dataBuffer[8192]; //< maximal DMA block size
    uint32_t header[4]; //< precompiled header
    
    uint32_t simBlockSize; //< block size used in simulation (6 words)
    uint32_t simDataRate; //< desired data in simulation (MB/s)
    
    bool (ORSLTv4Readout::*readoutCall)(SBC_LAM_Data*); //< pointer to the readout code
    
};

#endif /* _ORSLTv4Readout_hh_*/
