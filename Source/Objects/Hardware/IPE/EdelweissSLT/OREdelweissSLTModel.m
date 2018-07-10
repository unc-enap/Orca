//
//  OREdelweissSLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

//#import "ORIpeDefs.h"
#import "ORGlobal.h"
#import "ORCrate.h"
#import "OREdelweissSLTModel.h"
#import "OREdelweissFLTModel.h"
#import "EdelweissSLTv4_HW_Definitions.h"
#import "EdelweissSLTv4GeneralOperations.h"
#import "ipe4structure.h"
//#import "ORIpeFLTModel.h"
//#import "ORIpeCrateModel.h"
#import "ORIpeV4CrateModel.h"
#import "OREdelweissSLTDefs.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PMC_Link.h"               //this is taken from IpeV4 SLT !!  -tb-
#import "ORPMCReadWriteCommand.h"  //this is taken from IpeV4 SLT !!  -tb-

#import "ORTaskSequence.h"
#import "ORFileMover.h"

#include <pthread.h>


//IPE V4 register definitions
enum EdelweissSLTV4Enum {
	kEWSltV4ControlReg,
	kEWSltV4StatusReg,
	kEWSltV4CommandReg,
	kEWSltV4StatusLowReg, //new for rev. 2.00
	kEWSltV4StatusHighReg,//new for rev. 2.00
	//removed for rev. 2.00 kSltV4InterruptMaskReg,
	//removed for rev. 2.00 kSltV4InterruptRequestReg,
	//kSltV4RequestSemaphoreReg,
	kEWSltV4RevisionReg,
	kEWSltV4PixelBusErrorReg,
	kEWSltV4PixelBusEnableReg,
	//kSltV4PixelBusTestReg,
	//kSltV4AuxBusTestReg,
	//kSltV4DebugStatusReg,
    kEWSltV4FIFOUsedReg,
    //removed for rev. 2.00 kSltV4BBOpenedReg,
    kEWSltV4TestReg,
    
    //BB command FIFO + Opera stuff
    kEWSltV4SemaphoreReg,
    kEWSltV4CmdFIFOReg,
    kEWSltV4CmdFIFOStatusReg,
    kEWSltV4OperaStatusReg0Reg,
    kEWSltV4OperaStatusReg1Reg,
    kEWSltV4OperaStatusReg2Reg,
    
    kEWSltV4TimeLowReg,
    kEWSltV4TimeHighReg,
	
kSltV4EventFIFOReg,
kSltV4EventFIFOStatusReg,
kSltV4EventNumberReg,
	/*
	kSltV4VetoCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4VetoCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterHiReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterLoReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
								//TODO: and dead time and veto time counter are confused, too -tb-
	kSltV4RunCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4RunCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4SecondSetReg,
	kSltV4SecondCounterReg,
	kSltV4SubSecondCounterReg,
	kSltV4PageManagerReg,
	kSltV4TriggerTimingReg,
	kSltV4PageSelectReg,
	kSltV4NumberPagesReg,
	kSltV4PageNumbersReg,
	kSltV4EventStatusReg,
	kSltV4ReadoutCSRReg,
	kSltV4BufferSelectReg,
	kSltV4ReadoutDefinitionReg,
	kSltV4TPTimingReg,
	kSltV4TPShapeReg,
	*/
	
