#if !defined IPE4TBTOOLS_H
#define IPE4TBTOOLS_H


/***************************************************************************
    ipe4tbtools.h  -  description: header file  for the IPE4 Edelweiss software (OrcaReadout and ipe4reader)
                                   DO NOT INCLUDE to Obj-C code - will contain C++ classes!!!!
	history: see *.icc file

    begin                : Jan 07 2013
    copyright            : (C) 2012 by Till Bergmann, KIT
    email                : Till.Bergmann@kit.edu
 ***************************************************************************/

//This is the version of the IPE4 readout code (display is: version/1000, so cew_controle will e.g. display 1934003 as 1934.003) -tb-

// update 2013-01-03 -tb-

/*--------------------------------------------------------------------
  includes
  --------------------------------------------------------------------*/
#include <sys/types.h>//for uint32_t ? -tb-
#include <stdint.h>  //for uint32_t etc.




/*--------------------------------------------------------------------
 *    function prototypes
 *       
 *--------------------------------------------------------------------*/ //-tb-

// return slot associated to a address (1..20=FLT #1..#20, slot>=21 means SLT address); address = PCI-address
int slotOfPCIAddr(uint32_t address);

// return slot associated to a address (1..20=FLT #1..#20, slot>=21 means SLT address); address = PCI-address>>2
int slotOfAddr(uint32_t address);

//return number of bits in 'val'
int numOfBits(uint32_t val);



//counts all processes named "ipe4reader*" (used to prohibit double start)
int count_ipe4reader_instances(void);


//kill all ipe4reader* instances except myself
int kill_ipe4reader_instances(void);


int fifoReadsFLTIndexChecker(int fltIndex, int numfifo, int availableNumFIFO, int maxNumFIFO);


/*--------------------------------------------------------------------
  globals and functions for hardware access
  --------------------------------------------------------------------*/



//TODO: use this for ipe4reader AND Orca -tb-


    //SLT registers
	static const uint32_t SLTControlReg			= 0xa80000 >> 2;
	static const uint32_t SLTStatusReg			= 0xa80004 >> 2;
	static const uint32_t SLTCommandReg			= 0xa80008 >> 2;
	static const uint32_t SLTInterruptMaskReg	= 0xa8000c >> 2;
	static const uint32_t SLTInterruptRequestReg= 0xa80010 >> 2;
	static const uint32_t SLTVersionReg			= 0xa80020 >> 2;

	static const uint32_t SLTPixbusPErrorReg     = 0xa80024 >> 2;
	static const uint32_t SLTPixbusEnableReg     = 0xa80028 >> 2;
	static const uint32_t SLTBBOpenedReg         = 0xa80034 >> 2;

	
	static const uint32_t SLTSemaphoreReg    = 0xb00000 >> 2;
	
	static const uint32_t CmdFIFOReg         = 0xb00004 >> 2;
	static const uint32_t CmdFIFOStatusReg   = 0xb00008 >> 2;
	static const uint32_t OperaStatusReg0    = 0xb0000c >> 2;
	static const uint32_t OperaStatusReg1    = 0xb00010 >> 2;
	static const uint32_t OperaStatusReg2    = 0xb00014 >> 2;
	
	static const uint32_t FIFO0Addr         = 0xd00000 >> 2;
	
	//TODO: multiple FIFOs are obsolete, remove it -tb-
	static const uint32_t FIFO0ModeReg      = 0xe00000 >> 2;//obsolete 2012-10 
	static const uint32_t FIFO0StatusReg    = 0xe00004 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAEOffsetReg   = 0xe00008 >> 2;//obsolete 2012-10
	static const uint32_t BB0PAFOffsetReg   = 0xe0000c >> 2;//obsolete 2012-10
	static const uint32_t BB0csrReg         = 0xe00010 >> 2;//obsolete 2012-10
	
	#if 0
	static const uint32_t FIFOModeReg       = 0xe00000 >> 2;
	static const uint32_t FIFOStatusReg     = 0xe00004 >> 2;
	static const uint32_t PAEOffsetReg      = 0xe00008 >> 2;
	static const uint32_t PAFOffsetReg      = 0xe0000c >> 2;
	static const uint32_t FIFOcsrReg        = 0xe00010 >> 2;
    #endif

	static const uint32_t SLTTimeLowReg     = 0xb00018 >> 2;
	static const uint32_t SLTTimeHighReg    = 0xb0001c >> 2;

	static const uint32_t SLTEventFIFOReg       = 0xb80000 >> 2;
	static const uint32_t SLTEventFIFOStatusReg = 0xb80004 >> 2;
	static const uint32_t SLTEventFIFONumReg    = 0xb80008 >> 2;


	