	kEWSltV4I2CCommandReg,
	kEWSltV4EPCCommandReg,
	kEWSltV4BoardIDLoReg,
	kEWSltV4BoardIDHiReg,
	kEWSltV4PROMsControlReg,
	kEWSltV4PROMsBufferReg,
	//kSltV4TriggerDataReg,
	//kSltV4ADCDataReg,
kSltV4BBxDataFIFOReg,
kSltV4BBxFIFOModeReg,
kSltV4BBxFIFOStatusReg,
kSltV4BBxFIFOPAEOffsetReg,
kSltV4BBxFIFOPAFOffsetReg,
kSltV4BBxcsrReg,
kSltV4BBxRequestReg,
kSltV4BBxMaskReg,
	
	
	kEWSltV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kEWSltV4NumRegs] = {
{@"Control",			0xa80000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Status",				0xa80004,		1,			kIpeRegReadable },
{@"Command",			0xa80008,		1,			kIpeRegWriteable },
{@"Status Low",			0xa80010,		1,			kIpeRegReadable | kIpeRegWriteable },//new for rev. 2.00
{@"Status High",		0xa80014,		1,			kIpeRegReadable | kIpeRegWriteable },//new for rev. 2.00
//removed for rev. 2.00 {@"Interrupt Mask",		0xA8000C,		1,			kIpeRegReadable | kIpeRegWriteable },
//removed for rev. 2.00 {@"Interrupt Request",	0xA80010,		1,			kIpeRegReadable },
//HEAT {@"Request Semaphore",	0xA80014,		3,			kIpeRegReadable },
{@"Revision",			0xa80020,		1,			kIpeRegReadable },
{@"Pixel Bus Error",	0xA80024,		1,			kIpeRegReadable },			
{@"Pixel Bus Enable",	0xA80028,		1, 			kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Pixel Bus Test",		0xA8002C, 		1, 			kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Aux Bus Test",		0xA80030, 		1, 			kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Debug Status",		0xA80034,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"FIFO Used",			0xA80034,  		1, 			kIpeRegReadable },
//removed for rev. 2.00 {@"BB Opened",			0xA80034,  		1, 			kIpeRegReadable },
{@"Test",		    	0xA80038,  		1, 			kIpeRegReadable | kIpeRegWriteable },

{@"Semaphore",			0xB00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"CmdFIFO",			0xB00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"CmdFIFOStatus",		0xB00008,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"OperaStatusReg0",	0xB0000C,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"OperaStatusReg1",	0xB00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"OperaStatusReg2",	0xB00014,		1,			kIpeRegReadable | kIpeRegWriteable },

{@"TimeLow",			0xB00018,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"TimeHigh",			0xB0001C,		1,			kIpeRegReadable | kIpeRegWriteable },

{@"EventFIFO",			0xB80000,  		1, 			kIpeRegReadable },
{@"EventFIFOStatus",	0xB80004,  		1, 			kIpeRegReadable },
{@"EventNumber",		0xB80008, 		1,			kIpeRegReadable },
/*HEAT
{@"Veto Counter (MSB)",	0xA80080, 		1,			kIpeRegReadable },	
{@"Veto Counter (LSB)",	0xA80084,		1,			kIpeRegReadable },	
{@"Dead Counter (MSB)",	0xA80088, 		1,			kIpeRegReadable },	
{@"Dead Counter (LSB)",	0xA8008C, 		1,			kIpeRegReadable },	
{@"Run Counter  (MSB)",	0xA80090,		1,			kIpeRegReadable },	
{@"Run Counter  (LSB)",	0xA80094, 		1,			kIpeRegReadable },	
{@"Second Set",			0xB00000,  		1, 			kIpeRegReadable | kIpeRegWriteable }, 
{@"Second Counter",		0xB00004, 		1,			kIpeRegReadable },
{@"Sub-second Counter",	0xB00008, 		1,			kIpeRegReadable }, 
{@"Page Manager",		0xB80000,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Timing",		0xB80004,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Page Select",		0xB80008, 		1,			kIpeRegReadable },
{@"Number of Pages",	0xB8000C, 		1,			kIpeRegReadable },
{@"Page Numbers",		0xB81000,		64, 		kIpeRegReadable | kIpeRegWriteable },
{@"Event Status",		0xB82000,		64,			kIpeRegReadable },
{@"Readout CSR",		0xC00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Buffer Select",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Readout Definition",	0xC10000,	  2048,			kIpeRegReadable | kIpeRegWriteable },			
{@"TP Timing",			0xC80000,	   128,			kIpeRegReadable | kIpeRegWriteable },	
{@"TP Shape",			0xC81000,	   512,			kIpeRegReadable | kIpeRegWriteable },	
*/
{@"I2C Command",		0xC00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"EPC Command",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Board ID (LSB)",		0xC00008,		1,			kIpeRegReadable },
{@"Board ID (MSB)",		0xC0000C,		1,			kIpeRegReadable },
{@"PROMs Control",		0xC00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"PROMs Buffer",		0xC00100,		256/*252? ask Sascha*/,		kIpeRegReadable | kIpeRegWriteable },
//HEAT {@"Trigger Data",		0xD80000,	  14000,		kIpeRegReadable | kIpeRegWriteable },
//TODO: 0xEXxxxx, "needs FIFO num" implementieren!!! -tb-
{@"BBxDataFIFO",			0xD00000,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, //BBx -> x=num./index of FIFO   -tb-
{@"BBxFIFOMode",			0xE00000,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, //BBx -> x=num./index of FIFO (2012: this was equal to index FLTx), adress: 0xEX0000 -tb-
{@"BBxFIFOStatus",			0xE00004,	 1,		kIpeRegReadable |                    kIpeRegNeedsIndex }, 
{@"BBxFIFOPAEOffset",		0xE00008,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBxFIFOPAFOffset",		0xE0000C,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBx csr",				0xE00010,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBx Request",			0xE00014,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
{@"BBx Mask",				0xE00018,	 1,		kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsIndex }, 
//{@"Data Block RW",		0xF00000 Data Block RW
//{@"Data Block Length",	0xF00004 Data Block Length 
//{@"Data Block Address",	0xF00008 Data Block Address
};

//threading
	    //pthread handling
	    pthread_t dataReplyThread;
        pthread_mutex_t dataReplyThread_mutex;

volatile int vflag = 0;


#define kMaxNumUDPDataPackets 100000
#define kMaxNumUDPStatusPackets 100  // currently (2013) we expect max. 9 packets; but size might increase and legacy opera status may appear: use min 30 -tb-
#define kMaxUDPSizeDim 1500     //see comment below
#define kMaxNumADCChan 720      //see comment below
typedef struct{
	    int started;
	    int stopNow;
		id model;
		struct sockaddr_in sockaddr_data_from;
		int UDP_DATA_REPLY_SERVER_SOCKET;
        int isListeningOnDataServerSocket;

    //status packet buffer (I expect max. 
    char statusBuf[2][kMaxNumUDPStatusPackets][kMaxUDPSizeDim/*1500*/];//store the status UDP packets
    int statusBufSize[2][kMaxNumUDPStatusPackets];//store the size in bytes of the according status UDP packet
    int  numStatusPackets[2];
    TypeIpeCrateStatusBlock  crateStatusBlock[2]; //extra buffer for crate status
    //ADC buffer: 2 seconds buffer; 20 FLT * 36 chan = 720 ADCs -> 2*720=1440 Bytes; 100 000 samples per ADC channel -> 144 000 000 Bytes / 1440 Bytes (UDP Packet Size) = 100000 Pakete bzw. 144 MB
    //increased from 1440 to 1500 (packet size)
    char adcBuf[2][kMaxNumUDPDataPackets][kMaxUDPSizeDim/*1500*/];//store the UDP packets
    int adcBufSize[2][kMaxNumUDPDataPackets];//store the size in bytes of the according UDP packet
    int  numDataPackets[2];
    char adcBufReceivedFlag[2][kMaxNumUDPDataPackets];//flag which marks that this packet was received
    int  hasDataPackets[2];
    int  hasDataBytes[2];
    int  numfifo[2];
    int  numADCsInDataStream[2];
    
    int isSynchronized,wrIndex, rdIndex;
    uint32_t dataPacketCounter;
    //trace buffer: reorganized adcBuf to store all 100000 samples of one ADC channel (of 720 ADC channels)
    uint16_t adcTraceBuf[2][kMaxNumADCChan/*720*/][100000];//TODO: allocate dynamically? (I want to use pure C to be able to use it in Obj-C and C++) -tb-
    int32_t adcTraceBufCount[2][kMaxNumADCChan/*720*/];//count filled in shorts in accordingadcTraceBuf[2][720][100000]  -tb-
    
} THREAD_DATA;

THREAD_DATA dataReplyThreadData;

void* receiveFromDataReplyServerThreadFunction (void* p);


void* receiveFromDataReplyServerThreadFunction (void* p)
{
	
	THREAD_DATA *dataReplyThreadData = (THREAD_DATA *)p;
    dataReplyThreadData->hasDataPackets[0]=0;
    dataReplyThreadData->hasDataPackets[1]=0;
    
    //store some vars
    int *wrIndex = &(dataReplyThreadData->wrIndex);//we cannot use references, we are in C, not C++
    //int *rdIndex = &(dataReplyThreadData->rdIndex);//we cannot use references, we are in C, not C++
	int32_t debugCounter=0;
	
	//static int counterStatusPacket=0; //MAH commented out 9/17/2012 to get rid of compiler unused variable warning
//static int counterData1444Packet=0;
	int counterDataPacket=-1;
	int32_t counterDataPacketPayload=-1;
	int counterStatusPacket=-1;
	
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];
	
    const int maxSizeOfReadbuffer=4096*2;
    char readBuffer[maxSizeOfReadbuffer];
	
	int retval=-1;
	
	
	int64_t l=0;
	int doRunLoop=true;
	dataReplyThreadData->started = 1;
	do{
	    l++;
		//usleep(10000);
		//NSLog(@"xxxxCalled    receiveFromDataReplyServerThreadFunction: %i stop %i started %i\n",l,dataReplyThreadData->stopNow,dataReplyThreadData->started);//TODO: DEBUG -tb-
		
		//
		//if(![dataReplyThreadData->model isListeningOnDataServerSocket]){
		if(dataReplyThreadData->stopNow){
			dataReplyThreadData->stopNow=0;
			dataReplyThreadData->started=0;
			NSLog(@"Called    receiveFromDataReplyServerThreadFunction with stopNow : %i \n",l);//TODO: DEBUG -tb-
			doRunLoop=false;//finish for loop
		}
		if(!dataReplyThreadData->isListeningOnDataServerSocket){
			dataReplyThreadData->stopNow=0;
			dataReplyThreadData->started=0;
			NSLog(@"Called    receiveFromDataReplyServerThreadFunction with !isListeningOnDataServerSocket : %i \n",l);//TODO: DEBUG -tb-
			//NSLog(@"Called %@::%@  requestStoppingDataServerSocket:%i loop:%i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , requestStoppingDataServerSocket,l);//TODO: DEBUG -tb-
			//requestStoppingDataServerSocket=0;
			//break;
			doRunLoop=false;//finish for loop
		}
		//init
		retval=-1;
		socklen_t  sockaddr_data_fromLength = sizeof(dataReplyThreadData->sockaddr_data_from);
		
		
		retval = recvfrom(dataReplyThreadData->UDP_DATA_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &dataReplyThreadData->sockaddr_data_from, &sockaddr_data_fromLength);
	    //printf("recvfromGlobalServer retval:  %i, maxSize %i\n",retval,maxSizeOfReadbuffer);
		//if(retval==-1) break;
		if(retval==-1) continue;
	    if(retval>=0 && retval != 1444){ //TODO: warning if a packet is too small - outdated since 2014-01-08, when UDP size is variable -tb-
	        //printf("recvfromGlobalServer retval:  %i (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        //TODO: this overloads now the Orca display ... NSLog(@"     receiveFromDataReplyServerThreadFunction: Got UDP data from %s!  \n", inet_ntoa(dataReplyThreadData->sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
	        //TODO: this overloads now the Orca display ... NSLog(@"     receiveFromDataReplyServerThreadFunction: Got UDP data from %s!  \n", inet_ntoa(dataReplyThreadData->sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
			
	    }
        
#if 0
        
        int counterData1444Packet=counterDataPacket;

	    if(retval == 1444 && counterData1444Packet==0){
	        NSLog(@"     receiveFromDataReplyServerThreadFunction: Got UDP data packet from %s!  \n",  inet_ntoa(dataReplyThreadData->sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
			int i;
			uint16_t *shorts=(uint16_t *)readBuffer;
			NSMutableString *s = [[NSMutableString alloc] init];
			[s setString:@""];
  #if 0
			//TODO: using this the sequence is reverted!!!!! eg. 0x4122 0x4111 0x4244 0x4133 ....
			for(i=0;i<16;i++){
			    [s appendFormat:@" 0x%04x",shorts[i]];
			}
  #else
			for(i=0;i<8;i++){
			    [s appendFormat:@" 0x%04x",shorts[i*2+1]];
			    [s appendFormat:@" 0x%04x",shorts[i*2]];
			}
  #endif
			NSLog(@"%@\n",s);
		}
		
		//give some debug output
		if(retval>0){
			
			if(retval>=4){
				uint32_t *hptr = (uint32_t *)(readBuffer);
				uint16_t *h16ptr = (uint16_t *)(readBuffer);
				uint16_t *h16ptr2 = (uint16_t *)(&readBuffer[2]);
				if(retval==1444) counterData1444Packet++;
				else{
					if(counterData1444Packet>0) NSLog(@"  received %i data packets with 1444 bytes  \n",counterData1444Packet);
					NSLog(@"      received data packet w. header 0x%08x, 0x%04x,0x%04x, length %i\n",*hptr,*h16ptr,*h16ptr2,retval);
					NSLog(@"      bytes: %i\n",counterData1444Packet * 1440 + retval -4);
					counterData1444Packet=0;
				}
			}
		}
#endif
        
        //handle known data packets:
        //
        if(retval>4){
            uint32_t *hptr = (uint32_t *)(readBuffer);
            char *ptr=readBuffer;
            //--->synchro status packet
            if(retval==284 && (*hptr == 0x0000ffff)){
                //this is a 'old' status packet, skip parsing
				NSLog(@"    -- Found a OLD STYLE Status packet: header 0x%08x , size %i, skip parsing!\n",*hptr, retval);
                continue;
            }
            if((*hptr == 0x0000ffff) || (*hptr == 0x0000fffe) ){//this is a synchro or status packet
                TypeStatusHeader *header = (TypeStatusHeader *)readBuffer;
				NSLog(@"  Found a Status packet: header 0x%08x ,     length (bytes) %i \n",header->identifiant ,retval);
                //let ptr point to first statusBlock 
                ptr += sizeof(TypeStatusHeader);
                if(header->identifiant == 0x0000ffff){//this is a synchro status packet: first packet is a TypeIpeCrateStatusBlock
                    TypeIpeCrateStatusBlock *crateStatusBlock=(TypeIpeCrateStatusBlock *)ptr;
				    NSLog(@"  IPE crate status block:     PPS %i (0x%08x)\n",crateStatusBlock->PPS_count,crateStatusBlock->PPS_count);
				    NSLog(@"                              SLT time: %llu \n",((((unsigned long long) crateStatusBlock->SLTTimeHigh) << 32) | crateStatusBlock->SLTTimeLow) );
				    NSLog(@"      OperaStatus1 0x%08x (d0: %i)\n",crateStatusBlock->OperaStatus1,crateStatusBlock->OperaStatus1 & 0xfff);
				    NSLog(@"      size_bytes: %i \n",crateStatusBlock->size_bytes);
				    NSLog(@"      version: %i \n",crateStatusBlock->version);
				    NSLog(@"      numFIFOnumADCs: 0x%08x (%i,%i)\n",crateStatusBlock->numFIFOnumADCs,(crateStatusBlock->numFIFOnumADCs&0xffff0000)>>16,crateStatusBlock->numFIFOnumADCs % 0xffff);
                    uint32_t ps=crateStatusBlock->prog_status;
				    if(ps>0)NSLog(@"      prog_status: 0x%08x: stat: %i  percent:%i%c \n",ps,ps&0xf, (ps>>8)&0xfff,'%');
                    //if not a prog_status packet, prepare write buffer
                    
                    
                    //prepare toggling buffer (finish the current write buffer before!)
                    if(dataReplyThreadData->isSynchronized){
                        //we got a new synchro packet -> toggle buffers
                        if(dataReplyThreadData->rdIndex!=-1){
                            dataReplyThreadData->rdIndex=dataReplyThreadData->wrIndex;
                            dataReplyThreadData->wrIndex=(dataReplyThreadData->wrIndex+1) % 2; //toggle between 0 and 1
                        }else{//we were in the first cycle
                            dataReplyThreadData->rdIndex=0;
                            dataReplyThreadData->wrIndex=1; 
                        }
                        //mark as "ready for readout"
                        dataReplyThreadData->hasDataPackets[dataReplyThreadData->rdIndex]=counterDataPacket;
                        dataReplyThreadData->hasDataBytes[dataReplyThreadData->rdIndex]  =counterDataPacketPayload;
                    }else{
                        //now we are synchronized the first time in this cycle! init!
                        dataReplyThreadData->isSynchronized=1;
                        dataReplyThreadData->wrIndex=0; 
                        dataReplyThreadData->rdIndex=-1;
                    }
                    //(re)start counter for status and data packets
                    dataReplyThreadData->numStatusPackets[*wrIndex]=0;
                    dataReplyThreadData->numDataPackets[*wrIndex]=0;

                    //store some infos from status packet in buffer -> added 2013-04: store ALL status packets -tb-
                    uint32_t numfifo= (crateStatusBlock->numFIFOnumADCs >> 16) & 0xffff;
                    uint32_t numADCsInDataStream=crateStatusBlock->numFIFOnumADCs & 0xffff;
                    if(numADCsInDataStream>0) NSLog(@"  numfifo: %i    numADCs In Data Stream: %i \n",numfifo, numADCsInDataStream);
                    dataReplyThreadData->numfifo[*wrIndex]=numfifo;
                    dataReplyThreadData->numADCsInDataStream[*wrIndex]=numADCsInDataStream;
                    //    we buffer the whole crate status block ...
                    memcpy(&(dataReplyThreadData->crateStatusBlock[*wrIndex]), crateStatusBlock, sizeof(TypeIpeCrateStatusBlock));
                    //if we are synchronized, "reset" write buffer (reset flags)
                    #if 1
                    memset(dataReplyThreadData->adcBufReceivedFlag[*wrIndex],0,kMaxNumUDPDataPackets);
                    #else
                    int i;
                    for(i=0;i<kMaxNumUDPDataPackets; i++){
                        dataReplyThreadData->adcBufReceivedFlag[*wrIndex][i]=0;
                    }
                    #endif
                    if(counterDataPacket>0){
				        NSLog(@"  counterDataPacket:      %i    read ADC bytes: %i\n",counterDataPacket,counterDataPacketPayload);
                    }
                    //reset counter for next "round"
                    counterDataPacket=0;
                    counterDataPacketPayload=0;
                    //let ptr point behind current block (usually the first TypeBBStatusBlock )
                    ptr += crateStatusBlock->size_bytes;
                    //debugging
                    debugCounter++;
                }else{
				    NSLog(@"  BB status block UDP  packet:    id %i \n",header->identifiant);
                }

                //buffer this status packet for Orca
                counterStatusPacket=dataReplyThreadData->numStatusPackets[*wrIndex];
                if((counterStatusPacket < kMaxNumUDPStatusPackets) && (retval<1500)){
                    memcpy(&(dataReplyThreadData->statusBuf[*wrIndex][counterStatusPacket]), readBuffer, retval);
                    dataReplyThreadData->statusBufSize[*wrIndex][counterStatusPacket]=retval;
                    dataReplyThreadData->numStatusPackets[*wrIndex]++;
                }else{
                    //the buffer is full, skip succeeding packets (show a warning?) -tb-
                }

                

                //this is a BB status packet (or BB status blocks following the crate status block ...)
#if 1
                //--->BB status packet(s)
                TypeBBStatusBlock *BBblock;
                int BBblockLen, counter=0;
                BBblock=(TypeBBStatusBlock*)ptr;
                BBblockLen = BBblock->size_bytes; 
                while(BBblockLen>0){
                    counter++;
                    //error check
                    if(BBblockLen > MAX_UDP_STATUSPACKET_SIZE){  //is 1480
				        NSLog(@"      ERROR: BBblockLen %i exceeds max. len %i: corrupted UDP packet? \n",BBblockLen,SIZEOF_UDPStructIPECrateStatus);
                        break;
                    }
                    //print some output
				    NSLog(@"      BB status packet: block %i , length (bytes) %i, FLT #%i, fiber #%i, status: 0x%04x 0x%04x ... \n",
                                 counter,BBblock->size_bytes,BBblock->fltIndex +1,BBblock->fiberIndex +1,BBblock->bb_status[0],BBblock->bb_status[1]);
                    unsigned char* myptr = (unsigned char*)ptr;
                    //NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	                NSFont* aFont = [NSFont fontWithName:@"Monaco" size:11];
                    
				    NSLogFont(aFont,@"  0:   %02x %02x %02x %02x     %02x %02x %02x %02x     %02x %02x %02x %02x     %02x %02x %02x %02x \n",
                                 myptr[0],myptr[1],myptr[2],myptr[3],myptr[4],myptr[5],myptr[6],myptr[7],
                                 myptr[8],myptr[9],myptr[10],myptr[11],myptr[12],myptr[13],myptr[14],myptr[15]);
				    NSLogFont(aFont,@" 16:   %02x %02x %02x %02x     %02x %02x %02x %02x     %02x %02x %02x %02x     %02x %02x %02x %02x \n",
                                 myptr[16],myptr[17],myptr[18],myptr[19],myptr[20],myptr[21],myptr[22],myptr[23],
                                 myptr[24],myptr[25],myptr[26],myptr[27],myptr[28],myptr[29],myptr[30],myptr[31]);
                    //let ptr point to next TypeBBStatusBlock 
                    ptr += BBblockLen;
                    if((ptr-readBuffer) > MAX_UDP_STATUSPACKET_SIZE){
				        NSLog(@"    -- ERROR: prt behind MAX_UDP_STATUSPACKET_SIZE(%):  %i  , skip parsing!\n",MAX_UDP_STATUSPACKET_SIZE, ptr-readBuffer);
                        continue;
                    }
                    BBblock=(TypeBBStatusBlock*)ptr;
                    BBblockLen = BBblock->size_bytes;
                    if((ptr-readBuffer) > MAX_UDP_STATUSPACKET_SIZE){  //is 1480
				        NSLog(@"      WARNING: pointer pos %i exceeds max. pos %i: corrupted UDP packet? \n",ptr-readBuffer,SIZEOF_UDPStructIPECrateStatus);
                        break;
                    }
                }
#endif
            }else{//if((*hptr == 0x0000ffff) || (*hptr == 0x0000fffe) ) ... 
                int i;
                //all other packets are data packets
                //1. extract timestamp and packet number
                uint16_t *adc16ptr = (uint16_t *)(readBuffer);
                if(adc16ptr[0] == 0){//its the first packet -> debug output of some data
			        NSMutableString *s = [[NSMutableString alloc] init];
			        [s setString:@""];
 			        for(i=0;i<8;i++){
			            [s appendFormat:@" 0x%04x",adc16ptr[i*2]];
			            [s appendFormat:@" 0x%04x",adc16ptr[i*2+1]];
			        }
 	         		NSLog(@"UDP0:%@\n",s);
                }
                //copy UDP packet to buffer
                size_t size=retval;
                int index = adc16ptr[0];
                if(size<1500 && index<kMaxNumUDPDataPackets){
                    if(dataReplyThreadData->adcBufReceivedFlag[*wrIndex][index]==1){//error; already received this packet number
 	         		    //NSLog(@"ERROR: received packet %i at least twice!!!!!!\n", index);
                    }
                    memcpy(dataReplyThreadData->adcBuf[*wrIndex][index], readBuffer, size);//copy UDP packet with header
                    dataReplyThreadData->adcBufSize[*wrIndex][index]=size;
                    if(debugCounter<2 && index <2){
                        NSLog(@"copy   packet with index %i num %i TS %i (size %i (%i))\n", index, adc16ptr[0],adc16ptr[1], size, dataReplyThreadData->adcBufSize[*wrIndex][index]);
                    }
                    dataReplyThreadData->adcBufReceivedFlag[*wrIndex][index]=1;
                    dataReplyThreadData->numDataPackets[*wrIndex]++;
                    counterDataPacket++;
                    counterDataPacketPayload += size-4;//subtract header
                }else{
                }
            }

        }//if(retval>4) ... smaller packets are corrupted (must contain at least the 4 byte header)

	}while(doRunLoop);//for(l ...
	
	
	
	NSLog(@"     >>>>>>>>>>>>> receiveFromDataReplyServerThreadFunction: loop FINISHED  \n");
	dataReplyThreadData->stopNow=0;
	dataReplyThreadData->started=0;
	
	
	
    return (void*)0;
}




#pragma mark ***External Strings

NSString* OREdelweissSLTModelSaveIonChanFilterOutputRecordsChanged = @"OREdelweissSLTModelSaveIonChanFilterOutputRecordsChanged";
NSString* OREdelweissSLTModelFifoForUDPDataPortChanged = @"OREdelweissSLTModelFifoForUDPDataPortChanged";
NSString* OREdelweissSLTModelUseStandardUDPDataPortsChanged = @"OREdelweissSLTModelUseStandardUDPDataPortsChanged";
NSString* OREdelweissSLTModelResetEventCounterAtRunStartChanged = @"OREdelweissSLTModelResetEventCounterAtRunStartChanged";
NSString* OREdelweissSLTModelLowLevelRegInHexChanged = @"OREdelweissSLTModelLowLevelRegInHexChanged";
NSString* OREdelweissSLTModelStatusRegHighChanged = @"OREdelweissSLTModelStatusRegHighChanged";
NSString* OREdelweissSLTModelStatusRegLowChanged = @"OREdelweissSLTModelStatusRegLowChanged";
NSString* OREdelweissSLTModelTakeADCChannelDataChanged = @"OREdelweissSLTModelTakeADCChannelDataChanged";
NSString* OREdelweissSLTModelTakeRawUDPDataChanged = @"OREdelweissSLTModelTakeRawUDPDataChanged";
NSString* OREdelweissSLTModelChargeBBFileChanged = @"OREdelweissSLTModelChargeBBFileChanged";
NSString* OREdelweissSLTModelUseBroadcastIdBBChanged = @"OREdelweissSLTModelUseBroadcastIdBBChanged";
NSString* OREdelweissSLTModelIdBBforWCommandChanged = @"OREdelweissSLTModelIdBBforWCommandChanged";
NSString* OREdelweissSLTModelTakeEventDataChanged = @"OREdelweissSLTModelTakeEventDataChanged";
NSString* OREdelweissSLTModelTakeUDPstreamDataChanged = @"OREdelweissSLTModelTakeUDPstreamDataChanged";
NSString* OREdelweissSLTModelCrateUDPDataCommandChanged = @"OREdelweissSLTModelCrateUDPDataCommandChanged";
NSString* OREdelweissSLTModelBBCmdFFMaskChanged = @"OREdelweissSLTModelBBCmdFFMaskChanged";
NSString* OREdelweissSLTModelCmdWArg4Changed = @"OREdelweissSLTModelCmdWArg4Changed";
NSString* OREdelweissSLTModelCmdWArg3Changed = @"OREdelweissSLTModelCmdWArg3Changed";
NSString* OREdelweissSLTModelCmdWArg2Changed = @"OREdelweissSLTModelCmdWArg2Changed";
NSString* OREdelweissSLTModelCmdWArg1Changed = @"OREdelweissSLTModelCmdWArg1Changed";
NSString* OREdelweissSLTModelSltDAQModeChanged = @"OREdelweissSLTModelSltDAQModeChanged";
NSString* OREdelweissSLTModelNumRequestedUDPPacketsChanged = @"OREdelweissSLTModelNumRequestedUDPPacketsChanged";
NSString* OREdelweissSLTModelIsListeningOnDataServerSocketChanged = @"OREdelweissSLTModelIsListeningOnDataServerSocketChanged";
NSString* OREdelweissSLTModelOpenCloseDataCommandSocketChanged = @"OREdelweissSLTModelOpenCloseDataCommandSocketChanged";
NSString* OREdelweissSLTModelCrateUDPDataReplyPortChanged = @"OREdelweissSLTModelCrateUDPDataReplyPortChanged";
NSString* OREdelweissSLTModelCrateUDPDataIPChanged = @"OREdelweissSLTModelCrateUDPDataIPChanged";
NSString* OREdelweissSLTModelCrateUDPDataPortChanged = @"OREdelweissSLTModelCrateUDPDataPortChanged";
NSString* OREdelweissSLTModelEventFifoStatusRegChanged = @"OREdelweissSLTModelEventFifoStatusRegChanged";
NSString* OREdelweissSLTModelPixelBusEnableRegChanged = @"OREdelweissSLTModelPixelBusEnableRegChanged";
NSString* OREdelweissSLTModelSelectedFifoIndexChanged = @"OREdelweissSLTModelSelectedFifoIndexChanged";
NSString* OREdelweissSLTModelIsListeningOnServerSocketChanged = @"OREdelweissSLTModelIsListeningOnServerSocketChanged";
NSString* OREdelweissSLTModelCrateUDPCommandChanged = @"OREdelweissSLTModelCrateUDPCommandChanged";
NSString* OREdelweissSLTModelCrateUDPReplyPortChanged = @"OREdelweissSLTModelCrateUDPReplyPortChanged";
NSString* OREdelweissSLTModelCrateUDPCommandIPChanged = @"OREdelweissSLTModelCrateUDPCommandIPChanged";
NSString* OREdelweissSLTModelCrateUDPCommandPortChanged = @"OREdelweissSLTModelCrateUDPCommandPortChanged";
NSString* OREdelweissSLTModelSecondsSetInitWithHostChanged = @"OREdelweissSLTModelSecondsSetInitWithHostChanged";
NSString* OREdelweissSLTModelSltScriptArgumentsChanged = @"OREdelweissSLTModelSltScriptArgumentsChanged";

NSString* OREdelweissSLTModelClockTimeChanged = @"OREdelweissSLTModelClockTimeChanged";
NSString* OREdelweissSLTModelRunTimeChanged = @"OREdelweissSLTModelRunTimeChanged";
NSString* OREdelweissSLTModelVetoTimeChanged = @"OREdelweissSLTModelVetoTimeChanged";
NSString* OREdelweissSLTModelDeadTimeChanged = @"OREdelweissSLTModelDeadTimeChanged";
NSString* OREdelweissSLTModelSecondsSetChanged		= @"OREdelweissSLTModelSecondsSetChanged";
NSString* OREdelweissSLTModelStatusRegChanged		= @"OREdelweissSLTModelStatusRegChanged";
NSString* OREdelweissSLTModelControlRegChanged		= @"OREdelweissSLTModelControlRegChanged";
NSString* OREdelweissSLTModelFanErrorChanged		= @"OREdelweissSLTModelFanErrorChanged";
NSString* OREdelweissSLTModelVttErrorChanged		= @"OREdelweissSLTModelVttErrorChanged";
NSString* OREdelweissSLTModelGpsErrorChanged		= @"OREdelweissSLTModelGpsErrorChanged";
NSString* OREdelweissSLTModelClockErrorChanged		= @"OREdelweissSLTModelClockErrorChanged";
NSString* OREdelweissSLTModelPpsErrorChanged		= @"OREdelweissSLTModelPpsErrorChanged";
NSString* OREdelweissSLTModelPixelBusErrorChanged	= @"OREdelweissSLTModelPixelBusErrorChanged";
NSString* OREdelweissSLTModelHwVersionChanged		= @"OREdelweissSLTModelHwVersionChanged";

NSString* OREdelweissSLTModelPatternFilePathChanged		= @"OREdelweissSLTModelPatternFilePathChanged";
NSString* OREdelweissSLTModelInterruptMaskChanged		= @"OREdelweissSLTModelInterruptMaskChanged";
NSString* OREdelweissSLTPulserDelayChanged				= @"OREdelweissSLTPulserDelayChanged";
NSString* OREdelweissSLTPulserAmpChanged				= @"OREdelweissSLTPulserAmpChanged";
NSString* OREdelweissSLTSettingsLock					= @"OREdelweissSLTSettingsLock";
NSString* OREdelweissSLTStatusRegChanged				= @"OREdelweissSLTStatusRegChanged";
NSString* OREdelweissSLTControlRegChanged				= @"OREdelweissSLTControlRegChanged";
NSString* OREdelweissSLTSelectedRegIndexChanged			= @"OREdelweissSLTSelectedRegIndexChanged";
NSString* OREdelweissSLTWriteValueChanged				= @"OREdelweissSLTWriteValueChanged";
NSString* OREdelweissSLTModelNextPageDelayChanged		= @"OREdelweissSLTModelNextPageDelayChanged";
NSString* OREdelweissSLTModelPollRateChanged			= @"OREdelweissSLTModelPollRateChanged";

NSString* OREdelweissSLTModelPageSizeChanged			= @"OREdelweissSLTModelPageSizeChanged";
NSString* OREdelweissSLTModelDisplayTriggerChanged		= @"OREdelweissSLTModelDisplayTrigerChanged";
NSString* OREdelweissSLTModelDisplayEventLoopChanged	= @"OREdelweissSLTModelDisplayEventLoopChanged";
NSString* OREdelweissSLTV4cpuLock							= @"OREdelweissSLTV4cpuLock";

@interface OREdelweissSLTModel (private)
- (unsigned long) read:(unsigned long) address;
- (void) write:(unsigned long) address value:(unsigned long) aValue;
@end

@implementation OREdelweissSLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
	pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	[self setSecondsSetInitWithHost: YES];
	[self registerNotificationObservers];
	//some defaults
	crateUDPCommandPort = 9940;
	crateUDPCommandIP = @"localhost";
	crateUDPReplyPort = 9940;
    crateUDPDataPort = 9941;
    crateUDPDataIP = @"192.168.1.100";
    crateUDPDataReplyPort = 9941;
	
    return self;
}

-(void) dealloc
{
    [chargeBBFile release];
    [crateUDPDataCommand release];
    [crateUDPDataIP release];
    [crateUDPCommand release];
    [crateUDPCommandIP release];
    [sltScriptArguments release];
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [poller stop];
    [poller release];
	[pmcLink setDelegate:nil];
	[pmcLink release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[pmcLink wakeUp];
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
	[pmcLink sleep];
    [poller stop];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(!pmcLink){
			pmcLink = [[PMC_Link alloc] initWithDelegate:self];
		}
		[pmcLink connect];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"EdelweissSLTCard"]]; }
- (void) makeMainController	{ [self linkToController:@"OREdelweissSLTController"];		}
- (Class) guardianClass		{ return NSClassFromString(@"ORIpeV4CrateModel");		}

- (void) setGuardian:(id)aGuardian //-tb-
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
	else {
		[[self guardian] setAdapter:nil];
	}
	[super setGuardian:aGuardian];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];

    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsBetweenSubRuns:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsStartingSubRun:)
                         name : ORRunStartSubRunNotification
                       object : nil];


}

#pragma mark •••Accessors

- (BOOL) saveIonChanFilterOutputRecords
{
    return saveIonChanFilterOutputRecords;
}

- (void) setSaveIonChanFilterOutputRecords:(BOOL)aSaveIonChanFilterOutputRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSaveIonChanFilterOutputRecords:saveIonChanFilterOutputRecords];
    
    saveIonChanFilterOutputRecords = aSaveIonChanFilterOutputRecords;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSaveIonChanFilterOutputRecordsChanged object:self];
}

- (int) fifoForUDPDataPort
{
    return fifoForUDPDataPort;
}

- (void) setFifoForUDPDataPort:(int)aFifoForUDPDataPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoForUDPDataPort:fifoForUDPDataPort];
    fifoForUDPDataPort = aFifoForUDPDataPort;
    if(fifoForUDPDataPort==0) fifoForUDPDataPort=0;
    if(fifoForUDPDataPort>5) fifoForUDPDataPort=5;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelFifoForUDPDataPortChanged object:self];
    if(useStandardUDPDataPorts){
        [self setCrateUDPDataPort: 9941 + fifoForUDPDataPort];
        [self setCrateUDPDataReplyPort: 9941 + fifoForUDPDataPort];
    }
}

- (int) useStandardUDPDataPorts
{
    return useStandardUDPDataPorts;
}

- (void) setUseStandardUDPDataPorts:(int)aUseStandardUDPDataPorts
{
    int oldState=useStandardUDPDataPorts;
    [[[self undoManager] prepareWithInvocationTarget:self] setUseStandardUDPDataPorts:useStandardUDPDataPorts];
    useStandardUDPDataPorts = aUseStandardUDPDataPorts;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelUseStandardUDPDataPortsChanged object:self];
    if(oldState==0 && useStandardUDPDataPorts){
        [self setCrateUDPDataPort: 9941 + fifoForUDPDataPort];
        [self setCrateUDPDataReplyPort: 9941 + fifoForUDPDataPort];
    }
}

- (int) resetEventCounterAtRunStart
{
    return resetEventCounterAtRunStart;
}

- (void) setResetEventCounterAtRunStart:(int)aResetEventCounterAtRunStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setResetEventCounterAtRunStart:resetEventCounterAtRunStart];
    
    resetEventCounterAtRunStart = aResetEventCounterAtRunStart;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelResetEventCounterAtRunStartChanged object:self];
}

- (int) lowLevelRegInHex
{
    return lowLevelRegInHex;
}

- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowLevelRegInHex:lowLevelRegInHex];

    lowLevelRegInHex = aLowLevelRegInHex;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelLowLevelRegInHexChanged object:self];
}

- (unsigned long) statusHighReg
{
    return statusHighReg;
}

- (void) setStatusHighReg:(unsigned long)aStatusRegHigh
{
    statusHighReg = aStatusRegHigh;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelStatusRegHighChanged object:self];
}

- (unsigned long) statusLowReg
{
    return statusLowReg;
}

- (void) setStatusLowReg:(unsigned long)aStatusRegLow
{
    statusLowReg = aStatusRegLow;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelStatusRegLowChanged object:self];
}

- (int) takeADCChannelData
{
    return takeADCChannelData;
}

- (void) setTakeADCChannelData:(int)aTakeADCChannelData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeADCChannelData:takeADCChannelData];
    
    takeADCChannelData = aTakeADCChannelData;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelTakeADCChannelDataChanged object:self];
}

- (int) takeRawUDPData
{
    return takeRawUDPData;
}

- (void) setTakeRawUDPData:(int)aTakeRawUDPData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeRawUDPData:takeRawUDPData];
    takeRawUDPData = aTakeRawUDPData;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelTakeRawUDPDataChanged object:self];
}

- (NSString *) chargeBBFile
{
    if(chargeBBFile==0) return @"";
    return chargeBBFile;
}

- (void) setChargeBBFile:(NSString *)aChargeBBFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChargeBBFile:chargeBBFile];
    [chargeBBFile autorelease];
    chargeBBFile = [aChargeBBFile copy];    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelChargeBBFileChanged object:self];
}

- (bool) useBroadcastIdBB
{
    return useBroadcastIdBB;
}

- (void) setUseBroadcastIdBB:(bool)aUseBroadcastIdBB
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseBroadcastIdBB:useBroadcastIdBB];
    useBroadcastIdBB = aUseBroadcastIdBB;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelUseBroadcastIdBBChanged object:self];
}

- (int) idBBforWCommand
{
    return idBBforWCommand;
}

- (void) setIdBBforWCommand:(int)aIdBBforWCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIdBBforWCommand:idBBforWCommand];
    idBBforWCommand = aIdBBforWCommand;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelIdBBforWCommandChanged object:self];
}

- (int) takeEventData
{
    return takeEventData;
}

- (void) setTakeEventData:(int)aTakeEventData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeEventData:takeEventData];
    takeEventData = aTakeEventData;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelTakeEventDataChanged object:self];
}

- (int) takeUDPstreamData
{
    return takeUDPstreamData;
}

- (void) setTakeUDPstreamData:(int)aTakeUDPstreamData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeUDPstreamData:takeUDPstreamData];
    takeUDPstreamData = aTakeUDPstreamData;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelTakeUDPstreamDataChanged object:self];
}

- (NSString*) crateUDPDataCommand
{
	if(!crateUDPDataCommand) return @"";
    return crateUDPDataCommand;
}

- (void) setCrateUDPDataCommand:(NSString*)aCrateUDPDataCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataCommand:crateUDPDataCommand];
    
    [crateUDPDataCommand autorelease];
    crateUDPDataCommand = [aCrateUDPDataCommand copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataCommandChanged object:self];
}

- (uint32_t) BBCmdFFMask
{
    return BBCmdFFMask;
}

- (void) setBBCmdFFMask:(uint32_t)aBBCmdFFMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBBCmdFFMask:BBCmdFFMask];
    BBCmdFFMask = aBBCmdFFMask & 0xff;//is only 8 bit
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelBBCmdFFMaskChanged object:self];
}

- (int) cmdWArg4
{
    return cmdWArg4;
}

- (void) setCmdWArg4:(int)aCmdWArg4
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdWArg4:cmdWArg4];
    cmdWArg4 = aCmdWArg4;
    if(cmdWArg4<0) cmdWArg4=0;     if(cmdWArg4>0xff) cmdWArg4=0xff; 
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCmdWArg4Changed object:self];
}

- (int) cmdWArg3
{
    return cmdWArg3;
}

- (void) setCmdWArg3:(int)aCmdWArg3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdWArg3:cmdWArg3];
    cmdWArg3 = aCmdWArg3;
    if(cmdWArg3<0) cmdWArg3=0;     if(cmdWArg3>0xff) cmdWArg3=0xff; 
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCmdWArg3Changed object:self];
}

- (int) cmdWArg2
{
    return cmdWArg2;
}

- (void) setCmdWArg2:(int)aCmdWArg2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdWArg2:cmdWArg2];
    cmdWArg2 = aCmdWArg2;
    if(cmdWArg2<0) cmdWArg2=0;     if(cmdWArg2>0xff) cmdWArg2=0xff; 
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCmdWArg2Changed object:self];
}

- (int) cmdWArg1
{
    return cmdWArg1;
}

- (void) setCmdWArg1:(int)aCmdWArg1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdWArg1:cmdWArg1];
    cmdWArg1 = aCmdWArg1;
    if(cmdWArg1<0) cmdWArg1=0;     if(cmdWArg1>0xff) cmdWArg1=0xff; 
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCmdWArg1Changed object:self];
}

- (int) sltDAQMode
{
    return sltDAQMode;
}

- (void) setSltDAQMode:(int)aSltDAQMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSltDAQMode:sltDAQMode];
    sltDAQMode = aSltDAQMode;
    if(sltDAQMode<0) sltDAQMode=0;
    if(sltDAQMode>4) sltDAQMode=4;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSltDAQModeChanged object:self];
}

- (int) numRequestedUDPPackets
{
    return numRequestedUDPPackets;
}

- (void) setNumRequestedUDPPackets:(int)aNumRequestedUDPPackets
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumRequestedUDPPackets:numRequestedUDPPackets];
    numRequestedUDPPackets = aNumRequestedUDPPackets;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelNumRequestedUDPPacketsChanged object:self];
}

- (int) isListeningOnDataServerSocket
{
    return isListeningOnDataServerSocket;
}

- (void) setIsListeningOnDataServerSocket:(int)aIsListeningOnDataServerSocket
{
    isListeningOnDataServerSocket = aIsListeningOnDataServerSocket;
	dataReplyThreadData.isListeningOnDataServerSocket=isListeningOnDataServerSocket;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelIsListeningOnDataServerSocketChanged object:self];
}


- (int) requestStoppingDataServerSocket
{
    return requestStoppingDataServerSocket;
}

- (void) setRequestStoppingDataServerSocket:(int)aValue
{
    requestStoppingDataServerSocket = aValue;
    dataReplyThreadData.stopNow=aValue;

}

- (int) crateUDPDataReplyPort
{
    return crateUDPDataReplyPort;
}

- (void) setCrateUDPDataReplyPort:(int)aCrateUDPDataReplyPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataReplyPort:crateUDPDataReplyPort];
    crateUDPDataReplyPort = aCrateUDPDataReplyPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataReplyPortChanged object:self];
}

- (NSString*) crateUDPDataIP
{
    return crateUDPDataIP;
}

- (void) setCrateUDPDataIP:(NSString*)aCrateUDPDataIP
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataIP:crateUDPDataIP];
    [crateUDPDataIP autorelease];
    crateUDPDataIP = [aCrateUDPDataIP copy];    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataIPChanged object:self];
}

- (int) crateUDPDataPort
{
    return crateUDPDataPort;
}

- (void) setCrateUDPDataPort:(int)aCrateUDPDataPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataPort:crateUDPDataPort];
    crateUDPDataPort = aCrateUDPDataPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPDataPortChanged object:self];
}

- (unsigned long) eventFifoStatusReg
{
    return eventFifoStatusReg;
}

- (void) setEventFifoStatusReg:(unsigned long)aEventFifoStatusReg
{
    eventFifoStatusReg = aEventFifoStatusReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelEventFifoStatusRegChanged object:self];
}

- (unsigned long) pixelBusEnableReg
{
    return pixelBusEnableReg;
}

- (void) setPixelBusEnableReg:(unsigned long)aPixelBusEnableReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPixelBusEnableReg:pixelBusEnableReg];
    pixelBusEnableReg = aPixelBusEnableReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelPixelBusEnableRegChanged object:self];
}

- (int) selectedFifoIndex
{
    return selectedFifoIndex;
}

- (void) setSelectedFifoIndex:(int)aSelectedFifoIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedFifoIndex:selectedFifoIndex];
    selectedFifoIndex = aSelectedFifoIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSelectedFifoIndexChanged object:self];
}

- (int) isListeningOnServerSocket
{
    return isListeningOnServerSocket;
}

- (void) setIsListeningOnServerSocket:(int)aIsListeningOnServerSocket
{
    isListeningOnServerSocket = aIsListeningOnServerSocket;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelIsListeningOnServerSocketChanged object:self];
}

- (NSString*) crateUDPCommand
{
	if(!crateUDPCommand) return @"";
    return crateUDPCommand;
}

- (void) setCrateUDPCommand:(NSString*)aCrateUDPCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommand:crateUDPCommand];
    [crateUDPCommand autorelease];
    crateUDPCommand = [aCrateUDPCommand copy];    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPCommandChanged object:self];
}

- (int) crateUDPReplyPort
{
    return crateUDPReplyPort;
}

- (void) setCrateUDPReplyPort:(int)aCrateUDPReplyPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPReplyPort:crateUDPReplyPort];
    crateUDPReplyPort = aCrateUDPReplyPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPReplyPortChanged object:self];
}

- (NSString*) crateUDPCommandIP
{
	if(!crateUDPCommandIP) return @"";
    return crateUDPCommandIP;
}

- (void) setCrateUDPCommandIP:(NSString*)aCrateUDPCommandIP
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommandIP:crateUDPCommandIP];
    //crateUDPCommandIP = aCrateUDPCommandIP;
    [crateUDPCommandIP autorelease];
    crateUDPCommandIP = [aCrateUDPCommandIP copy];    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPCommandIPChanged object:self];
}

- (int) crateUDPCommandPort
{
    return crateUDPCommandPort;
}

- (void) setCrateUDPCommandPort:(int)aCrateUDPCommandPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommandPort:crateUDPCommandPort];
    crateUDPCommandPort = aCrateUDPCommandPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelCrateUDPCommandPortChanged object:self];
}
- (BOOL) secondsSetInitWithHost
{
    return secondsSetInitWithHost;
}

- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSetInitWithHost:secondsSetInitWithHost];
    secondsSetInitWithHost = aSecondsSetInitWithHost;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSecondsSetInitWithHostChanged object:self];
}

- (NSString*) sltScriptArguments
{
	if(!sltScriptArguments)return @"";
    return sltScriptArguments;
}

- (void) setSltScriptArguments:(NSString*)aSltScriptArguments
{
	if(!aSltScriptArguments)aSltScriptArguments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSltScriptArguments:sltScriptArguments];

    [sltScriptArguments autorelease];
    sltScriptArguments = [aSltScriptArguments copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelSltScriptArgumentsChanged object:self];
	
	//NSLog(@"%@::%@  is %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),sltScriptArguments);//TODO: debug -tb-
}

- (unsigned long long) clockTime //TODO: rename to 'time' ? -tb-
{
    return clockTime;
}

- (void) setClockTime:(unsigned long long)aClockTime
{
    clockTime = aClockTime;
 	//NSLog(@"   %@::%@:   clockTime: 0x%016qx from aClockTime: 0x%016qx   \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),clockTime , aClockTime);//TODO: DEBUG testing ...-tb-
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelClockTimeChanged object:self];
}


- (unsigned long) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(unsigned long)aStatusReg
{
    statusReg = aStatusReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelStatusRegChanged object:self];
}

- (unsigned long) controlReg
{
    return controlReg;
}

- (void) setControlReg:(unsigned long)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    controlReg = aControlReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelControlRegChanged object:self];
}

- (unsigned long) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (unsigned long) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (unsigned long) implementation  { return hwVersion & kImplemention;}
- (unsigned long) hwVersion       { return hwVersion ;}//=SLT FPGA version/revision

- (void) setHwVersion:(unsigned long) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelHwVersionChanged object:self];	
}


- (void) writeEvRes				{ [self writeReg:kEWSltV4CommandReg value:kEWCmdEvRes];   }
- (void) writeFwCfg				{ [self writeReg:kEWSltV4CommandReg value:kEWCmdFwCfg];   }
- (void) writeSltReset			{ [self writeReg:kEWSltV4CommandReg value:kEWCmdSltReset];   }
- (void) writeFltReset			{ [self writeReg:kEWSltV4CommandReg value:kEWCmdFltReset];   }

- (id) controllerCard		{ return self;	  }
- (SBC_Link*)sbcLink		{ return pmcLink; } 
- (bool)sbcIsConnected      { return [pmcLink isConnected]; }
- (bool)crateCPUIsConnected { return [self sbcIsConnected]; }

- (TimedWorker *) poller	{ return poller;  }

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
	[self readAllStatus];
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
    [poller runWithTarget:self selector:@selector(readAllStatus)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}


- (void) runIsAboutToStart:(NSNotification*)aNote
{
	//TODO: reset of timers probably should be done here -tb-2011-01
	#if 0 
		NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	#endif
}

- (void) runIsStopped:(NSNotification*)aNote
{	
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	//NSLog(@"%@::%@  [readOutGroup count] is %i!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[readOutGroup count]);//TODO: debug -tb-

	//writing the SLT time counters is done in runTaskStopped:userInfo:   -tb-
	//see SBC_Link.m, runIsStopping:userInfo:: if(runInfo.amountInBuffer > 0)... this is data sent out during 'Stop()...' of readout code, e.g.
	//the histogram (2060 int32_t's per histogram and one extra word) -tb-

	// Stop all activities by software inhibit
	if([readOutGroup count] == 0){//TODO: I don't understand this - remove it? -tb-
		//[self writeSetInhibit];
        //TODO: maybe set OnLine bit to 0????? But: this is for steam mode ... -tb- 2012-July
	}
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	// run counter is shipped in runTaskStopped:userInfo: -tb-
	
	//NSLog(@"Deadtime: %lld\n", [self readDeadTime]);
}

- (void) runIsBetweenSubRuns:(NSNotification*)aNote
{
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	[self shipSltSecondCounter: kStopSubRunType];
	//TODO: I could set inhibit to measure the 'netto' run time precisely -tb-
}


- (void) runIsStartingSubRun:(NSNotification*)aNote
{
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	[self shipSltSecondCounter: kStartSubRunType];
}


#pragma mark •••Accessors

- (NSString*) patternFilePath
{
    return patternFilePath;
}

- (void) setPatternFilePath:(NSString*)aPatternFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternFilePath:patternFilePath];
	
	if(!aPatternFilePath)aPatternFilePath = @"";
    [patternFilePath autorelease];
    patternFilePath = [aPatternFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelPatternFilePathChanged object:self];
}

- (unsigned long) nextPageDelay
{
	return nextPageDelay;
}

- (void) setNextPageDelay:(unsigned long)aDelay
{	
	if(aDelay>102400) aDelay = 102400;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNextPageDelay:nextPageDelay];
    
    nextPageDelay = aDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelNextPageDelayChanged object:self];
	
}

- (unsigned long) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelInterruptMaskChanged object:self];
}

- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}

- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}

- (NSMutableArray*) children 
{
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}


- (float) pulserDelay
{
    return pulserDelay;
}

- (void) setPulserDelay:(float)aPulserDelay
{
	if(aPulserDelay<100)		 aPulserDelay = 100;
	else if(aPulserDelay>3276.7) aPulserDelay = 3276.7;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserDelay:pulserDelay];
    
    pulserDelay = aPulserDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTPulserDelayChanged object:self];
}

- (float) pulserAmp
{
    return pulserAmp;
}

- (void) setPulserAmp:(float)aPulserAmp
{
	if(aPulserAmp>4)aPulserAmp = 4;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserAmp:pulserAmp];
    
    pulserAmp = aPulserAmp;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kEWSltV4NumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddress: (short) anIndex
{
    return( regV4[anIndex].addressOffset>>2);
}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissSLTSelectedRegIndexChanged
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissSLTWriteValueChanged
	 object:self];
}


- (BOOL) displayTrigger
{
	return displayTrigger;
}

- (void) setDisplayTrigger:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayTrigger:displayTrigger];
	displayTrigger = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelDisplayEventLoopChanged object:self];
	
}

- (unsigned long) pageSize
{
	return pageSize;
}

- (void) setPageSize: (unsigned long) aPageSize
{
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
	
    if (aPageSize > 100) pageSize = 100;
	else pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelPageSizeChanged object:self];
	
}  

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendSimulationConfigScriptON
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
	//[self sendPMCCommandScript: @"SimulationConfigScriptON"];
	[self sendPMCCommandScript: [NSString stringWithFormat:@"%@ %i",@"SimulationConfigScriptON",[pmcLink portNumber]]];//send the port number, too

	#if 0
	NSString *scriptName = @"EdelweissSLTScript";
		ORTaskSequence* aSequence;	
		aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
		
		NSString* driverCodePath; //[pmcLink ]
		if([pmcLink loadMode])driverCodePath = [[pmcLink filePath] stringByAppendingPathComponent:[self sbcLocalCodePath]];
		else driverCodePath = [resourcePath stringByAppendingPathComponent:[self codeResourcePath]];
		//driverCodePath = [driverCodePath stringByAppendingPathComponent:[delegate driverScriptName]];
		driverCodePath = [driverCodePath stringByAppendingPathComponent: scriptName];
		ORFileMover* driverScriptFileMover = [[ORFileMover alloc] init];//TODO: keep it as object in the class variables -tb-
		[driverScriptFileMover setDelegate:aSequence];