uint32_t FIFOStatusReg(int numFIFO);

uint32_t FIFOModeReg(int numFIFO);
uint32_t FIFOAddr(int numFIFO);
uint32_t PAEOffsetReg(int numFIFO);
uint32_t PAFOffsetReg(int numFIFO);
uint32_t BBcsrReg(int numFIFO);

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
	static const uint32_t FLTPostTriggI2HDelayRegBase  = 0x00003c >> 2;

	static const uint32_t FLTAccessTestRegBase     = 0x000040 >> 2;
	
	static const uint32_t FLTTotalTriggerNRegBase  = 0x000084 >> 2;

	static const uint32_t FLTBBStatusRegBase    = 0x00001400 >> 2;

	static const uint32_t FLTRAMDataRegBase     = 0x00003000 >> 2;


	static const uint32_t FLTHeatTriggParRegBase     = 0x00000050 >> 2;
	static const uint32_t FLTIonTriggParRegBase     = 0x00000054 >> 2;
	
	static const uint32_t FLTReadPageNumRegBase     = 0x00007c >> 2;

// 
// NOTE: numFLT from 1...20  !!!!!!!!!!!!
//
// (NOT from 0 ... 19!!!)
//
	//TODO: 0x3f or 0x1f?????????????
uint32_t FLTStatusReg(int numFLT);
uint32_t FLTControlReg(int numFLT);
uint32_t FLTCommandReg(int numFLT);
uint32_t FLTVersionReg(int numFLT);
uint32_t FLTFiberOutMaskReg(int numFLT);
uint32_t FLTFiberSet_1Reg(int numFLT);
uint32_t FLTFiberSet_2Reg(int numFLT);
uint32_t FLTStreamMask_1Reg(int numFLT);
uint32_t FLTStreamMask_2Reg(int numFLT);
uint32_t FLTTriggerMask_1Reg(int numFLT);
uint32_t FLTTriggerMask_2Reg(int numFLT);
uint32_t FLTPostTriggI2HDelayReg(int numFLT);
uint32_t FLTAccessTestReg(int numFLT);
uint32_t FLTBBStatusReg(int numFLT, int numChan);
uint32_t FLTTotalTriggerNReg(int numFLT);
uint32_t FLTRAMDataReg(int numFLT, int numChan);
uint32_t FLTHeatTriggParReg(int numFLT, int numChan);
uint32_t FLTIonTriggParReg(int numFLT, int numChan);
uint32_t FLTTriggParReg(int numFLT, int numChan);
uint32_t FLTReadPageNumReg(int numFLT);
uint32_t FLTRegAddr(uint32_t regAddrBase, int numFLT);




/*--------------------------------------------------------------------
 *    function prototypes (moved from ipe4reader to provide access for OrcaReadout)
 *--------------------------------------------------------------------*/ //-tb-
extern int (*sendChargeBBStatusFunctionPtr)(uint32_t prog_status,int numFifo);
//int (*sendChargeBBStatusFunctionPtr)(uint32_t prog_status,int numFifo) = 0;
//for testing :int (*sendChargeBBStatusFunctionPtr)(uint32_t prog_status,int numFifo) = (int (*)(uint32_t ,int ))23;

void sendCommandFifo(unsigned char * buffer, int len);
void sendCommandFifoUnblockFiber(unsigned char * buffer, int len, int flt, int fiber);
void envoie_commande_standard_BBv2(void);
//void envoie_commande_horloge(void);
void envoie_commande_horloge(int X, int Retard, int Masque_BB, int Code_acqui, int Code_synchro, int Nb_mots_lecture);

int32_t  fsize(FILE* fd);
int chargeBBWithFILEPtr(FILE * fichier,int * numserie, int numFifo);
void chargeBBWithFile(char * filename, int fromFifo);


uint32_t setSLTtimerWithUTC(uint32_t flags, uint32_t utcTime, uint64_t utcTimeOffset,  uint64_t utcTimeCorrection100kHz);






/*--------------------------------------------------------------------
  classes:
  --------------------------------------------------------------------*/






/*--------------------------------------------------------------------
 *    function:     
 *    purpose:      
 *    author:       Till Bergmann, 2011
 *--------------------------------------------------------------------*/ //-tb-
 
 
#endif
//of #if !defined IPE4TBTOOLS_H