NSLog(@"loadMode: %i driverCodePath: %@ \n",[pmcLink loadMode], driverCodePath);		
		[driverScriptFileMover setMoveParams:[driverCodePath stringByExpandingTildeInPath]
										to:@"" 
								remoteHost:[pmcLink IPNumber] 
								  userName:[pmcLink userName] 
								  passWord:[pmcLink passWord]];
		[driverScriptFileMover setVerbose:YES];
		[driverScriptFileMover doNotMoveFilesToSentFolder];
		[driverScriptFileMover setTransferType:eUseSCP];
		[aSequence addTaskObj:driverScriptFileMover];
		
		//NSString* scriptRunPath = [NSString stringWithFormat:@"/home/%@/%@",[pmcLink userName],scriptName];
		NSString* scriptRunPath = [NSString stringWithFormat:@"~/%@",scriptName];
NSLog(@"  scriptRunPath: %@ \n" , scriptRunPath);		
		[aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"] 
				 arguments:[NSArray arrayWithObjects:[pmcLink userName],[pmcLink passWord],[pmcLink IPNumber],scriptRunPath,
				 //@"arg1",@"arg2",nil]];
				 //@"shellcommand",@"ls",@"&&",@"date",@"&&",@"ps",nil]];
				 //@"shellcommand",@"ls",@"-laF",nil]];
				 @"shellcommand",@"ls",@"-l",@"-a",@"-F",nil]];  //limited to 6 arguments (see loginScript)
				 //TODO: use sltScriptArguments -tb-
		
		[aSequence launch];
		#endif

}

/*! Send a script to the PrPMC which will configure the PrPMC.
 */
- (void) sendSimulationConfigScriptOFF
{
	//NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
	[self sendPMCCommandScript: @"SimulationConfigScriptOFF"];
}

- (void) installIPE4reader
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	
	[self sendPMCCommandScript: @"InstallIpe4reader"];
}

- (void) installAndCompileIPE4reader
{
	NSLog(@"%@::%@: under construction.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	
	[self sendPMCCommandScript: @"InstallAndCompileIpe4reader"];
}

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendPMCCommandScript: (NSString*)aString;
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 


	NSArray *scriptcommands = nil;//limited to 6 arguments (see loginScript)
	if(aString) scriptcommands = [aString componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([scriptcommands count] >6) NSLog(@"WARNING: too much arguments in sendPMCConfigScript:\n");
	
	NSString *scriptName = @"IpeEdelweissV4SLTScript";
		ORTaskSequence* aSequence;	
		aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
		
		NSString* driverCodePath; //[pmcLink ]
		if([pmcLink loadMode])driverCodePath = [[pmcLink filePath] stringByAppendingPathComponent:[self sbcLocalCodePath]];
		else driverCodePath = [resourcePath stringByAppendingPathComponent:[self codeResourcePath]];
		//driverCodePath = [driverCodePath stringByAppendingPathComponent:[delegate driverScriptName]];
		driverCodePath = [driverCodePath stringByAppendingPathComponent: scriptName];
		ORFileMover* driverScriptFileMover = [[ORFileMover alloc] init];//TODO: keep it as object in the class variables -tb-
		[driverScriptFileMover setDelegate:aSequence];
NSLog(@"loadMode: %i driverCodePath: %@ \n",[pmcLink loadMode], driverCodePath);		
		[driverScriptFileMover setMoveParams:[driverCodePath stringByExpandingTildeInPath]
										to:@"" 
								remoteHost:[pmcLink IPNumber] 
								  userName:[pmcLink userName] 
								  passWord:[pmcLink passWord]];
		[driverScriptFileMover setVerbose:YES];
		[driverScriptFileMover doNotMoveFilesToSentFolder];
		[driverScriptFileMover setTransferType:eUseSCP];
		[aSequence addTaskObj:driverScriptFileMover];
		
		//NSString* scriptRunPath = [NSString stringWithFormat:@"/home/%@/%@",[pmcLink userName],scriptName];
		NSString* scriptRunPath = [NSString stringWithFormat:@"~/%@",scriptName];
NSLog(@"  scriptRunPath: %@ \n" , scriptRunPath);	

	    //prepare script commands/arguments
		NSMutableArray *arguments = nil;
		arguments = [NSMutableArray arrayWithObjects:[pmcLink userName],[pmcLink passWord],[pmcLink IPNumber],scriptRunPath,nil];
		[arguments addObjectsFromArray:	scriptcommands];
NSLog(@"  arguments: %@ \n" , arguments);	
	
		//add task
		[aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"] 
				 arguments: arguments];  //limited to 6 arguments (see loginScript)

		
		[aSequence launch];

}





#pragma mark ***UDP Communication

//  UDP K command connection   -------------------------------
//reply socket (server)
- (int) startListeningServerSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-

    int status, retval=0;

	if(UDP_REPLY_SERVER_SOCKET>0) [self stopListeningServerSocket];//still open, first close the socket
	UDP_REPLY_SERVER_SOCKET = socket ( AF_INET, SOCK_DGRAM, IPPROTO_UDP );
	if (UDP_REPLY_SERVER_SOCKET==-1){
        //fprintf(stderr, "initUDPServerSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	//fprintf(stderr, "initGlobalUDPServerSocket: socket(...) created socket %i\n",GLOBAL_UDP_SERVER_SOCKET);
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_REPLY_SERVER_SOCKET);//TODO: DEBUG -tb-


	UDP_REPLY_servaddr.sin_family = AF_INET; 
	UDP_REPLY_servaddr.sin_port = htons (crateUDPReplyPort);

	char  GLOBAL_UDP_SERVER_IP_ADDR[1024]="0.0.0.0";//TODO: this might be necessary for hosts with several network adapters -tb-


	retval=inet_aton(GLOBAL_UDP_SERVER_IP_ADDR,&UDP_REPLY_servaddr.sin_addr);
	int GLOBAL_UDP_SERVER_IP = UDP_REPLY_servaddr.sin_addr.s_addr;//this is already in network byte order!!!
	printf("  inet_aton: retval: %i,IP_ADDR: %s, IP %i (0x%x)\n",retval,GLOBAL_UDP_SERVER_IP_ADDR,crateUDPReplyPort,GLOBAL_UDP_SERVER_IP);
	//GLOBAL_servaddr.sin_addr.s_addr =  htonl(GLOBAL_UDP_SERVER_IP);// INADDR_ANY = 0x00000000 = 0  ;   192.168.1.9  = 0xc0a80109  ;   192.168.1.34   = 0xc0a80122
	status = bind(UDP_REPLY_SERVER_SOCKET,(struct sockaddr *) &UDP_REPLY_servaddr,sizeof(UDP_REPLY_servaddr));
	if (status==-1) {
		printf("    ERROR starting UDP server .. -tb- continue, ignore error -tb-\n");
	    NSLog(@"    ERROR starting UDP server (bind: err %i) .. probably port already used ! (-tb- continue, ignore error -tb-)\n", status);//TODO: DEBUG -tb-
		//return 2 ; //-tb- continue, ignore error -tb-
	}
	printf("  serveur udp ouvert avec servaddr.sin_addr.s_addr=%s \n",inet_ntoa(UDP_REPLY_servaddr.sin_addr));
	listen(UDP_REPLY_SERVER_SOCKET,5);  //TODO: is this necessary? what does it mean exactly? -tb-
	                                    //TODO: is this necessary? what does it mean exactly? -tb-
 printf("  UDP SERVER is listening for K command reply on port %u\n",crateUDPReplyPort);
   if(crateUDPReplyPort<1024) printf("  NOTE,WARNING: initUDPServerSocket: UDP SERVER is listening on port %u, using ports below 1024 requires to run as 'root'!\n",crateUDPReplyPort);


    retval=0;//no error


	[self setIsListeningOnServerSocket: 1];
	//start polling
	if(	[self isListeningOnServerSocket]) [self performSelector:@selector(receiveFromReplyServer) withObject:nil afterDelay: 0];

    return retval;//retval=0: OK, else error
	
	return 0;
}

- (void) stopListeningServerSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    if(UDP_REPLY_SERVER_SOCKET>-1) close(UDP_REPLY_SERVER_SOCKET);
    UDP_REPLY_SERVER_SOCKET = -1;
	
	[self setIsListeningOnServerSocket: 0];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromReplyServer) object:nil];
}

- (int) openServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	
	return 0;
}

- (void) closeServerSocket
{
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
}



- (int) receiveFromReplyServer
{

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromReplyServer) object:nil];

    const int maxSizeOfReadbuffer=4096;
    char readBuffer[maxSizeOfReadbuffer];

	int retval=-1;
    sockaddr_fromLength = sizeof(sockaddr_from);
    //while( (retval = recvfrom(MY_UDP_SERVER_SOCKET, (char*)InBuffer,sizeof(InBuffer) , MSG_DONTWAIT,(struct sockaddr *) &servaddr, &AddrLength)) >0 ){
    retval = recvfrom(UDP_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &sockaddr_from, &sockaddr_fromLength);
	    //printf("recvfromGlobalServer retval:  %i, maxSize %i\n",retval,maxSizeOfReadbuffer);
	    if(retval>=0){
	        //printf("recvfromGlobalServer retval:  %i (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        NSLog(@" %@::%@ Got UDP data from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_from.sin_addr));//TODO: DEBUG -tb-

	    }
	//handle K commands
	if(retval>0){
	    //check for K command replies:
	    switch(readBuffer[0]){
	    case 'K':
	        readBuffer[retval]='\0';//make null terminated string for printf
	        //printf("Received reply to K command: >%s<\n",readBuffer);
	        NSLog(@"    Received reply to K command: >%s<\n", readBuffer);//TODO: DEBUG -tb-
	        //handleKCommand(readBuffer, retval, &sockaddr_from);
	        break;
	    default:
	        readBuffer[retval]='\0';//make null terminated string for printf
	        //printf("Received unknown command: >%s<\n",readBuffer);
			if(retval < 100)
	            NSLog(@"    Received message with length %i: >%s<\n", retval, readBuffer);//TODO: DEBUG -tb-
			else
	            NSLog(@"    Received message with length %i: first 4 bytes 0x%08x\n", retval, *((uint16_t*)readBuffer));//TODO: DEBUG -tb-
	        break;
	    }
		
		//if(   *((uint16_t*)readBuffer) & 0xFFD0    )
		
		
		//check for data packets:
		if(   *((uint16_t*)readBuffer) == 0xFFD0   /*&&  retval==1480*/){// reply to KRC_IPECrateStatus command
	        NSLog(@"    Received IPECrateStatus message with length %i\n", retval);//TODO: DEBUG -tb-
			UDPStructIPECrateStatus *status = (UDPStructIPECrateStatus *)readBuffer;
			NSLog(@"    Header0: 0x%04x,  Header1: 0x%04x\n",status->id0, status->id1);
			NSLog(@"    presentFLTMap: 0x%08x \n",status->presentFLTMap );
//			NSLog(@"    reserved0: 0x%08x,  reserved1: 0x%08x\n",status->reserved0, status->reserved1);
			
			int i;
			NSLog(@"    SLT Block: \n");
			for(i=0; i<IPE_BLOCK_SIZE; i++){
			    NSLog(@"        SLT[%i]: 0x%08x \n",i,status->SLT[i] );
			}
			int f;
			for(f=0; f<MAX_NUM_FLT_CARDS; f++){
			    if(status->presentFLTMap & (0x1 <<f)){
    			    NSLog(@"    FLT #%i Block: \n",f);
	    		    for(i=0; i<IPE_BLOCK_SIZE; i++){
		    	        NSLog(@"        FLT #%i [%i]: 0x%08x \n",f,i,status->FLT[f][i] );
			        }
				}
				else
				{
		    	        NSLog(@"     FLT #%i not present \n",f);
				}

			}

			NSLog(@"    IPAdressMap: \n");
			for(i=0; i<MAX_NUM_FLT_CARDS; i++){
			    NSLog(@"        IPAdressMap[%i]: 0x%08x    Port: %i (0x%04x)\n",i,status->IPAdressMap[i], status->PortMap[i], status->PortMap[i]);
			}
		}
	}
	
	if(	[self isListeningOnServerSocket]) [self performSelector:@selector(receiveFromReplyServer) withObject:nil afterDelay: 0];

    return retval;
}



//command socket (client)
- (int) openCommandSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
	
	if(UDP_COMMAND_CLIENT_SOCKET>0) [self closeCommandSocket];//still open, first close the socket
	
	//almost a copy from ipe4reader6.cpp
    int retval=0;
    if ((UDP_COMMAND_CLIENT_SOCKET=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1){
        //fprintf(stderr, "initGlobalUDPClientSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_COMMAND_CLIENT_SOCKET);//TODO: DEBUG -tb-
	
  #if 1 //do it in sendToGlobalClient3 again?
    sockaddrin_to_len=sizeof(UDP_COMMAND_sockaddrin_to);
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort); //take global variable MY_UDP_CLIENT_PORT //TODO: was PORT, remove PORT
  if (inet_aton([crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "inet_aton() failed\n");
	return 2;
    //exit(1);
  }
	NSLog(@" %@::%@  UDP Client: IP: %s, port: %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,[crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);//TODO: DEBUG -tb-
    //fprintf(stderr, "    initGlobalUDPClientSocket: UDP Client: IP: %s, port: %i\n",[crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);
  #endif
  
	
	
	return retval;
}

- (void) closeCommandSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
      if(UDP_COMMAND_CLIENT_SOCKET>-1) close(UDP_COMMAND_CLIENT_SOCKET);
      UDP_COMMAND_CLIENT_SOCKET = -1;
}

- (int) isOpenCommandSocket
{
	if(UDP_COMMAND_CLIENT_SOCKET>0) return 1; else return 0;
}





- (int) sendUDPCommand
#if 1
{
    return [self sendUDPCommandString: crateUDPCommand];
}
#else
{ //this was the first version, moved everything to 'sendUDPCommandString:' -tb-
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
	NSLog(@"Called %@::%@! Send string: >%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  [self crateUDPCommand]);//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    const void *buffer   = [[crateUDPCommand dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	size_t length        = [crateUDPCommand lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	int retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort);
  if (inet_aton([crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient3: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPCommandPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
    return retval;

}
#endif

/*
- (int) sendUDPCommandString:(NSString*)aString
EXAMPLES:
//[slt sendUDPCommandString:@"KWC_stopStreamLoop"];
//[slt sendUDPCommandString:@"KWC_startStreamLoop"];

//[slt sendUDPCommandString:@"KWC_chargeBBFile_/home/katrin/bbv2.rbf"];
//print("Call [slt sendUDPDataCommand:...]");
//[slt sendUDPDataCommandString: "KWC_chargeBBFile_/home/katrin/bbv2.rbf" ];

//cmdWArg1=
//[slt sendUDPDataWCommandRequestPacketArg1: cmdWArg1 arg2: cmdWArg2 arg3: cmdWArg3  arg4:cmdWArg4];
//debloque
[slt sendUDPDataWCommandRequestPacketArg1: 0x13 arg2: 0xA arg3: 0  arg4:0x6];
//bloque
[slt sendUDPDataWCommandRequestPacketArg1: 0x13 arg2: 0xA arg3: 0  arg4:0x0];
//demarrage
[slt sendUDPDataWCommandRequestPacketArg1: 0x13 arg2: 0xA arg3: 0  arg4:0x7];


alim
alim          = 0x01; 
cmd_autorisee = 0x02;
comprime      = 0x10;
carte_rapide  = 0x20;
status_diff   = 0x40;

arg4= alim | cmd_autorisee | status_diff;
[slt sendUDPDataWCommandRequestPacketArg1: 0xFF arg2: 0xA arg3: 0  arg4: arg4 ];

if( 0){
aSize=10;
array a[aSize];
a[0]=123;
a[1]=2;
i=0;
for(i=0;i<aSize;i++) print "a[",  i   ,"] is ",a[i];
}


 write FiberOutMask ...
[slt sendUDPCommandString:@"KRF_0x01_0x00000018"];
[slt sendUDPCommandString:@"KWF_0x01_0x00000018_0x00000001"];
[slt sendUDPCommandString:@"KRF_0x01_0x00000018"];

[slt sendUDPCommandString:@"KRF_0x02_0x00000018"];
[slt sendUDPCommandString:@"KWF_0x02_0x00000018_0x00000001"];



[slt sendUDPCommandString:@"KWC_restartKCommandSockets"];
[slt sendUDPCommandString:@"KWL_GLOBAL_UDP_CLIENT_PORT: 9942"];
[slt sendUDPCommandString:@"KWC_restartKCommandSockets"];


if(0){
[slt sendUDPCommandString:@"KWC_stopStreamLoop"];
[slt sendUDPCommandString:@"KWL_FLTstreamMask1(3):       0x00003f3f"];
[slt sendUDPCommandString:@"KWC_startStreamLoop"];
}


commands:
  KWC_init
  KWC_startStreamLoop
  KWC_coldStart
  KWC_stopStreamLoop
  KWC_reloadConfigFile
  KWC_reset
  KWC_restartKCommandSockets
  KWC_exit


*/
- (int) sendUDPCommandString:(NSString*)aString
{
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
	NSLog(@"Called %@::%@! Send string: >%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  aString);//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	int retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort);
  if (inet_aton([crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient3: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPCommandPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
    return retval;

}






//  UDP data packet connection ---------------------
//reply socket (server)
- (int) startListeningDataServerSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-

    int status, retval=0;

	if(UDP_DATA_REPLY_SERVER_SOCKET>0) [self stopListeningDataServerSocket];//still open, first close the socket
	UDP_DATA_REPLY_SERVER_SOCKET = socket ( AF_INET, SOCK_DGRAM, IPPROTO_UDP );
	if (UDP_DATA_REPLY_SERVER_SOCKET==-1){
        //fprintf(stderr, "initUDPServerSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	//fprintf(stderr, "initGlobalUDPServerSocket: socket(...) created socket %i\n",GLOBAL_UDP_SERVER_SOCKET);
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_DATA_REPLY_SERVER_SOCKET);//TODO: DEBUG -tb-


	UDP_DATA_REPLY_servaddr.sin_family = AF_INET; 
	UDP_DATA_REPLY_servaddr.sin_port = htons (crateUDPDataReplyPort);

	char  GLOBAL_UDP_SERVER_IP_ADDR[1024]="0.0.0.0";//TODO: this might be necessary for hosts with several network adapters -tb-


	retval=inet_aton(GLOBAL_UDP_SERVER_IP_ADDR,&UDP_DATA_REPLY_servaddr.sin_addr);
	int GLOBAL_UDP_SERVER_IP = UDP_DATA_REPLY_servaddr.sin_addr.s_addr;//this is already in network byte order!!!
	printf("  inet_aton: retval: %i,IP_ADDR: %s, IP %i (0x%x)\n",retval,GLOBAL_UDP_SERVER_IP_ADDR,crateUDPDataReplyPort,GLOBAL_UDP_SERVER_IP);
	//GLOBAL_servaddr.sin_addr.s_addr =  htonl(GLOBAL_UDP_SERVER_IP);// INADDR_ANY = 0x00000000 = 0  ;   192.168.1.9  = 0xc0a80109  ;   192.168.1.34   = 0xc0a80122
	status = bind(UDP_DATA_REPLY_SERVER_SOCKET,(struct sockaddr *) &UDP_DATA_REPLY_servaddr,sizeof(UDP_DATA_REPLY_servaddr));
	if (status==-1) {
		printf("    ERROR starting UDP server .. -tb- continue, ignore error -tb-\n");
	    NSLog(@"    ERROR starting UDP server (bind: err %i) .. probably port already used ! (-tb- continue, ignore error -tb-)\n", status);//TODO: DEBUG -tb-
		//return 2 ; //-tb- continue, ignore error -tb-
	}
	printf("  serveur udp ouvert avec servaddr.sin_addr.s_addr=%s \n",inet_ntoa(UDP_DATA_REPLY_servaddr.sin_addr));
	listen(UDP_DATA_REPLY_SERVER_SOCKET,5);  //TODO: is this necessary? what does it mean exactly? -tb-
	                                    //TODO: is this necessary? what does it mean exactly? -tb-
 printf("  UDP DATA SERVER is listening for data packets (data and status) on port %u\n",crateUDPDataReplyPort);
   if(crateUDPDataReplyPort<1024) printf("  NOTE,WARNING: startListeningDataServerSocket: UDP DATA SERVER is listening on port %u, using ports below 1024 requires to run as 'root'!\n",crateUDPDataReplyPort);


    retval=0;//no error


	[self setIsListeningOnDataServerSocket: 1];
	//start polling
	if(	[self isListeningOnDataServerSocket]) 
	[self performSelector:@selector(receiveFromDataReplyServer) withObject:nil afterDelay: 0];

    return retval;//retval=0: OK, else error
	
	return 0;
}


- (void) stopListeningDataServerSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    if(UDP_DATA_REPLY_SERVER_SOCKET>-1) close(UDP_DATA_REPLY_SERVER_SOCKET);
    UDP_DATA_REPLY_SERVER_SOCKET = -1;
	
	[self setIsListeningOnDataServerSocket: 0];
    ////TODO: a test -tb-
	dataReplyThreadData.stopNow=1;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];
}





- (int) receiveFromDataReplyServer
{
//TODO: changed to pthreads - needs cleanup -tb-
// code moved to void* receiveFromDataReplyServerThreadFunction (void* p)
 
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];

#if 0
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];
	//static int counterStatusPacket=0; //MAH commented out 9/17/2012 to get rid of compiler unused variable warning
	static int counterData1444Packet=0;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromDataReplyServer) object:nil];

    const int maxSizeOfReadbuffer=4096*2;
    char readBuffer[maxSizeOfReadbuffer];

	int retval=-1;
	
	
int l;
for(l=0;l<2500;l++){
//usleep(10000);
	    //NSLog(@"xxxCalled %@::%@  requestStoppingDataServerSocket:%i loop:%i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , requestStoppingDataServerSocket,l);//TODO: DEBUG -tb-
    //
	if(requestStoppingDataServerSocket==1){
	    NSLog(@"Called %@::%@  requestStoppingDataServerSocket:%i loop:%i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , requestStoppingDataServerSocket,l);//TODO: DEBUG -tb-
	    requestStoppingDataServerSocket=0;
	    break;//finish for loop
	}
	//init
	retval=-1;
    sockaddr_data_fromLength = sizeof(sockaddr_data_from);
	
	
    //while( (retval = recvfrom(MY_UDP_SERVER_SOCKET, (char*)InBuffer,sizeof(InBuffer) , MSG_DONTWAIT,(struct sockaddr *) &servaddr, &AddrLength)) >0 ){
    retval = recvfrom(UDP_DATA_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &sockaddr_data_from, &sockaddr_data_fromLength);
	    //printf("recvfromGlobalServer retval:  %i, maxSize %i\n",retval,maxSizeOfReadbuffer);
	//if(retval==-1) break;
	if(retval==-1) continue;
	    if(retval>=0 && retval != 1444){
	        //printf("recvfromGlobalServer retval:  %i (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        NSLog(@" %@::%@ Got UDP data from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-

	    }
	    if(retval == 1444 && counterData1444Packet==0){
	        NSLog(@" %@::%@ Got UDP data packet from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
			int i;
			uint16_t *shorts=(uint16_t *)readBuffer;
			NSMutableString *s = [[NSMutableString alloc] init];
			[s setString:@""];
			#if 0
			//TODO: using this the sequence is reverted!!!!! eg. 0x4122 0x4111 0x4244 0x4133 ....
			for(i=0;i<16;i++){
			    [s appendFormat:@" 0x%04x",shorts[i]];
			}
			#else
			for(i=0;i<8;i++){
			    [s appendFormat:@" 0x%04x",shorts[i*2+1]];
			    [s appendFormat:@" 0x%04x",shorts[i*2]];
			}
			#endif
			NSLog(@"%@\n",s);
		}
		
	//give some debug output
	if(retval>0){
	
	    if(retval>=4){
		    uint32_t *hptr = (uint32_t *)(readBuffer);
		    uint16_t *h16ptr = (uint16_t *)(readBuffer);
		    uint16_t *h16ptr2 = (uint16_t *)(&readBuffer[2]);
			if(retval==1444) counterData1444Packet++;
			else{
		        if(counterData1444Packet>0) NSLog(@"  received %i data packets with 1444 bytes  \n",counterData1444Packet);
		        NSLog(@"  received data packet w header 0x%08x, 0x%04x,0x%04x, length %i\n",*hptr,*h16ptr,*h16ptr2,retval);
		        NSLog(@"  bytes: %i\n",counterData1444Packet * 1440 + retval -4);
				counterData1444Packet=0;
			}
		}

	
	
	}
}//for(l ...
//NSLog(@"retval: %i, l=%i\n",retval,l); with one fiber we had ca. 12 packets per loop ...
	if(	[self isListeningOnDataServerSocket]) [self performSelector:@selector(receiveFromDataReplyServer) withObject:nil afterDelay: 0];




#else
	int retval=-1;

    dataReplyThreadData.model = self;
    dataReplyThreadData.started = 0;
    dataReplyThreadData.stopNow = 0;
    dataReplyThreadData.sockaddr_data_from = sockaddr_data_from;
    dataReplyThreadData.UDP_DATA_REPLY_SERVER_SOCKET = UDP_DATA_REPLY_SERVER_SOCKET;
    dataReplyThreadData.isSynchronized=0;
   
   //is it OK to call it again? when destroy it? -tb-
   pthread_create(&dataReplyThread, NULL, receiveFromDataReplyServerThreadFunction, (void*) &dataReplyThreadData);
     //note: pthread_create is not blocking -tb-

 //NSLog(@"retval: %i, l=%i\n",retval,l); with one fiber we had ca. 12 packets per loop ...
	//if(	[self isListeningOnDataServerSocket]) [self performSelector:@selector(receiveFromDataReplyServer) withObject:nil afterDelay: 0];

#endif

    return retval;
}





//command data socket (client)
- (int) openDataCommandSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
	
	if(UDP_DATA_COMMAND_CLIENT_SOCKET>0) [self closeDataCommandSocket];//still open, first close the socket
	
	//almost a copy from ipe4reader6.cpp
    int retval=0;
    if ((UDP_DATA_COMMAND_CLIENT_SOCKET=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP))==-1){
        //fprintf(stderr, "openDataCommandSocket: socket(...) failed\n");
	    NSLog(@" %@::%@  socket(...) failed!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        //diep("socket");
	    return 1;
    }
	NSLog(@" %@::%@  created socket %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_DATA_COMMAND_CLIENT_SOCKET);//TODO: DEBUG -tb-
	
  #if 1 //do it in sendToGlobalClient... again?
  memset((char *) &UDP_DATA_COMMAND_sockaddrin_to, 0, sizeof(UDP_DATA_COMMAND_sockaddrin_to));
  UDP_DATA_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_DATA_COMMAND_sockaddrin_to.sin_port = htons(crateUDPDataPort); //take global variable MY_UDP_CLIENT_PORT //TODO: was PORT, remove PORT
  if (inet_aton([crateUDPDataIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_DATA_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "inet_aton() failed\n");
	retval = 2;
    //exit(1);
  }
	NSLog(@" %@::%@  UDP Client: IP: %s, port: %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,[crateUDPDataIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPDataPort);//TODO: DEBUG -tb-
    //fprintf(stderr, "    initGlobalUDPClientSocket: UDP Client: IP: %s, port: %i\n",[crateUDPCommandIP cStringUsingEncoding:NSASCIIStringEncoding] /*crateUDPCommandIP oder %@ benutzen*/,	crateUDPCommandPort);
  #endif
  
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelOpenCloseDataCommandSocketChanged object:self];
	
	return retval;
}



- (void) closeDataCommandSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
      if(UDP_DATA_COMMAND_CLIENT_SOCKET>-1) close(UDP_DATA_COMMAND_CLIENT_SOCKET);
      UDP_DATA_COMMAND_CLIENT_SOCKET = -1;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissSLTModelOpenCloseDataCommandSocketChanged object:self];
}

- (int) isOpenDataCommandSocket
{
	if(UDP_DATA_COMMAND_CLIENT_SOCKET>0) return 1; else return 0;
}

- (int) sendUDPDataCommand:(char*)data length:(int) len
{
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
    #if 0
	NSLog(@"Called %@::%@! Send data ... len %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , len);//TODO: DEBUG -tb-
	int i;
	for(i=0; i<len;i++) NSLog(@"0x%02x  ",data[i]);
	NSLog(@"\n");
    #endif


	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_DATA_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    //const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	//size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
    const void *buffer   = data; 
	size_t length        = len;
	const char* receiverIPAddr = [crateUDPDataIP cStringUsingEncoding: NSASCIIStringEncoding];;

	int retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_DATA_COMMAND_sockaddrin_to, 0, sizeof(UDP_DATA_COMMAND_sockaddrin_to));
  UDP_DATA_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_DATA_COMMAND_sockaddrin_to.sin_port = htons(crateUDPDataPort);
  if (inet_aton([crateUDPDataIP cStringUsingEncoding:NSASCIIStringEncoding], &UDP_DATA_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient3: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPDataPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_DATA_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_DATA_COMMAND_sockaddrin_to, sizeof(UDP_DATA_COMMAND_sockaddrin_to));
    return retval;


}

/* similar to
    - (int) sendUDPCommandString:(NSString*)aString
    but sends over UDP data socket
    */
- (int) sendUDPDataCommandString:(NSString*)aString
{
	NSLog(@"Called %@::%@! Send data socket command: >%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , aString);//TODO: DEBUG -tb-
    const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
    return [self sendUDPDataCommand:(char*)buffer length: length];
}




- (int) sendUDPDataCommandRequestPackets:(int8_t) num
{
    char data[6];
	int len=6;
	data[0]='P';//'P' = 0x50 = P command
	//data[1]=50;//amount of requested data (interpreted as second (?)), standard: 50
	data[1]= num & 0xff;//50;//amount of requested data (interpreted as second (?)), standard: 50
	uint16_t *port=(uint16_t *)(&data[2]);
	*port = [self crateUDPDataReplyPort];
	data[4]=0;//=bolo?
	data[5]=0;//=bolo?
	return [self sendUDPDataCommand: data length: len];	
}


- (int) sendUDPDataCommandRequestUDPData
{
	return [self sendUDPDataCommandRequestPackets:  numRequestedUDPPackets];	
}

- (int) sendUDPDataCommandChargeBBFile
{
    NSString *cmd = [[NSString alloc] initWithFormat: @"KWC_chargeBBFile_%@", [self chargeBBFile]];
	//debug 
    NSLog(@" %@::%@ send KCommand:%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), cmd);//TODO: DEBUG -tb-
    [cmd autorelease]; //MAH 06/11/13 added autorelease to prevent memory leak
	return [self sendUDPDataCommandString:  cmd];	
}



- (void) loopCommandRequestUDPData
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loopCommandRequestUDPData) object:nil];
    if(	[self isOpenDataCommandSocket]) 
        [self sendUDPDataCommandRequestPackets:  30];
    [self performSelector:@selector(loopCommandRequestUDPData) withObject:nil afterDelay: 10.0];//repeat every 10 seconds
}

- (int) sendUDPDataWCommandRequestPacketArg1:(int) arg1 arg2:(int) arg2 arg3:(int) arg3  arg4:(int) arg4
{
	//debug 
    NSLog(@"Called %@::%@ Arg1:0x%x arg2:0x%x arg3:0x%x  arg4:0x%x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), arg1,arg2,arg3,arg4);//TODO: DEBUG -tb-

    char data[6];
	int len=6;
	data[0]='W';//'P' = 0x50 = P command
	data[1]= 0xf0;//cmd
	data[2]= arg1 & 0xff;
	data[3]= arg2 & 0xff;
	data[4]= arg3 & 0xff;
	data[5]= arg4 & 0xff;
	return [self sendUDPDataCommand: data length: len];	
}

- (int) sendUDPDataWCommandRequestPacket
{
    return [self sendUDPDataWCommandRequestPacketArg1: cmdWArg1 arg2: cmdWArg2 arg3: cmdWArg3  arg4:cmdWArg4];
}


- (int) sendUDPDataTab0x0ACommand:(uint32_t) aBBCmdFFMask //send FF Command
{
    int arg1=idBBforWCommand;
    if(useBroadcastIdBB) arg1=0xff;
    
    return [self sendUDPDataWCommandRequestPacketArg1: arg1 arg2: 0x0A arg3: 0x00  arg4:aBBCmdFFMask];
}

- (int) sendUDPDataTabBloqueCommand
{
    int arg1=idBBforWCommand;
    if(useBroadcastIdBB) arg1=0xff;
    return [self sendUDPDataWCommandRequestPacketArg1: arg1 arg2: 0x0A arg3: 0x00  arg4: 0x00];  
}

- (int) sendUDPDataTabDebloqueCommand
{
    int arg1=idBBforWCommand;
    if(useBroadcastIdBB) arg1=0xff;
    return [self sendUDPDataWCommandRequestPacketArg1: arg1 arg2: 0x0A arg3: 0x00  arg4: 0x06];  
}

- (int) sendUDPDataTabDemarrageCommand
{ 
    int arg1=idBBforWCommand;
    if(useBroadcastIdBB) arg1=0xff;
    return [self sendUDPDataWCommandRequestPacketArg1: arg1 arg2: 0x0A arg3: 0x00  arg4: 0x07];  
}



#pragma mark ***HW Access

- (int)           chargeBBWithFile:(char*)data numBytes:(int) numBytes
{


    //DEBUG 	    
    NSLog(@"%@::%@ \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


   long buf32[1024+2]; //cannot exceed size of cmd FIFO
   //uint32_t buf32[257]; //cannot exceed size of cmd FIFO
   int num32ToSend = (numBytes+3)/4 + 1;//round up if not multiple of 4; add 1 for first word containing numBytes
   if(numBytes>1024+2) return -1;
   buf32[0]=numBytes;
   char* buf=(char*)&buf32[1];
   int i;
   for(i=0; i<numBytes; i++) buf[i]=data[i];
   
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
        NSLog(@"%@::%@ buf32[0] before: %i (0x%08x)\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),buf32[0],buf32[0]);//TODO: DEBUG testing ...-tb-    
        NSLog(@"%@::%@ buf32[1] before: %i (0x%08x)\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),buf32[1],buf32[1]);//TODO: DEBUG testing ...-tb-    
		[pmcLink writeGeneral:buf32 operation:kChargeBBWithFile numToWrite:num32ToSend];
        NSLog(@"%@::%@ buf32[0] after: %i (0x%08x)\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),buf32[0],buf32[0]);//TODO: DEBUG testing ...-tb-    
        NSLog(@"%@::%@ buf32[1] after: %i (0x%08x)\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),buf32[1],buf32[1]);//TODO: DEBUG testing ...-tb-    
	}
   
   
   return 0;
}


- (int)           chargeBBusingSBCinBackgroundWithData:(NSData*)theData forFLT:(OREdelweissFLTModel*) aFLT
{

    fltChargingBB = aFLT;

    //DEBUG 	    
    NSLog(@"%@::%@ data length: %i\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),[theData length]);//TODO: DEBUG testing ...-tb-

	if(![pmcLink isConnected]){
		NSLog(@"   ERROR: Crate Computer (PMC) Not Connected!\n"); 
		//[NSException raise:@"Not Connected" format:@"Socket not connected."];
        return 0;
	}
   
   
	
	NSLog(@"Charge BB FPGA\n");
	
	unsigned long numLongs		= ceil([theData length]/4.0); //round up to long word boundary
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination			= kPMC;//kSBC_Command;//kSBC_Process;
	aPacket.cmdHeader.cmdID					= kEdelweissSLTchargeBB;
	aPacket.cmdHeader.numberBytesinPayload	= sizeof(EdelweissSLTchargeBBStruct) + numLongs*sizeof(long);
	
	EdelweissSLTchargeBBStruct* payloadPtr	= (EdelweissSLTchargeBBStruct*)aPacket.payload;
	payloadPtr->fileSize					= [theData length];
	
	const char* dataPtr						= (const char*)[theData bytes];
	//really should be an error check here that the file isn't bigger than the max payload size
	char* p = (char*)payloadPtr + sizeof(EdelweissSLTchargeBBStruct);
	bcopy(dataPtr, p, [theData length]);
	
	@try {
		//launch the load job. The response will be a job status record
		[pmcLink send:&aPacket receive:&aPacket];
		SBC_JobStatusStruct *responsePtr = (SBC_JobStatusStruct*)aPacket.payload;
		long running = responsePtr->running;
		if(running){
			NSLog(@"BB charge in progress on the SBC on the IPE crate.\n");
			[pmcLink monitorJobFor:self statusSelector:@selector(chargeBBStatus:)];
		}
//			NSLog(@"Error Code: %d %s\n",errorCode,aPacket.message);
//			[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
//		}
//		else NSLog(@"Looks like success.\n");
	}
	@catch(NSException* localException) {
		NSLog(@"BB charge failed. %@\n",localException);
		[NSException raise:@"BB charge Failed" format:@"%@",localException];
	}
   
   
   
   
   
   return 0;
}

- (void) chargeBBStatus:(ORSBCLinkJobStatus*) jobStatus
{
	if(![jobStatus running]){
		NSLog(@"SLT job NOT running: job message: %@   progress: %i finalStatus: %i\n",[jobStatus message],[jobStatus  progress],[jobStatus  finalStatus]);
        if(fltChargingBB) [fltChargingBB setProgressOfChargeBB: [jobStatus  progress]];
        if([jobStatus  finalStatus]==666){//job killed
            if(fltChargingBB) [fltChargingBB setProgressOfChargeBB: 101];
        }
        usleep(10000);
        if(fltChargingBB) [fltChargingBB setProgressOfChargeBB: 0];
	}
    else{
		//NSLog(@"SLT: %@   progress: %i\n",[jobStatus message],[jobStatus  progress]);
		NSLog(@"SLT job running: job message: %@   progress: %i finalStatus: %i\n",[jobStatus message],[jobStatus  progress],[jobStatus  finalStatus]);
        if(fltChargingBB) [fltChargingBB setProgressOfChargeBB: [jobStatus  progress]];
    }
}





- (int)           chargeFICusingSBCinBackgroundWithData:(NSData*)theData forFLT:(OREdelweissFLTModel*) aFLT
{

    fltChargingFIC = aFLT;

    //DEBUG 	    
    NSLog(@"%@::%@ data length: %i\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),[theData length]);//TODO: DEBUG testing ...-tb-

	if(![pmcLink isConnected]){
		NSLog(@"   ERROR: Crate Computer (PMC) Not Connected!\n"); 
		//[NSException raise:@"Not Connected" format:@"Socket not connected."];
        return 0;
	}
   
   
	
	NSLog(@"Charge FIC FPGA\n");
	
	unsigned long numLongs		= ceil([theData length]/4.0); //round up to long word boundary
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination			= kPMC;//kSBC_Command;//kSBC_Process;
	aPacket.cmdHeader.cmdID					= kEdelweissSLTchargeFIC;
	aPacket.cmdHeader.numberBytesinPayload	= sizeof(EdelweissSLTchargeBBStruct) + numLongs*sizeof(long);
	
	EdelweissSLTchargeBBStruct* payloadPtr	= (EdelweissSLTchargeBBStruct*)aPacket.payload;
	payloadPtr->fileSize					= [theData length];
	
	const char* dataPtr						= (const char*)[theData bytes];
	//really should be an error check here that the file isn't bigger than the max payload size
	char* p = (char*)payloadPtr + sizeof(EdelweissSLTchargeBBStruct);
	bcopy(dataPtr, p, [theData length]);
	
	@try {
		//launch the load job. The response will be a job status record
		[pmcLink send:&aPacket receive:&aPacket];
		SBC_JobStatusStruct *responsePtr = (SBC_JobStatusStruct*)aPacket.payload;
		long running = responsePtr->running;
		if(running){
			NSLog(@"FIC charge in progress on the SBC on the IPE crate.\n");
			[pmcLink monitorJobFor:self statusSelector:@selector(chargeFICStatus:)];
		}
//			NSLog(@"Error Code: %d %s\n",errorCode,aPacket.message);
//			[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
//		}
//		else NSLog(@"Looks like success.\n");
	}
	@catch(NSException* localException) {
		NSLog(@"FIC charge failed. %@\n",localException);
		[NSException raise:@"FIC charge Failed" format:@"%@",localException];
	}
   
   
   
   
   
   return 0;
}

- (void) chargeFICStatus:(ORSBCLinkJobStatus*) jobStatus
{
	if(![jobStatus running]){
		NSLog(@"SLT job NOT running: job message: %@   progress: %i finalStatus: %i\n",[jobStatus message],[jobStatus  progress],[jobStatus  finalStatus]);
        if(fltChargingFIC) [fltChargingFIC setProgressOfChargeFIC: [jobStatus  progress]];
        if([jobStatus  finalStatus]==666){//job killed
            if(fltChargingFIC) [fltChargingFIC setProgressOfChargeFIC: 101];
        }
        usleep(10000);
        if(fltChargingFIC) [fltChargingFIC setProgressOfChargeFIC: 0];
	}
    else{
		//NSLog(@"SLT: %@   progress: %i\n",[jobStatus message],[jobStatus  progress]);
		NSLog(@"SLT job running: job message: %@   progress: %i finalStatus: %i\n",[jobStatus message],[jobStatus  progress],[jobStatus  finalStatus]);
        if(fltChargingFIC) [fltChargingFIC setProgressOfChargeFIC: [jobStatus  progress]];
    }
}





- (void) killSBCJob
{
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination			= kSBC_Process;//kSBC_Command;//kSBC_Process;
	aPacket.cmdHeader.cmdID					= kSBC_KillJob;
	aPacket.cmdHeader.numberBytesinPayload	= 0;//sizeof(EdelweissSLTchargeBBStruct) + numLongs*sizeof(long);

	@try {
		//launch the load job. The response will be a job status record
        NSLog(@"Sending kSBC_KillJob.\n");
		[pmcLink send:&aPacket receive:&aPacket];
        NSLog(@"Sent kSBC_KillJob.\n");
//			NSLog(@"Error Code: %d %s\n",errorCode,aPacket.message);
//			[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
//		}
//		else NSLog(@"Looks like success.\n");
	}
	@catch(NSException* localException) {
		NSLog(@"kSBC_KillJob command failed. %@\n",localException);
		[NSException raise:@"kSBC_KillJob command failed" format:@"%@",localException];
	}

}



//this uses a general write command
- (int)          writeToCmdFIFO:(char*)data numBytes:(int) numBytes
{


    //DEBUG 	    
    NSLog(@"%@::%@ \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


   long buf32[257]; //cannot exceed size of cmd FIFO
   //uint32_t buf32[257]; //cannot exceed size of cmd FIFO
   int num32ToSend = (numBytes+3)/4 + 1;//round up if not multiple of 4; add 1 for first word containing numBytes
   if(numBytes>1024) return -1;
   buf32[0]=numBytes;
   char* buf=(char*)&buf32[1];
   int i;
   for(i=0; i<numBytes; i++) buf[i]=data[i];
   
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink writeGeneral:buf32 operation:kWriteToCmdFIFO numToWrite:num32ToSend];
	}
   
   
   return 0;
}



- (void)		  readAllControlSettingsFromHW
{
//DEBUG OUTPUT: 	
NSLog(@"WARNING: %@::%@: under construction! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    [self readControlReg];
    [self readPixelBusEnableReg];
}



- (void) checkPresence
{
	@try {
		[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}
/*
- (void) loadPatternFile
{
	NSString* contents = [NSString stringWithContentsOfFile:patternFilePath encoding:NSASCIIStringEncoding error:nil];
	if(contents){
		NSLog(@"loading Pattern file: <%@>\n",patternFilePath);
		NSScanner* scanner = [NSScanner scannerWithString:contents];
		int amplitude;
		[scanner scanInt:&amplitude];
		int i=0;
		int j=0;
		unsigned long time[256];
		unsigned long mask[20][256];
		int len = 0;
		BOOL status;
		while(1){
			status = [scanner scanHexInt:(unsigned*)&time[i]];
			if(!status)break;
			if(time[i] == 0){
				break;
			}
			for(j=0;j<20;j++){
				status = [scanner scanHexInt:(unsigned*)&mask[j][i]];
				if(!status)break;
			}
			i++;
			len++;
			if(i>256)break;
			if(!status)break;
		}
		
		@try {
			//collect all valid cards
			ORIpeFLTModel* cards[20];//TODO: OREdelweissSLTModel -tb-
			int i;
			for(i=0;i<20;i++)cards[i]=nil;
			
			NSArray* allFLTs = [[self crate] orcaObjects];
			NSEnumerator* e = [allFLTs objectEnumerator];
			id aCard;
			while(aCard = [e nextObject]){
				if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;//TODO: is this still true for v4? -tb-
				int index = [aCard stationNumber] - 1;
				if(index<20){
					cards[index] = aCard;
				}
			}
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Test_Mode];
			}
			
			
			[self writeReg:kSltTestpulsAmpl value:amplitude];
			[self writeBlock:SLT_REG_ADDRESS(kSltTimingMemory) 
				  dataBuffer:time
					  length:len
				   increment:1];
			
			
			int j;
			for(j=0;j<20;j++){
				[cards[j] writeTestPattern:mask[j] length:len];
			}
			
			[self swTrigger];
			
			NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"Index|  Time    | Mask                              Amplitude = %5d\n",amplitude);			
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"     |    delta |  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20\n");			
			unsigned int delta = time[0];
			for(i=0;i<len;i++){
				NSMutableString* line = [NSMutableString stringWithFormat:@"  %2d |=%4d=%4d|",i,delta,time[i]];
				delta += time[i];
				for(j=0;j<20;j++){
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"‚Ä¢":"-"];
					else [line appendFormat:@"%3s","="];
				}
				NSLogFont(aFont,@"%@\n",line);
			}
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n",amplitude);			
			
			
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFltV4Katrin_Run_Mode];
			}
			
			
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor],@"Couldn't load Pattern file <%@>\n",patternFilePath);
		}
	}
	else NSLogColor([NSColor redColor],@"Couldn't open Pattern file <%@>\n",patternFilePath);
}

- (void) swTrigger
{
	[self writeReg:kSltSwTestpulsTrigger value:0];
}
*/

- (void) writeReg:(int)index value:(unsigned long)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (void) writeReg:(int)index  forFifo:(int)fifoIndex value:(unsigned long)aValue
{
	[self write: ([self getAddress:index]|(fifoIndex << 14)) value:aValue];
}

- (void)		  rawWriteReg:(unsigned long) address  value:(unsigned long)aValue
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
    [self write: address value: aValue];
}

- (unsigned long) rawReadReg:(unsigned long) address
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
	return [self read: address];

}

- (unsigned long) readReg:(int) index
{
	return [self read: [self getAddress:index]];

}

- (unsigned long) readReg:(int) index forFifo:(int)fifoIndex;
{
	return [ self read: ([self getAddress:index] | (fifoIndex << 14)) ];

}

- (id) writeHardwareRegisterCmd:(unsigned long) regAddress value:(unsigned long) aValue
{
	return [ORPMCReadWriteCommand writeLongBlock:&aValue
									   atAddress:regAddress
									  numToWrite:1];
}

- (id) readHardwareRegisterCmd:(unsigned long) regAddress
{
	return [ORPMCReadWriteCommand readLongBlockAtAddress:regAddress
									  numToRead:1];
}

- (void) executeCommandList:(ORCommandList*)aList
{
	[pmcLink executeCommandList:aList];
}

- (void) readAllStatus
{
	[self readControlReg];
	[self readStatusReg];
	//[self readReadOutControlReg];
	[self getTime];
	[self readEventFifoStatusReg];
}



- (unsigned long) readControlReg
{
	unsigned long data = [self readReg:kEWSltV4ControlReg];
    [self setControlReg: data];
	return data;
}


- (void) writeControlReg
{
	[self writeReg:kEWSltV4ControlReg value:controlReg];
}

- (void) printControlReg
{
	unsigned long data = [self readControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register %@ is 0x%08x ----\n",[self fullID],data);
	NSLogFont(aFont,@"OnLine  : 0x%02x\n",(data & kCtrlOnLine) >> 14);
	NSLogFont(aFont,@"LedOff  : 0x%02x\n",(data & kCtrlLedOff) >> 15);
	NSLogFont(aFont,@"Invert  : 0x%02x\n",(data & kCtrlInvert) >> 16);
	NSLogFont(aFont,@"NumFIFOs: 0x%02x\n",(data & kCtrlNumFIFOs) >> 28);
}


- (unsigned long) readStatusReg
{
	unsigned long data = [self readReg:kEWSltV4StatusReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kEWSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusReg:data];
	return data;
}

- (unsigned long) readStatusLowReg
{
	unsigned long data = [self readReg:kEWSltV4StatusLowReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kEWSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusLowReg:data];
	return data;
}

- (unsigned long) readStatusHighReg
{
	unsigned long data = [self readReg:kEWSltV4StatusHighReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kEWSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusHighReg:data];
	return data;
}


- (void) printStatusReg
{
	unsigned long data = [self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register %@ is 0x%08x ----\n",[self fullID],data);
	NSLogFont(aFont,@"IRQ           : 0x%02x\n",ExtractValue(data,kEWStatusIrq,31));
	NSLogFont(aFont,@"PixErr        : 0x%02x\n",ExtractValue(data,kEWStatusPixErr,16));
	NSLogFont(aFont,@"FLT0..15 Requ.: 0x%04x\n",ExtractValue(data,0xffff,0));
}

- (void) printStatusLowHighReg
{
//DEBUG OUTPUT:
  	NSLog(@"   %@::%@: UNDER CONSTRUCTION \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-

	unsigned long low = [self readStatusLowReg];
	unsigned long high = [self readStatusHighReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Low Register %@ is 0x%08x ----\n",[self fullID],low);
	NSLogFont(aFont,@"FifoReq0..7 Requ.: 0x%04x\n",ExtractValue(low,0xffff,0));
	NSLogFont(aFont,@"FLTrq           : 0x%02x\n",ExtractValue(low,0x1<<15,15));
	NSLogFont(aFont,@"FLTto           : 0x%02x\n",ExtractValue(low,0x1<<16,16));
	NSLogFont(aFont,@"FLTPixErr       : 0x%02x\n",ExtractValue(low,0x1<<17,17));
	NSLogFont(aFont,@"PPS Err         : 0x%02x\n",ExtractValue(low,0x1<<18,18));
	NSLogFont(aFont,@"Clock Err       : 0x%02x\n",ExtractValue(low,0xf<<19,19));
	NSLogFont(aFont,@"GPS Err         : 0x%02x\n",ExtractValue(low,0x1<<23,23));
	NSLogFont(aFont,@"VTT Err         : 0x%02x\n",ExtractValue(low,0x1<<24,24));
	NSLogFont(aFont,@"Fan Err         : 0x%02x\n",ExtractValue(low,0x1<<25,25));
    
//	NSLogFont(aFont,@"IRQ           : 0x%02x\n",ExtractValue(low,kEWStatusIrq,15));
//	NSLogFont(aFont,@"PixErr        : 0x%02x\n",ExtractValue(low,kEWStatusPixErr2013,16));
	NSLogFont(aFont,@"----Status High Register %@ is 0x%08x ----\n",[self fullID],high);
	NSLogFont(aFont,@"FLT0..19 Requ.: 0x%05x\n",ExtractValue(high,0xfffff,0));
	NSLogFont(aFont,@"SW IR         : 0x%02x\n",ExtractValue(high,0x1<<31,31));

}




- (void) writePixelBusEnableReg
{
	[self writeReg:kEWSltV4PixelBusEnableReg value: [self pixelBusEnableReg]];
}

- (void) readPixelBusEnableReg
{
    unsigned long val;
	val = [self readReg:kEWSltV4PixelBusEnableReg];
	[self setPixelBusEnableReg:val];	
}










- (long) getSBCCodeVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSoftwareVersion numToRead:1];
		//implementation is in HW_Readout.cc, void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)  ... -tb-
	}
	[pmcLink setSbcCodeVersion:theVersion];
	return theVersion;
}

- (long) getFdhwlibVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetFdhwLibVersion numToRead:1];
	}
	return theVersion;
}

- (long) getSltPciDriverVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSltPciDriverVersion numToRead:1];
	}
	return theVersion;
}

- (long) getPresentFLTsMap
{
	/*uint32_t*/ long theMap = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theMap operation:kGetPresentFLTsMap numToRead:1];
	}
	return theMap;
}

//TODO: remove this, never usd -tb-
- (void) readEventStatus:(unsigned long*)eventStatusBuffer
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink readLongBlockPmc:eventStatusBuffer
					 atAddress:regV4[kSltV4EventFIFOStatusReg].addressOffset
					 numToRead: 1];
	
}

- (void) readEventFifoStatusReg
{
	[self setEventFifoStatusReg:[self readReg:kSltV4EventFIFOStatusReg]];
}


- (unsigned long long) readBoardID
{
	unsigned long low = [self readReg:kEWSltV4BoardIDLoReg];
	unsigned long hi  = [self readReg:kEWSltV4BoardIDHiReg];
	BOOL crc =(hi & 0x80000000)==0x80000000;
	if(crc){
		return (unsigned long long)(hi & 0xffff)<<32 | low;
	}
	else return 0;
}

//DEBUG OUTPUT: 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-

#if 0 //deprecated 2013-06 -tb-
- (void) writeInterruptMask
{
	[self writeReg:kSltV4InterruptMaskReg value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kSltV4InterruptMaskReg]];
}

- (void) readInterruptRequest
{
	[self setInterruptMask:[self readReg:kSltV4InterruptRequestReg]];
}

- (void) printInterruptRequests
{
	[self printInterrupt:kSltV4InterruptRequestReg];
}

- (void) printInterruptMask
{
	[self printInterrupt:kSltV4InterruptMaskReg];
}

- (void) printInterrupt:(int)regIndex
{
	unsigned long data = [self readReg:regIndex];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts %@)\n",regIndex==kSltV4InterruptRequestReg?@"Requested":@"Enabled");
	else {
		NSLogFont(aFont,@"The following interrupts are %@:\n",regIndex==kSltV4InterruptRequestReg?@"Requested":@"Enabled");
		NSLogFont(aFont,@"0x%04x\n",data & 0xffff);
	}
}
#endif


- (unsigned long) readHwVersion
{
	unsigned long value;
	@try {
		[self setHwVersion:[self readReg: kEWSltV4RevisionReg]];	
	}
	@catch (NSException* e){
	}
	return value;
}


- (unsigned long) readTimeLow
{
	return [self readReg:kEWSltV4TimeLowReg];
}

- (unsigned long) readTimeHigh
{
	return [self readReg:kEWSltV4TimeHighReg];
}

- (unsigned long long) getTime
{
	unsigned long th = [self readTimeHigh]; 
	unsigned long tl = [self readTimeLow]; 
	[self setClockTime: (((unsigned long long) th) << 32) | tl];
//DEBUG OUTPUT: 	NSLog(@"   %@::%@: tl: 0x%08x,  th: 0x%08x  clockTime: 0x%016qx  (%li)\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),tl,th,clockTime,clockTime);//TODO: DEBUG testing ...-tb-
	return clockTime;
}

- (void) initBoard
{

//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-
//TODO: initBoard: switch to online, event readout etc. -tb-

//DEBUG OUTPUT:
 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-



	[self writeControlReg];
	[self writePixelBusEnableReg];
	//-----------------------------------------------
	//board doesn't appear to start without this stuff
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	//usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];
	
	//usleep(100);
	
//	int savedTriggerSource = triggerSource;
//	int savedInhibitSource = inhibitSource;
//	triggerSource = 0x1; //sw trigger only
//	inhibitSource = 0x3; 
//	[self writePageManagerReset];
	//unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSltSwRelInhibit value:0];
	//int i = 0;
	//unsigned long lTmp;
    //do {
	//	lTmp = [self readReg:kSltStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		//usleep(10);
		//i++;
   // } while(((lTmp & 0x10000) != 0) && (i<10000));
	
   // if (i>= 10000){
		//NSLog(@"Release inhibit failed\n");
		//[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	//}
/*	
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSltSwSetInhibit value:0];
 */
//	triggerSource = savedTriggerSource;
	//inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	[self printStatusReg];
	[self printStatusLowHighReg];
	[self printControlReg];
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
}

- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	[ORTimer delay:1.5];
	[ORTimer delay:1.5];
	//[self readReg:kSltStatusReg];
	[guardian checkCards];
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	//[self writeReg:kSltSwRelInhibit value:0];
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];				
}
/*
- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self writeReg:kSltTestpulsAmpl value:theConvertedAmp];
	NSLog(@"Wrote %.2fV to SLT pulser Amplitude\n",pulserAmp);
}

- (void) loadPulseDelay
{
	//delay goes from 100ns to 3276.8us
	//writing 0x00 to hw gives longest delay. 
	//conversion equation:  hwValue = -10.0*delay + 32768.
	unsigned short theConvertedDelay = pulserDelay * -10.0 + 32768.;
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+0 value:theConvertedDelay];
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+1 value:theConvertedDelay];
	int i; //load the rest of the pulser memory with 0's
	for (i=2;i<256;i++) [self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+i value:theConvertedDelay];
}


- (void) loadPulserValues
{
	[self loadPulseAmp];
	[self loadPulseDelay];
}
*/

- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setSaveIonChanFilterOutputRecords:[decoder decodeBoolForKey:@"saveIonChanFilterOutputRecords"]];
	[self setFifoForUDPDataPort:[decoder decodeIntForKey:@"fifoForUDPDataPort"]];
	[self setUseStandardUDPDataPorts:[decoder decodeIntForKey:@"useStandardUDPDataPorts"]];
	[self setResetEventCounterAtRunStart:[decoder decodeIntForKey:@"resetEventCounterAtRunStart"]];
	[self setLowLevelRegInHex:[decoder decodeIntForKey:@"lowLevelRegInHex"]];
	[self setTakeADCChannelData:[decoder decodeIntForKey:@"takeADCChannelData"]];
	[self setTakeRawUDPData:[decoder decodeIntForKey:@"takeRawUDPData"]];
	[self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFile"]];
	[self setUseBroadcastIdBB:[decoder decodeIntForKey:@"useBroadcastIdBB"]];
	[self setIdBBforWCommand:[decoder decodeIntForKey:@"idBBforWCommand"]];
	[self setTakeEventData:[decoder decodeIntForKey:@"takeEventData"]];
	[self setTakeUDPstreamData:[decoder decodeIntForKey:@"takeUDPstreamData"]];
	[self setCrateUDPDataCommand:[decoder decodeObjectForKey:@"crateUDPDataCommand"]];
	[self setBBCmdFFMask:[decoder decodeInt32ForKey:@"BBCmdFFMask"]];
	[self setCmdWArg4:[decoder decodeIntForKey:@"cmdWArg4"]];
	[self setCmdWArg3:[decoder decodeIntForKey:@"cmdWArg3"]];
	[self setCmdWArg2:[decoder decodeIntForKey:@"cmdWArg2"]];
	[self setCmdWArg1:[decoder decodeIntForKey:@"cmdWArg1"]];
	[self setSltDAQMode:[decoder decodeIntForKey:@"sltDAQMode"]];
	[self setNumRequestedUDPPackets:[decoder decodeIntForKey:@"numRequestedUDPPackets"]];
	[self setCrateUDPDataReplyPort:[decoder decodeIntForKey:@"crateUDPDataReplyPort"]];
	[self setCrateUDPDataIP:[decoder decodeObjectForKey:@"crateUDPDataIP"]];
	[self setCrateUDPDataPort:[decoder decodeIntForKey:@"crateUDPDataPort"]];
	[self setPixelBusEnableReg:[decoder decodeInt32ForKey:@"pixelBusEnableReg"]];
	[self setSelectedFifoIndex:[decoder decodeIntForKey:@"selectedFifoIndex"]];
	[self setCrateUDPCommand:[decoder decodeObjectForKey:@"crateUDPCommand"]];
	[self setCrateUDPReplyPort:[decoder decodeIntForKey:@"crateUDPReplyPort"]];
	[self setCrateUDPCommandIP:[decoder decodeObjectForKey:@"crateUDPCommandIP"]];
	[self setCrateUDPCommandPort:[decoder decodeIntForKey:@"crateUDPCommandPort"]];
	[self setSltScriptArguments:[decoder decodeObjectForKey:@"sltScriptArguments"]];
	pmcLink = [[decoder decodeObjectForKey:@"PMC_Link"] retain];
	if(!pmcLink)pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	else [pmcLink setDelegate:self];

	[self setControlReg:		[decoder decodeInt32ForKey:@"controlReg"]];
	if([decoder containsValueForKey:@"secondsSetInitWithHost"])
		[self setSecondsSetInitWithHost:[decoder decodeBoolForKey:@"secondsSetInitWithHost"]];
	else[self setSecondsSetInitWithHost: YES];
	

	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"OREdelweissSLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeInt32ForKey:@"OREdelweissSLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"OREdelweissSLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"OREdelweissSLTModelPulserAmp"]];
		
	//special
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"OREdelweissSLTPageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"OREdelweissSLTDisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"OREdelweissSLTDisplayEventLoop"]];
    	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
	[[self undoManager] enableUndoRegistration];

	[self registerNotificationObservers];
		
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeBool:saveIonChanFilterOutputRecords forKey:@"saveIonChanFilterOutputRecords"];
	[encoder encodeInt:fifoForUDPDataPort forKey:@"fifoForUDPDataPort"];
	[encoder encodeInt:useStandardUDPDataPorts forKey:@"useStandardUDPDataPorts"];
	[encoder encodeInt:resetEventCounterAtRunStart forKey:@"resetEventCounterAtRunStart"];
	[encoder encodeInt:lowLevelRegInHex forKey:@"lowLevelRegInHex"];
	[encoder encodeInt:takeADCChannelData forKey:@"takeADCChannelData"];
	[encoder encodeInt:takeRawUDPData forKey:@"takeRawUDPData"];
	[encoder encodeObject:chargeBBFile forKey:@"chargeBBFile"];
	[encoder encodeInt:useBroadcastIdBB forKey:@"useBroadcastIdBB"];
	[encoder encodeInt:idBBforWCommand forKey:@"idBBforWCommand"];
	[encoder encodeInt:takeEventData forKey:@"takeEventData"];
	[encoder encodeInt:takeUDPstreamData forKey:@"takeUDPstreamData"];
	[encoder encodeObject:crateUDPDataCommand forKey:@"crateUDPDataCommand"];
	[encoder encodeInt32:BBCmdFFMask forKey:@"BBCmdFFMask"];
	[encoder encodeInt:cmdWArg4 forKey:@"cmdWArg4"];
	[encoder encodeInt:cmdWArg3 forKey:@"cmdWArg3"];
	[encoder encodeInt:cmdWArg2 forKey:@"cmdWArg2"];
	[encoder encodeInt:cmdWArg1 forKey:@"cmdWArg1"];
	[encoder encodeInt:sltDAQMode forKey:@"sltDAQMode"];
	[encoder encodeInt:numRequestedUDPPackets forKey:@"numRequestedUDPPackets"];
	[encoder encodeInt:crateUDPDataReplyPort forKey:@"crateUDPDataReplyPort"];
	[encoder encodeObject:crateUDPDataIP forKey:@"crateUDPDataIP"];
	[encoder encodeInt:crateUDPDataPort forKey:@"crateUDPDataPort"];
	[encoder encodeInt32:pixelBusEnableReg forKey:@"pixelBusEnableReg"];
	[encoder encodeInt:selectedFifoIndex forKey:@"selectedFifoIndex"];
	[encoder encodeObject:crateUDPCommand forKey:@"crateUDPCommand"];
	[encoder encodeInt:crateUDPReplyPort forKey:@"crateUDPReplyPort"];
	[encoder encodeObject:crateUDPCommandIP forKey:@"crateUDPCommandIP"];
	[encoder encodeInt:crateUDPCommandPort forKey:@"crateUDPCommandPort"];
	[encoder encodeBool:secondsSetInitWithHost forKey:@"secondsSetInitWithHost"];
	[encoder encodeObject:sltScriptArguments forKey:@"sltScriptArguments"];
	[encoder encodeObject:pmcLink		forKey:@"PMC_Link"];
	[encoder encodeInt32:controlReg	forKey:@"controlReg"];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"OREdelweissSLTModelPatternFilePath"];
	[encoder encodeInt32:interruptMask	 forKey:@"OREdelweissSLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"OREdelweissSLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"OREdelweissSLTModelPulserAmp"];
		
	//special
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"OREdelweissSLTPageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"OREdelweissSLTDisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"OREdelweissSLTDisplayEventLoop"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OREdelweissSLTDecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissSLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissSLTDecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissSLTMultiplicity"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissSLTDecoderForWaveForm",			@"decoder",
				   [NSNumber numberWithLong:waveFormId],        @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissSLTWaveForm"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissSLTDecoderForFLTEvent",			@"decoder",
				   [NSNumber numberWithLong:fltEventId],        @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissSLTFLTEvent"];
    
    return dataDictionary;
}

- (unsigned long) fltEventId	     { return fltEventId; }
- (void) setFltEventId: (unsigned long) aDataId    { fltEventId = aDataId; }
- (unsigned long) eventDataId        { return eventDataId; }
- (unsigned long) multiplicityId	 { return multiplicityId; }
- (unsigned long) waveFormId	     { return waveFormId; }
- (void) setEventDataId: (unsigned long) aDataId    { eventDataId = aDataId; }
- (void) setMultiplicityId: (unsigned long) aDataId { multiplicityId = aDataId; }
- (void) setWaveFormId: (unsigned long) aDataId { waveFormId = aDataId; }

- (void) setDataIds:(id)assigner
{
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
    fltEventId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setEventDataId:[anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
    [self setWaveFormId:[anotherCard waveFormId]];
    [self setFltEventId:[anotherCard fltEventId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	return objDictionary;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


    if(takeEventData || [[userInfo objectForKey:@"doinit"]intValue]){
       accessAllowedToHardwareAndSBC = YES;
    }else{
       accessAllowedToHardwareAndSBC = NO;
    }

    [self clearExceptionCount];
	
	//check that we can actually run
    if(takeEventData){
	    if(![pmcLink isConnected]){
		    [NSException raise:@"Not Connected" format:@"Check the SLT connection"];
	    }
    }
	
    if(takeUDPstreamData){
        savedUDPSocketState = [self isOpenDataCommandSocket] | ([self isListeningOnDataServerSocket]<<1);
        //savedUDPSocketState=0;
        //if([self isOpenDataCommandSocket]) savedUDPSocketState=0x1;
        //if([self isListeningOnDataServerSocket]) savedUDPSocketState|=0x2;

NSLog(@"     %@::%@: takeUDPstreamData: savedUDPSocketState is %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),savedUDPSocketState);//TODO: DEBUG testing ...-tb-
         
	    //if(![pmcLink isConnected]){
		//    [NSException raise:@"Not Connected" format:@"Check the SLT connection"];
	    //}
        //open UDP sockets, if not opened
        if(![self isOpenDataCommandSocket]) [self openDataCommandSocket];
        if(![self isListeningOnDataServerSocket]) [self startListeningDataServerSocket];
	    if(! ([self isOpenDataCommandSocket]  &&  [self isListeningOnDataServerSocket]  ) ){
		    [NSException raise:@"UDP sockets not Connected" format:@"Check the 'UDP data socket' connection of SLT"];
	    }
        
    }
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OREdelweissSLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	pollingWasRunning = [poller isRunning];
	if(pollingWasRunning) [poller stop];
	
	//[self writeSetInhibit];  //TODO: maybe move to readout loop to avoid dead time -tb-
	
    
    //warm or cold start?
    //  for QuickStart: do not access the hardware (at least not registers relevant for SAMBA) -tb-
    if([[userInfo objectForKey:@"doinit"]intValue]){
        [self initBoard];		
        //event mode
        if(takeEventData){
		    //[self initBoard];		
            //init FLTs is done by RunControl, if they are in TaskManager ...
        }
        //UDP data stream mode
        if(takeUDPstreamData){
            //'re-init' stream loop
            //---- deprecated --- [self sendUDPDataCommandString: @"KWC_stopStreamLoop"];	
            [self sendUDPDataCommandString: [NSString stringWithFormat: @"KWC_stopFIFO %i",fifoForUDPDataPort]];	
            usleep(10000);//need to wait for a recvfrom() cycle ...
            sleep(1);
            //---- deprecated --- [self sendUDPDataCommandString: @"KWC_startStreamLoop"];	
            [self sendUDPDataCommandString: [NSString stringWithFormat: @"KWC_startFIFO %i",fifoForUDPDataPort]];	
            usleep(10000);
            [self loopCommandRequestUDPData];
            //[self sendUDPDataCommandRequestPackets:  numRequestedUDPPackets];
            //[self performSelector:@selector(loopCommandRequestUDPData) withObject:nil afterDelay: 10.0];//repeat every 10 seconds
        }
	}	
	
    
    
    partOfRunFLTMask = 0;
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	
	for(id obj in dataTakers){ //the SLT calls runTaskStarted:userInfo: for all FLTs -tb-
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
         #if 1
        if([[obj class]  isSubclassOfClass: NSClassFromString(@"OREdelweissFLTModel")]){
            //DEBUG
            //NSLog(@"    %@::%@: found a OREdelweissFLTModel data taker! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
            partOfRunFLTMask |= 0x1 << ([obj stationNumber]-1);
            //NSLog(@"         data taker! stationNumber: %i flt mask:0x%08x\n" ,[obj stationNumber],partOfRunFLTMask);//TODO: DEBUG testing ...-tb-
        }
         #endif
    }
	

	
	//TODO: temporarily disabled ... [self readStatusReg];
    if(accessAllowedToHardwareAndSBC){
        //reset event FIFO and counter(s)
        if(resetEventCounterAtRunStart)[self writeEvRes];
        //display status
        [self readStatusReg];	
    }
    
    
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
    if(accessAllowedToHardwareAndSBC){
	    //load all the data needed for the eCPU to do the HW read-out.
	    [self load_HW_Config];
	    [pmcLink runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
        // -------TIMER-VARIABLES-----------
        static struct timeval starttime, /*stoptime,*/ currtime;//    struct timezone tz; is obsolete ... -tb-
        //struct timezone	timeZone;
	    static double currDiffTime=0.0, lastDiffTime=0.0;




	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pmc code.
        if(accessAllowedToHardwareAndSBC)
    		[pmcLink takeData:aDataPacket userInfo:userInfo];
        
        
        //additionally we generate events here
        //start timer -------TIMER------------
        //timing
        //see below ... gettimeofday(&starttime,NULL);
        //gettimeofday(&starttime,&timeZone);
        //start timer -------TIMER------------

        //TIMER - do something every x seconds:
        //-----------------------
		//gettimeofday(&starttime,NULL);
        gettimeofday(&currtime,NULL);
        currDiffTime =      (  (double)(currtime.tv_sec  - starttime.tv_sec)  ) +
                    ( ((double)(currtime.tv_usec - starttime.tv_usec)) * 0.000001 );
        double elapsedTime = currDiffTime - lastDiffTime;
        
        //if takeUDPstreamData is checked, check every 0.5 sec. the UDP buffer ...
        if(takeUDPstreamData) if(elapsedTime >= 0.5){// ----> x= this value (e.g. 1.0/0.5 ...)
		    //code to be executed every x seconds -BEGIN
		    //
		    // 
		    //./ DO SOMETHING
			NSLog(@"===================================\n");
			NSLog(@"   Datataker Loop: 1 strobe: %f\n",currDiffTime);
			NSLog(@"===================================\n");
            
            #if 0
            //send a test data record (waveForm)
            {
                                uint32_t waveformLength = 1000; //2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable   
                                uint32_t locationWord = 0;//			  = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
                                uint32_t headerData = 0; 
                                uint16_t dataWord16 = 0; 
                        	unsigned long totalLength = (9 + waveformLength32);	// longs (1 page=1024 shorts [16 bit] are stored in 512 longs [32 bit])
							NSMutableData* theADCTraceData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
							unsigned long header = waveFormId | totalLength;
							
							[theADCTraceData appendBytes:&header length:4];				           //ORCA header word
							[theADCTraceData appendBytes:&locationWord length:4];		           //which crate, which card info
                            headerData = 123; //second
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = 0; //
							[theADCTraceData appendBytes:&headerData length:4];		           
							[theADCTraceData appendBytes:&headerData length:4];		           
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = 234; //energy
							[theADCTraceData appendBytes:&headerData length:4];		           
                            uint32_t eventFlags     = 1;//1 = UDP packet
							[theADCTraceData appendBytes:&eventFlags length:4];		           
                            headerData = 0; //
							[theADCTraceData appendBytes:&headerData length:4];		           
                            //ship a test ramp
                            int i;
                            for(i=0; i< waveformLength;i++){
                                dataWord16 = i;
							    [theADCTraceData appendBytes:&dataWord16 length:sizeof(dataWord16)];		           
                            }							
                            
							[aDataPacket addData:theADCTraceData]; //ship the waveform
            }
            #endif
            

            //check for data
            int *rdIndex = &(dataReplyThreadData.rdIndex);//we cannot use references, we are in C, not C++
            if(*rdIndex>=0){
			    NSLog(@"   ReadBuffer:   %i   hasPackets: %i   hasBytes: %i  numADCsInDataStream: %i numfifo: %i numStatPak: %i\n",*rdIndex, 
                    dataReplyThreadData.hasDataPackets[*rdIndex],
                    dataReplyThreadData.hasDataBytes[*rdIndex],
                    dataReplyThreadData.numADCsInDataStream[*rdIndex],
                    dataReplyThreadData.numfifo[*rdIndex],
                    dataReplyThreadData.numStatusPackets[*rdIndex]);
            }else{
			    NSLog(@"   ReadBuffer:   %i   \n",*rdIndex);
            }
            
            if(dataReplyThreadData.rdIndex>=0){//i.e. != -1   TODO: I could omit this check (?) -tb-
                TypeIpeCrateStatusBlock *crateStatusBlock= &(dataReplyThreadData.crateStatusBlock[*rdIndex]);

                //if data is available, reorder UDP paket data and write it to run file
                if(dataReplyThreadData.hasDataPackets[dataReplyThreadData.rdIndex]){
                
                
                //sending raw UDP packet
                #if 1
                    //send the first UDP packet as 'waveform' packet
                    //
                        if(takeRawUDPData){
                          NSLog(@"     -> ship UDP packets: status packets: %i; data packets: %i\n",dataReplyThreadData.numStatusPackets[*rdIndex],dataReplyThreadData.numDataPackets[*rdIndex]);

                            int k;
                            //ship status packets
                            for(k=0;k<dataReplyThreadData.numStatusPackets[*rdIndex];k++){
                                    char *udpData = dataReplyThreadData.statusBuf[*rdIndex][k];
                                    int length=  dataReplyThreadData.statusBufSize[*rdIndex][k];
                                    [self shipUDPPacket:aDataPacket data:udpData len:length index:k type:0x1];
                          NSLog(@"       ship UDP packets: status packets: len %i; index: %i\n",length,k);
                            }

                            //ship raw UDP packets
                            int countShipped=0;
                            int sumDataPackets=dataReplyThreadData.numDataPackets[*rdIndex];
                            for(k=0;k<kMaxNumUDPDataPackets;k++){
                                if(dataReplyThreadData.adcBufReceivedFlag[*rdIndex][k]){
                                    char *udpData = dataReplyThreadData.adcBuf[*rdIndex][k];
                                    int length=  dataReplyThreadData.adcBufSize[*rdIndex][k];
                                    [self shipUDPPacket:aDataPacket data:udpData len:length index:k  type:0x3];
                                    countShipped++;
                                    if(countShipped==sumDataPackets) break;
                                }
                            }
                        }

                #endif
                
                  if(takeADCChannelData){
                
                    //read out data
                    //    reorder UDP packets to build ADC traces according to one channel
                    //TODO: submit maxPacketSize in status packet ... (extend crate status struct in ipe4reader) -tb- 
                    int ipe4readerVersion = dataReplyThreadData.crateStatusBlock[*rdIndex].version;
                    int ipe4readerSWVersion = ipe4readerVersion % 100;
                    NSLog(@"    statusPacket from ipe4reader version:   %i (sw version: %i)\n",ipe4readerVersion,ipe4readerSWVersion);

                    int MaxUDPPacketSizeBytes=1444;
                    int M=(-4) / 2;//max. number of shorts (1444-4)/2=720
                    //int NA=dataReplyThreadData.numADCsInDataStream[*rdIndex];//TODO: take from crate status packet -tb- DONE
                    int NA=dataReplyThreadData.crateStatusBlock[*rdIndex].numFIFOnumADCs & 0xffff;//take from crate status packet -tb-
                    int maxUDPSizeSetting=dataReplyThreadData.crateStatusBlock[*rdIndex].maxUDPSize;//take from crate status packet -tb-

//TODO:
if(NA==0) NA=6;//TODO: dirty workaround, if 0 channels are transmitted -tb-
//TODO: I could try to detect num of ADCs by checking number of bytes in buffer - need to sum up all UDP data packet size (without header) -tb-


                    if(ipe4readerSWVersion < 10){//version before 2014-01-08, fixed UDP packed size 1444
                        MaxUDPPacketSizeBytes=1444;
                        M=(MaxUDPPacketSizeBytes-4) / 2;//max. number of shorts (1444-4)/2=720
                    }else{//we have variable packet size
                        int mupsb = (720/NA)*NA*2+4 ;//(1440 / (2*NA)) * 2 * NA + 4;
                        //maxUDPSizeSetting==0 is ipe4reader version <10 and should already have been handled (see above)
                        if(maxUDPSizeSetting==-1){//auto mode: compute size by numADCs
                            if(MaxUDPPacketSizeBytes != mupsb) NSLog(@"  --------->  parser correction:  udpDataPacketSize: old: %i new:%i\n", MaxUDPPacketSizeBytes,mupsb);
                            MaxUDPPacketSizeBytes = mupsb;
                        }else{
                            //mupsb = 1444; //this should become standard, quick fix
                            if(MaxUDPPacketSizeBytes != maxUDPSizeSetting) NSLog(@"  --------->  parser correction:  udpDataPacketSize: old: %i new:%i\n", MaxUDPPacketSizeBytes,maxUDPSizeSetting);
                            MaxUDPPacketSizeBytes = maxUDPSizeSetting;
                        }
                        
                        M=(MaxUDPPacketSizeBytes-4) / 2;//max. number of shorts (1444-4)/2=720
                    }
                    int numfifo=dataReplyThreadData.numfifo[*rdIndex];//TODO: take from crate status packet -tb-
                    int     i, j, j_swapit, toffset = 0;
                    int64_t K,t = 0;
                    //for(i=0; i<NA; i++) adcTraceBufCount[*rdIndex][i]=0;
                    for(i=0; i<kMaxNumADCChan/*720*/; i++) dataReplyThreadData.adcTraceBufCount[*rdIndex][i]=0;
                    uint16_t *P;
                    uint16_t *data16;
                    int packetCounter=0;
                    bool reachedMaxTimesample=false;
                    for(i=0; i<kMaxNumUDPDataPackets;i++){// i counts the UDP packets
                        if(dataReplyThreadData.adcBufReceivedFlag[*rdIndex][i]){
                            //check: P should also be == i
                            P = (uint16_t*)(&dataReplyThreadData.adcBuf[*rdIndex][i][0]);
                            K = *P * M;
                            t = K/NA; 
                            toffset = K % NA; //toffset is more or less the abs. ADC channel number ... -tb-
                            int len;
                            len=(dataReplyThreadData.adcBufSize[*rdIndex][i]-4) / 2;
                            data16=(uint16_t*)(&dataReplyThreadData.adcBuf[*rdIndex][i][4]);
                            j_swapit=1;
                            for(j=0; j<len; j++){//j loops through UDP packet data
                                if(t>=100000){//we have too much data, probably the number of sent ADC channels has changed/increased: stop assembling event records
                                    reachedMaxTimesample=true;
                                    break;
                                }
                                //if(i<2 || (len<720)) NSLog(@" A i:%i j:%i index  (toffset,t)=(%i,%i)  len %i (%i)\n",(int)i,(int)j,(int)toffset,(int)t,(int)len,(int)dataReplyThreadData.adcBufSize[*rdIndex][i]);
                                dataReplyThreadData.adcTraceBuf[*rdIndex][toffset][t]=*(data16+j+j_swapit);
                                //we need to swap each pair of shorts (uint16_t) - this is the sequence in the UDP packets ...
                                j_swapit = -j_swapit;// ->toggles between 1 and -1 ...
                                //unswapped: dataReplyThreadData.adcTraceBuf[*rdIndex][toffset][t]=*(data16+j);
                                dataReplyThreadData.adcTraceBufCount[*rdIndex][toffset]++; //count the number of shorts
                                toffset++; 
                                if(toffset==NA){toffset=0; t++;}
                            }//for(j...
                            if(reachedMaxTimesample){
                                NSLog(@"    reachedMaxTimesample - leave loop! t is %i (should be 100000) double break \n",(int)t);
                                break;
                            }
                            //debug if(i<10 || t>99996) NSLog(@" E  index  (toffset,t)=(%i,%i)  len %i \n",(int)toffset,(int)t,(int)len);
                        }

                        if(packetCounter==dataReplyThreadData.hasDataPackets[*rdIndex]){
                            NSLog(@"    packetCounter==dataReplyThreadData.hasDataPackets[*rdIndex]: we handled all data packets - leave loop! t is %i (should be 100000) regular break \n",(int)t);
                            break;
                        }
                        packetCounter++;
                    }//for(i...
                    if(t<100000){
                        NSLog(@"    end of  loop! t is %i t<100000 (should be 100000) missing UDP packets? \n",(int)t);
                    }
                    if(reachedMaxTimesample){
                        NSLog(@"    reachedMaxTimesample - leave loop! t is %i (should be 100000) double break ; handled packetCounter %i, in buffer packets %i \n",(int)t,packetCounter,dataReplyThreadData.hasDataPackets[*rdIndex]);
                    }
                    
                    
                    //    now ship recorded data
                    int chan;
                    uint16_t dataWord16 = 0; 
                    uint32_t locationWord = 0;//			  = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
                    uint32_t headerData = 0; 
                    int numTSamples=100000;
                    int traceLength=10000;//<---------------   <<-------  <<<----   configure the length of a single trace record here (number of shorts/uint16_t)
                                          //<---------------   <<-------  <<<----   tested: 1000, 2000, 4000, 10000
                    int numTraces=numTSamples/traceLength; //                             = 100,   50,   25,    10
                    NSLog(@" Shipping num of ADC channels:%i  \n",(int)NA);
                    
                    for(chan=0;chan<NA;chan++){
                        if(dataReplyThreadData.adcTraceBufCount[*rdIndex][toffset]<100000){
                            NSLog(@"    channel %i, trace %i has missing samples (%i out of 100000) \n",chan,(int)i,(int)dataReplyThreadData.adcTraceBufCount[*rdIndex][chan]);

                        }
                        unsigned long totalLength = (9 + traceLength/2);	// header (uint32_t) + traceLength shorts (16 bit)
                        unsigned long header = waveFormId | totalLength;
                        t=0;
                        for(i=0; i<numTraces; i++){//default is: ship numTraces=10 packets with traceLength=10000 sample points

                            NSMutableData* theADCTraceData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
                            [theADCTraceData appendBytes:&header length:4];				           //ORCA header word
 						    locationWord = (chan&0xff)<<8; 
							[theADCTraceData appendBytes:&locationWord length:4];		           //which crate, which card info
                            headerData = crateStatusBlock->PPS_count; //second
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = i * traceLength; //sub second
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = chan & 0xffff; //total number of channel in packet (was 'channel map')
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = i; //event ID
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = numfifo; //numfifo (was energy)
							[theADCTraceData appendBytes:&headerData length:4];		           
                            uint32_t eventFlags     = 0;//0 = ADC trace
							[theADCTraceData appendBytes:&eventFlags length:4];		           
                            headerData = 0; //
							[theADCTraceData appendBytes:&headerData length:4];	
                            //append ADC values	           
                            for(j=0; j<traceLength; j++){
                                dataWord16 = dataReplyThreadData.adcTraceBuf[*rdIndex][chan][t];
							    [theADCTraceData appendBytes:&dataWord16 length:sizeof(dataWord16)];		           
                                t++;
                            }
                            [aDataPacket addData:theADCTraceData]; //ship the waveform

                        }
                    }
                    
                    
                    
                    //mark buffer as free
                    dataReplyThreadData.hasDataPackets[dataReplyThreadData.rdIndex]=0;
                    dataReplyThreadData.hasDataBytes[dataReplyThreadData.rdIndex]=0;
                  }//if(takeADCChannelData ...
                  
                }//if( ...bufferHasData...
                
                
            }//if(...buffersAreActive...    TODO: I could omit this check (?) -tb-
		    //code to be executed every second -END
		    lastDiffTime = currDiffTime;
		}



        
	}
	else {// the first time
		//TODO: -tb- [self writePageManagerReset];
		//TODO: -tb- [self writeClrCnt];
        if(accessAllowedToHardwareAndSBC){

		    unsigned long long runcount = [self getTime];
		    [self shipSltEvent:kRunCounterType withType:kStartRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];

		    [self shipSltSecondCounter: kStartRunType];
        }
        
		first = NO;
        
        //init timer
        currDiffTime=0.0; lastDiffTime=0.0;
        //start timer -------TIMER------------
        //timing
        //see below ... gettimeofday(&starttime,NULL);
        gettimeofday(&starttime,NULL);
        //start timer -------TIMER------------

	}
}

- (void) shipUDPPacket:(ORDataPacket*)aDataPacket data:(char*)udpPacket len:(int)len index:(int)aIndex type:(int)t
{
                                uint32_t waveformLength = len/2; //2048; 
								uint32_t waveformLength32=waveformLength/2; //the waveform length is variable   
if((len % 4) != 0){
    int i,addZeros=4-(len % 4);
    for(i=0;i<addZeros;i++) udpPacket[len+i]=0;
    waveformLength32++;
    waveformLength=waveformLength32*2;
	//	
    NSLog(@"Called %@::%@: len not multiple of 4: len %i, changed to  %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),len,waveformLength*2);//TODO: DEBUG -tb-
    NSLog(@"Called %@::%@: len not multiple of 4: len %i, changed to  %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),len,waveformLength*2);//TODO: DEBUG -tb-
    NSLog(@"Called %@::%@: len not multiple of 4: len %i, changed to  %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),len,waveformLength*2);//TODO: DEBUG -tb-
    NSLog(@"Called %@::%@: len not multiple of 4: len %i, changed to  %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),len,waveformLength*2);//TODO: DEBUG -tb-
}
                                uint32_t headerData = 0; 
                                uint16_t dataWord16 = 0; 
                                uint32_t locationWord = 0;//			  = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
 						         //locationWord |= (aChan&0xff)<<8; // New: There is a place for the channel in the header?!

                            //int len=(dataReplyThreadData.adcBufSize[*rdIndex][0]) / 2;
                            //int len=1500/2;
                        waveformLength=len;
                        waveformLength32=waveformLength/2;



                        	unsigned long totalLength = (9 + waveformLength32);	// longs (1 page=1024 shorts [16 bit] are stored in 512 longs [32 bit])
							NSMutableData* theADCTraceData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
							unsigned long header = waveFormId | totalLength;
							
							[theADCTraceData appendBytes:&header length:4];				           //ORCA header word
							[theADCTraceData appendBytes:&locationWord length:4];		           //which crate, which card info
                            headerData = 0; //second
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = 0; //subsec
							[theADCTraceData appendBytes:&headerData length:4];	
                            headerData = aIndex & 0xffff; //number of  packet (was 'channel map')
							[theADCTraceData appendBytes:&headerData length:4];		
                            headerData = 0; //ID
							[theADCTraceData appendBytes:&headerData length:4];		           
                            headerData = 0; //energy
							[theADCTraceData appendBytes:&headerData length:4];		           
                            uint32_t eventFlags     = t;//Bit0==1 : UDP packet (bit 1: status packet(0) or data packet (1)
							[theADCTraceData appendBytes:&eventFlags length:4];		           
                            headerData = 0; //
							[theADCTraceData appendBytes:&headerData length:4];		           
							//[theWaveFormData appendBytes:&theEvent length:sizeof(katrinEventDataStruct)];
							//[theWaveFormData appendBytes:&theDebugEvent length:sizeof(katrinDebugDataStruct)];	

                            //ship the UDP packet with index 0
                            int j;
                            uint16_t *data16;
                            data16=(uint16_t*)(udpPacket);
                            //NSLog(@" ship UDP packet with  len %i \n",len);
                            for(j=0; j<waveformLength; j++){
                                dataWord16=*(data16+j);
							    [theADCTraceData appendBytes:&dataWord16 length:sizeof(dataWord16)];		           
                            }


							[aDataPacket addData:theADCTraceData]; //ship the waveform

                    
}



- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    for(id obj in dataTakers){
        [obj runIsStopping:aDataPacket userInfo:userInfo];
    }
    
    if(accessAllowedToHardwareAndSBC)
    	[pmcLink runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(accessAllowedToHardwareAndSBC){
	    [self shipSltSecondCounter: kStopRunType];
	    unsigned long long runcount = [self getTime];
	    [self shipSltEvent:kRunCounterType withType:kStopRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
	}
    
    for(id obj in dataTakers){
		[obj runTaskStopped:aDataPacket userInfo:userInfo];
    }	

    if(accessAllowedToHardwareAndSBC)	
    	[pmcLink runTaskStopped:aDataPacket userInfo:userInfo];
	
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
	
    //restore socket activity (on or off)
    if(takeUDPstreamData){
    	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loopCommandRequestUDPData) object:nil];
        if(! (savedUDPSocketState & 0x1)) [self closeDataCommandSocket];
        if(! (savedUDPSocketState & 0x2)) [self stopListeningDataServerSocket];
        savedUDPSocketState=0;
    }

    
	[dataTakers release];
	dataTakers = nil;

}

/** For the V4 SLT (Auger/KATRIN)the subseconds count 100 nsec tics! (Despite the fact that the ADC sampling has a 50 nsec base.)
  */ //-tb- 
- (void) shipSltSecondCounter:(unsigned char)aType
{
	//aType = 1 start run, =2 stop run, = 3 start subrun, =4 stop subrun, see #defines in OREdelweissSLTDefs.h -tb-
	unsigned long tl = [self readTimeLow]; 
	unsigned long th = [self readTimeHigh]; 

	

	[self shipSltEvent:kSecondsCounterType withType:aType eventCt:0 high:th low:tl ];
	#if 0
	unsigned long location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	unsigned long data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | (aType & 0xf);
			data[2] = 0;	
			data[3] = th;	
			data[4] = tl;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(5)]];
	#endif
}

- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(unsigned long)c high:(unsigned long)h low:(unsigned long)l
{
	unsigned long location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	unsigned long data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | ((aCounterType & 0xf)<<4) | (aType & 0xf);
			data[2] = c;	
			data[3] = h;	
			data[4] = l;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(5)]];
}


- (BOOL) doneTakingData
{
	return [pmcLink doneTakingData];
}

- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj
{ 
	//temp----
	int i, j, k;
	int sltSize = pageSize * 20;	
	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	//unsigned long xyProj[20];
	//unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<sltSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<sltSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Display trigger data
	if (displayTrigger) {	
		int i, j, k;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
		
		for(j=0;j<22;j++){
			NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
			//matrix of triggered pixel
			for(i=0;i<20;i++){
				if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
				else							   [s appendFormat:@"."];
			}
			[s appendFormat:@"  "];
			
			// trigger timing
			for (k=0;k<pageSize;k++){
				if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
				else							   [s appendFormat:@"."];
			}
			NSLogFont(aFont, @"%@\n", s);
		}
		
		NSLogFont(aFont,@"\n");	
	}		
	return(nTriggered);
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"cPCI"]autorelease]]; // ????? -tb-
    [readOutGroup loadUsingFile:aFile];
}
/*
- (void) dumpTriggerRAM:(int)aPageIndex
{
	
	//read page start address
	unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSltLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex];
	unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex+1];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
	NSLogFont(aFont,@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			  aPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
	
	//readout the SLT pixel trigger data
	unsigned long buffer[2000];
	unsigned long sltMemoryAddress = (SLTID << 24) | aPageIndex<<11;
	[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer length:20*100 increment:1];
	unsigned long reorderBuffer[2000];
	// Re-organize trigger data to get it in a continous data stream
	unsigned long *pMult = reorderBuffer;
	memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
	memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
	
	int i;
	int j;	
	int k;	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	unsigned long xyProj[20];
	unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<2000;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<2000;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	
	for(j=0;j<22;j++){
		NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			else							   [s appendFormat:@"."];
		}
		[s appendFormat:@"  "];
		
		// trigger timing
		for (k=0;k<100;k++){
			if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			else							   [s appendFormat:@"."];
		}
		NSLogFont(aFont, @"%@\n", s);
	}
	
	
	NSLogFont(aFont,@"\n");			
	
	
}
*/
- (void) autoCalibrate
{
	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if(![aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")]){  //remained from V3 ??? -tb-
			[aCard autoCalibrate];
		}
	}
}

- (void) tasksCompleted: (NSNotification*)aNote
{
	//nothing to do... this just removes a run-time exception
}

#pragma mark •••SBC_Linking protocol
- (NSString*) driverScriptName {return nil;} //no driver
- (NSString*) driverScriptInfo {return @"";}

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"IPE-DAQ-V4 EDELWEISS SLT Card (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return OREdelweissSLTSettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/EdelweissSLT/EdelweissSLTv4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config
{
	int index = 0;
	SBC_crate_config configStruct;
	configStruct.total_cards = 0;
	[self load_HW_Config_Structure:&configStruct index:index];
	[pmcLink load_HW_Config:&configStruct];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kSLTv4EW;	//should be unique
	configStruct->card_info[index].hw_mask[0] 	= eventDataId;
	configStruct->card_info[index].hw_mask[1] 	= waveFormId;
	configStruct->card_info[index].hw_mask[2] 	= fltEventId;
	configStruct->card_info[index].slot			= [self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
	
	configStruct->card_info[index].deviceSpecificData[0] = partOfRunFLTMask;	
    
	unsigned long runFlagsMask = 0;
	runFlagsMask |= kFirstTimeFlag;          //bit 16 = "first time" flag
    if(takeEventData)  runFlagsMask |= kTakeEventDataFlag;
    if(saveIonChanFilterOutputRecords)  runFlagsMask |= kSaveIonChanFilterOutputRecordsFlag;
	configStruct->card_info[index].deviceSpecificData[3] = runFlagsMask;	
    
    //for handling of different firmware versions
    if(hwVersion==0) [self readHwVersion];
    NSLog(@"IPE-DAQ EW SLT FPGA version 0x%08x (build %s %s)\n", hwVersion, __DATE__, __TIME__);
    if(hwVersion <= kSLTRev20131212_5WordsPerEvent /*is 0x41950242*/){
        NSLog(@"WARNING: You use a old SLT firmware - consider a update!\n");
        NSLog(@"WARNING: This version is supported, but you will miss some features!\n");
        NSLog(@"WARNING: KIT-IPE\n");
    }						  
	configStruct->card_info[index].deviceSpecificData[7] = hwVersion;	

	configStruct->card_info[index].num_Trigger_Indexes = 1;	//Just 1 group of objects controlled by SLT
    int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	for(id obj in dataTakers){
		if([obj respondsToSelector:@selector(load_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[0] == -1){
				configStruct->card_info[index].next_Trigger_Index[0] = nextIndex;
			}
			int savedIndex = nextIndex;
			nextIndex = [obj load_HW_Config_Structure:configStruct index:nextIndex];
			if(obj == [dataTakers lastObject]){
				configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
			}
		}
	}
	configStruct->card_info[index].next_Card_Index 	= nextIndex;	
	return index+1;
}
@end

@implementation OREdelweissSLTModel (private)
- (unsigned long) read:(unsigned long) address
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pmcLink readLongBlockPmc:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) write:(unsigned long) address value:(unsigned long) aValue
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink writeLongBlockPmc:&aValue
					  atAddress:address
					 numToWrite:1];
}


- (void) readBlock:(unsigned long)  address 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr
{
    //DEBUG   NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink readLongBlockPmc:   aDataBuffer
					  atAddress: address
					  numToRead: length];
}


@end

