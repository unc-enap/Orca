//
//  ORAmptekDP5Model.m
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
#import "ORAmptekDP5Model.h"
#import "OREdelweissFLTModel.h"
//#import "AmptekDP5v4_HW_Definitions.h"
//#import "AmptekDP5v4GeneralOperations.h"
#import "ipe4structure.h"
//#import "ORIpeFLTModel.h"
//#import "ORIpeCrateModel.h"
#import "ORIpeV4CrateModel.h"
//#import "ORAmptekDP5Defs.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PMC_Link.h"               //this is taken from IpeV4 SLT !!  -tb-
#import "ORPMCReadWriteCommand.h"  //this is taken from IpeV4 SLT !!  -tb-

#import "ORTaskSequence.h"
#import "ORFileMover.h"

#import "ORSafeQueue.h"

#include <pthread.h>




//is currently in ORIpeSlowControlModel.m -tb- 2015-08-26
@interface NSString (ParsingExtensions)
-(NSArray *)csvRows;
@end





//Amptek ASCII Commands
static AmptekDP5ASCIICommandsStruct amptekCmds[kAmptekNumCommands] = {
{@"MCAC",     @"1025",     @"1024",			1,			  @"MCA/MCS channels" , 1  },
{@"GAIA",     @"20",	       @"1",			 	1,			  @"Analog gain index [##]" , 2  },
{@"GAIF",     @"1.0",	 @"1.0",			1,			  @"Fine gain [##.###]" , 3  },
{@"GAIN",     @"1.00",	@"1.00",			 	1,			  @"Total gain (analog*fine) [##.###]" , 4  },
};


//IPE V4 register definitions
enum AmptekDP5V4Enum {
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





#if 0
// ... moved to header file ... -tb-
//threading
#define kMaxNumUDPDataPackets 100000
#define kMaxNumUDPStatusPackets 100  // currently (2013) we expect max. 9 packets; but size might increase and legacy opera status may appear: use min 30 -tb-
#define kMaxUDPSizeDim 1500     //see comment below
#define kMaxNumADCChan 720      //see comment below
	    //pthread handling
	    pthread_t dataReplyThread;
        pthread_mutex_t dataReplyThread_mutex;
        
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
#endif





void* receiveFromDataReplyServerThreadFunctionXXX (void* p);


void* receiveFromDataReplyServerThreadFunctionXXX (void* p)
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
	
	ssize_t retval=-1;
	
	
	int64_t l=0;
	int doRunLoop=true;
	dataReplyThreadData->started = 1;
	do{
	    l++;
		//usleep(10000);
		//NSLog(@"xxxxCalled    receiveFromDataReplyServerThreadFunctionXXX: %i stop %i started %i\n",l,dataReplyThreadData->stopNow,dataReplyThreadData->started);//TODO: DEBUG -tb-
		
		//
		//if(![dataReplyThreadData->model isListeningOnDataServerSocket]){
		if(dataReplyThreadData->stopNow){
			dataReplyThreadData->stopNow=0;
			dataReplyThreadData->started=0;
			NSLog(@"Called    receiveFromDataReplyServerThreadFunctionXXX with stopNow : %i \n",l);//TODO: DEBUG -tb-
			doRunLoop=false;//finish for loop
		}
		if(!dataReplyThreadData->isListeningOnDataServerSocket){
			dataReplyThreadData->stopNow=0;
			dataReplyThreadData->started=0;
			NSLog(@"Called    receiveFromDataReplyServerThreadFunctionXXX with !isListeningOnDataServerSocket : %i \n",l);//TODO: DEBUG -tb-
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
	        //TODO: this overloads now the Orca display ... NSLog(@"     receiveFromDataReplyServerThreadFunctionXXX: Got UDP data from %s!  \n", inet_ntoa(dataReplyThreadData->sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
	        //TODO: this overloads now the Orca display ... NSLog(@"     receiveFromDataReplyServerThreadFunctionXXX: Got UDP data from %s!  \n", inet_ntoa(dataReplyThreadData->sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
			
	    }
        
#if 0
        
        int counterData1444Packet=counterDataPacket;

	    if(retval == 1444 && counterData1444Packet==0){
	        NSLog(@"     receiveFromDataReplyServerThreadFunctionXXX: Got UDP data packet from %s!  \n",  inet_ntoa(dataReplyThreadData->sockaddr_data_from.sin_addr));//TODO: DEBUG -tb-
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
				    NSLog(@"                              SLT time: %llu \n",((((uint64_t) crateStatusBlock->SLTTimeHigh) << 32) | crateStatusBlock->SLTTimeLow) );
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
                    dataReplyThreadData->statusBufSize[*wrIndex][counterStatusPacket]=(int)retval;
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
                    dataReplyThreadData->adcBufSize[*wrIndex][index]=(int)size;
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
	
	
	
	NSLog(@"     >>>>>>>>>>>>> receiveFromDataReplyServerThreadFunctionXXX: loop FINISHED  \n");
	dataReplyThreadData->stopNow=0;
	dataReplyThreadData->started=0;
	
	
	
    return (void*)0;
}




#pragma mark ***External Strings

NSString* ORAmptekDP5ModelSerialNumberChanged = @"ORAmptekDP5ModelSerialNumberChanged";
NSString* ORAmptekDP5ModelFirmwareFPGAVersionChanged = @"ORAmptekDP5ModelFirmwareFPGAVersionChanged";
NSString* ORAmptekDP5ModelDetectorTemperatureChanged = @"ORAmptekDP5ModelDetectorTemperatureChanged";
NSString* ORAmptekDP5ModelDeviceIDChanged = @"ORAmptekDP5ModelDeviceIDChanged";
NSString* ORAmptekDP5ModelBoardTemperatureChanged = @"ORAmptekDP5ModelBoardTemperatureChanged";
NSString* ORAmptekDP5ModelSlowCounterChanged = @"ORAmptekDP5ModelSlowCounterChanged";
NSString* ORAmptekDP5ModelFastCounterChanged = @"ORAmptekDP5ModelFastCounterChanged";
NSString* ORAmptekDP5ModelRealTimeChanged = @"ORAmptekDP5ModelRealTimeChanged";
NSString* ORAmptekDP5ModelAcquisitionTimeChanged = @"ORAmptekDP5ModelAcquisitionTimeChanged";
NSString* ORAmptekDP5ModelDropFirstSpectrumChanged = @"ORAmptekDP5ModelDropFirstSpectrumChanged";
NSString* ORAmptekDP5ModelAutoReadbackSetpointChanged = @"ORAmptekDP5ModelAutoReadbackSetpointChanged";
NSString* ORAmptekDP5ModelCommandTableChanged = @"ORAmptekDP5ModelCommandTableChanged";
NSString* ORAmptekDP5ModelCommandQueueCountChanged = @"ORAmptekDP5ModelCommandQueueCountChanged";
NSString* ORAmptekDP5ModelIsPollingSpectrumChanged = @"ORAmptekDP5ModelIsPollingSpectrumChanged";
NSString* ORAmptekDP5ModelSpectrumRequestRateChanged = @"ORAmptekDP5ModelSpectrumRequestRateChanged";
NSString* ORAmptekDP5ModelSpectrumRequestTypeChanged = @"ORAmptekDP5ModelSpectrumRequestTypeChanged";
NSString* ORAmptekDP5ModelNumSpectrumBinsChanged = @"ORAmptekDP5ModelNumSpectrumBinsChanged";
NSString* ORAmptekDP5ModelTextCommandChanged = @"ORAmptekDP5ModelTextCommandChanged";
NSString* ORAmptekDP5ModelResetEventCounterAtRunStartChanged = @"ORAmptekDP5ModelResetEventCounterAtRunStartChanged";
NSString* ORAmptekDP5ModelLowLevelRegInHexChanged = @"ORAmptekDP5ModelLowLevelRegInHexChanged";
NSString* ORAmptekDP5ModelStatusRegHighChanged = @"ORAmptekDP5ModelStatusRegHighChanged";
NSString* ORAmptekDP5ModelStatusRegLowChanged = @"ORAmptekDP5ModelStatusRegLowChanged";
NSString* ORAmptekDP5ModelTakeADCChannelDataChanged = @"ORAmptekDP5ModelTakeADCChannelDataChanged";
NSString* ORAmptekDP5ModelTakeRawUDPDataChanged = @"ORAmptekDP5ModelTakeRawUDPDataChanged";
NSString* ORAmptekDP5ModelChargeBBFileChanged = @"ORAmptekDP5ModelChargeBBFileChanged";
NSString* ORAmptekDP5ModelUseBroadcastIdBBChanged = @"ORAmptekDP5ModelUseBroadcastIdBBChanged";
NSString* ORAmptekDP5ModelIdBBforWCommandChanged = @"ORAmptekDP5ModelIdBBforWCommandChanged";
NSString* ORAmptekDP5ModelTakeEventDataChanged = @"ORAmptekDP5ModelTakeEventDataChanged";
NSString* ORAmptekDP5ModelTakeUDPstreamDataChanged = @"ORAmptekDP5ModelTakeUDPstreamDataChanged";
NSString* ORAmptekDP5ModelCrateUDPDataCommandChanged = @"ORAmptekDP5ModelCrateUDPDataCommandChanged";
NSString* ORAmptekDP5ModelBBCmdFFMaskChanged = @"ORAmptekDP5ModelBBCmdFFMaskChanged";
NSString* ORAmptekDP5ModelCmdWArg4Changed = @"ORAmptekDP5ModelCmdWArg4Changed";
NSString* ORAmptekDP5ModelCmdWArg3Changed = @"ORAmptekDP5ModelCmdWArg3Changed";
NSString* ORAmptekDP5ModelCmdWArg2Changed = @"ORAmptekDP5ModelCmdWArg2Changed";
NSString* ORAmptekDP5ModelCmdWArg1Changed = @"ORAmptekDP5ModelCmdWArg1Changed";
NSString* ORAmptekDP5ModelSltDAQModeChanged = @"ORAmptekDP5ModelSltDAQModeChanged";
NSString* ORAmptekDP5ModelNumRequestedUDPPacketsChanged = @"ORAmptekDP5ModelNumRequestedUDPPacketsChanged";
NSString* ORAmptekDP5ModelIsListeningOnDataServerSocketChanged = @"ORAmptekDP5ModelIsListeningOnDataServerSocketChanged";
NSString* ORAmptekDP5ModelOpenCloseDataCommandSocketChanged = @"ORAmptekDP5ModelOpenCloseDataCommandSocketChanged";
NSString* ORAmptekDP5ModelCrateUDPDataReplyPortChanged = @"ORAmptekDP5ModelCrateUDPDataReplyPortChanged";
NSString* ORAmptekDP5ModelCrateUDPDataIPChanged = @"ORAmptekDP5ModelCrateUDPDataIPChanged";
NSString* ORAmptekDP5ModelCrateUDPDataPortChanged = @"ORAmptekDP5ModelCrateUDPDataPortChanged";
NSString* ORAmptekDP5ModelEventFifoStatusRegChanged = @"ORAmptekDP5ModelEventFifoStatusRegChanged";
NSString* ORAmptekDP5ModelPixelBusEnableRegChanged = @"ORAmptekDP5ModelPixelBusEnableRegChanged";
NSString* ORAmptekDP5ModelSelectedFifoIndexChanged = @"ORAmptekDP5ModelSelectedFifoIndexChanged";
NSString* ORAmptekDP5ModelIsListeningOnServerSocketChanged = @"ORAmptekDP5ModelIsListeningOnServerSocketChanged";
NSString* ORAmptekDP5ModelCrateUDPCommandChanged = @"ORAmptekDP5ModelCrateUDPCommandChanged";
NSString* ORAmptekDP5ModelCrateUDPReplyPortChanged = @"ORAmptekDP5ModelCrateUDPReplyPortChanged";
NSString* ORAmptekDP5ModelCrateUDPCommandIPChanged = @"ORAmptekDP5ModelCrateUDPCommandIPChanged";
NSString* ORAmptekDP5ModelCrateUDPCommandPortChanged = @"ORAmptekDP5ModelCrateUDPCommandPortChanged";
NSString* ORAmptekDP5ModelSecondsSetInitWithHostChanged = @"ORAmptekDP5ModelSecondsSetInitWithHostChanged";
NSString* ORAmptekDP5ModelSltScriptArgumentsChanged = @"ORAmptekDP5ModelSltScriptArgumentsChanged";

NSString* ORAmptekDP5ModelClockTimeChanged = @"ORAmptekDP5ModelClockTimeChanged";
NSString* ORAmptekDP5ModelRunTimeChanged = @"ORAmptekDP5ModelRunTimeChanged";
NSString* ORAmptekDP5ModelVetoTimeChanged = @"ORAmptekDP5ModelVetoTimeChanged";
NSString* ORAmptekDP5ModelDeadTimeChanged = @"ORAmptekDP5ModelDeadTimeChanged";
NSString* ORAmptekDP5ModelSecondsSetChanged		= @"ORAmptekDP5ModelSecondsSetChanged";
NSString* ORAmptekDP5ModelStatusRegChanged		= @"ORAmptekDP5ModelStatusRegChanged";
NSString* ORAmptekDP5ModelControlRegChanged		= @"ORAmptekDP5ModelControlRegChanged";
NSString* ORAmptekDP5ModelFanErrorChanged		= @"ORAmptekDP5ModelFanErrorChanged";
NSString* ORAmptekDP5ModelVttErrorChanged		= @"ORAmptekDP5ModelVttErrorChanged";
NSString* ORAmptekDP5ModelGpsErrorChanged		= @"ORAmptekDP5ModelGpsErrorChanged";
NSString* ORAmptekDP5ModelClockErrorChanged		= @"ORAmptekDP5ModelClockErrorChanged";
NSString* ORAmptekDP5ModelPpsErrorChanged		= @"ORAmptekDP5ModelPpsErrorChanged";
NSString* ORAmptekDP5ModelPixelBusErrorChanged	= @"ORAmptekDP5ModelPixelBusErrorChanged";
NSString* ORAmptekDP5ModelHwVersionChanged		= @"ORAmptekDP5ModelHwVersionChanged";

NSString* ORAmptekDP5ModelPatternFilePathChanged		= @"ORAmptekDP5ModelPatternFilePathChanged";
NSString* ORAmptekDP5ModelInterruptMaskChanged		= @"ORAmptekDP5ModelInterruptMaskChanged";
NSString* ORAmptekDP5PulserDelayChanged				= @"ORAmptekDP5PulserDelayChanged";
NSString* ORAmptekDP5PulserAmpChanged				= @"ORAmptekDP5PulserAmpChanged";
NSString* ORAmptekDP5SettingsLock					= @"ORAmptekDP5SettingsLock";
NSString* ORAmptekDP5StatusRegChanged				= @"ORAmptekDP5StatusRegChanged";
NSString* ORAmptekDP5ControlRegChanged				= @"ORAmptekDP5ControlRegChanged";
NSString* ORAmptekDP5SelectedRegIndexChanged			= @"ORAmptekDP5SelectedRegIndexChanged";
NSString* ORAmptekDP5WriteValueChanged				= @"ORAmptekDP5WriteValueChanged";
NSString* ORAmptekDP5ModelNextPageDelayChanged		= @"ORAmptekDP5ModelNextPageDelayChanged";
NSString* ORAmptekDP5ModelPollRateChanged			= @"ORAmptekDP5ModelPollRateChanged";

NSString* ORAmptekDP5ModelPageSizeChanged			= @"ORAmptekDP5ModelPageSizeChanged";
NSString* ORAmptekDP5ModelDisplayTriggerChanged		= @"ORAmptekDP5ModelDisplayTrigerChanged";
NSString* ORAmptekDP5ModelDisplayEventLoopChanged	= @"ORAmptekDP5ModelDisplayEventLoopChanged";
NSString* ORAmptekDP5V4cpuLock							= @"ORAmptekDP5V4cpuLock";

@interface ORAmptekDP5Model (private)
- (uint32_t) read:(uint32_t) address;
- (void) write:(uint32_t) address value:(uint32_t) aValue;
@end

@implementation ORAmptekDP5Model

- (id) init
{
    self = [super init];
	//ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	//[self setReadOutGroup:readList];
    //[self makePoller:0];
	//[readList release];


	[self setSecondsSetInitWithHost: YES];
	[self registerNotificationObservers];
	//some defaults
	crateUDPCommandPort = 10001;
	crateUDPCommandIP = @"192.168.1.102";
    
	//if(!commandTable)  commandTable = [[NSMutableArray array] retain];
    [self initCommandTable];
    
    useCommandQueue=YES;//just for debugging -tb-

    
    
    //TODO: REMOVE
//	crateUDPReplyPort = 9940;
    
//    crateUDPDataPort = 994;
//    crateUDPDataIP = @"192.168.1.100";
//    crateUDPDataReplyPort = 12345;
	
    deviceId = -1;
    
    minValue[0]=-128.0; maxValue[0]=128.0; lowLimit[0]=0.0; hiLimit[0]=80.0;
    minValue[1]=0.0;    maxValue[1]=300.0; lowLimit[1]=0.0; hiLimit[1]=280.0;
    { int i; for(i=2; i<10; i++){minValue[i]=-128.0; maxValue[i]=128.0; lowLimit[i]=0.0; hiLimit[i]=80.0;} }
    
    return self;
}

-(void) dealloc
{
    [lastRequest release];
    [textCommand release];
    [crateUDPCommand release];
    [crateUDPCommandIP release];
    [sltScriptArguments release];
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [poller stop];
    [poller release];
    [commandTable release];
    
	[cmdQueue release];
    
    
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
    [poller stop];
}

- (void) awakeAfterDocumentLoaded
{
#if 0 //TODO: remove SLT stuff -tb-   2014 

	@try {
		if(!pmcLink){
			pmcLink = [[PMC_Link alloc] initWithDelegate:self];
		}
		[pmcLink connect];
	}
	@catch(NSException* localException) {
	}
#endif




}

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"AmptekDP5Card"]]; }
- (void) makeMainController	{ [self linkToController:@"ORAmptekDP5Controller"];		}






#if 0

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
#endif  





#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
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



#pragma mark •••Commands
- (void) queueStringCommand:(NSString*)aCommand
{
    //DEBUG    
        NSLog(@"Called %@::%@  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
        
	if(!cmdQueue)cmdQueue = [[ORSafeQueue alloc] init];
	[cmdQueue enqueue:aCommand];
    //DEBUG            NSLog(@"       %@::%@  queue count: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self commandQueueCount]);//TODO: DEBUG -tb-
   //         sleep(1);

	[[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCommandQueueCountChanged object: self];
    
	if(!lastRequest)[self processOneCommandFromQueue];//wait until response returned ...
}



#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors

- (int) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(int)aSerialNumber
{
    serialNumber = aSerialNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSerialNumberChanged object:self];
}

- (int) FirmwareFPGAVersion
{
    return FirmwareFPGAVersion;
}

- (void) setFirmwareFPGAVersion:(int)aFirmwareFPGAVersion
{
    FirmwareFPGAVersion = aFirmwareFPGAVersion;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelFirmwareFPGAVersionChanged object:self];
}

- (int) detectorTemperature
{
    return detectorTemperature;
}

- (void) setDetectorTemperature:(int)aDetectorTemperature
{
    detectorTemperature = aDetectorTemperature;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelDetectorTemperatureChanged object:self];
}

- (int) deviceId
{
    return deviceId;
}

- (void) setDeviceId:(int)aDeviceId
{
    deviceId = aDeviceId;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelDeviceIDChanged object:self];
}

- (int) boardTemperature
{
    return boardTemperature;
}

- (void) setBoardTemperature:(int)aBoardTemperature
{
    boardTemperature = aBoardTemperature;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelBoardTemperatureChanged object:self];
}


#if 0
- (NSData*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSData*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;
}
#endif

- (int) commandQueueCount
{
    return (int)[cmdQueue count];
}

- (ORSafeQueue*) commandQueue
{
    return cmdQueue;
}

- (void) clearCommandQueue
{
    if([cmdQueue count]>0){
        [cmdQueue removeAllObjects]; //if we timeout we just flush the queue
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCommandQueueCountChanged object: self];

    }
}



- (void) processOneCommandFromQueue
{
    //DEBUG    
        NSLog(@"Called %@::%@  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
        
	if([cmdQueue count] > 0){
		NSString* cmd = [cmdQueue dequeue];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCommandQueueCountChanged object: self];
        if([cmd hasPrefix:@"+ra:"]){//readback ascii command -tb-
            [self readbackTextCommandString: [cmd substringFromIndex:4]];
        }else
        if([cmd hasPrefix:@"+wa:"]){//readback ascii command -tb-
            [self sendTextCommandString: [cmd substringFromIndex:4]];
        }else
        {
        }
    }
    
}

//mainly for debugging, not accessible for users - set it to false to directly send commands to Amptek DP5 -tb-
- (BOOL) useCommandQueue
{ return useCommandQueue; }

- (void) setUseCommandQueue:(BOOL)aValue
{  useCommandQueue=aValue; }




- (NSMutableArray*) commandTable
{ return commandTable; }

- (void) setCommandTable:(NSMutableArray*)aArray
{
    [commandTable release];
    commandTable = aArray;
    [commandTable retain];
}


- (NSDictionary*) commandTableRow:(int)row
{
    if(row<[commandTable count]) return [commandTable objectAtIndex: row];
    return 0;
}



- (int) commandTableCount
{
    if(!commandTable) return 0;
	return (int)[commandTable count];
}


- (void) initCommandTable
{
	if(!commandTable)  commandTable = [[NSMutableArray array] retain];
    else [commandTable removeAllObjects];

    int i;
    for(i=0; i<kAmptekNumCommands;i++){
        NSMutableDictionary* commandTableRow = [NSMutableDictionary dictionary];
	    [commandTableRow setObject: amptekCmds[i].name		    forKey:@"Name"]; //used by processing
	    [commandTableRow setObject: amptekCmds[i].value		    forKey:@"Value"]; //used by processing
	    [commandTableRow setObject: [NSNumber numberWithInt: amptekCmds[i].init]		    forKey:@"Init"]; //used by processing
	    [commandTableRow setObject: amptekCmds[i].comment		forKey:@"Comment"]; //used by processing
	    [commandTableRow setObject: [NSNumber numberWithInt: amptekCmds[i].id]		    forKey:@"ID"]; //used by processing
//	    [commandTableRow setObject:[NSNumber numberWithInt:0]		forKey:@"LoAlarm"]; //used by processing

        [commandTable addObject: commandTableRow];
        //[commandTable replaceObjectAtIndex: i withObject: commandTableRow];
    }
    
    
    
    //DEBUG      
            NSLog(@"%@::%@ commandTable is:%@\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd),commandTable);//DEBUG OUTPUT -tb-  
    
}


- (int) setCommandTableItem:(NSString*)itemName setObject:(id)object forKey:(NSString*)key
{
    int retval=0, num=(int)[commandTable count];
    int i;
    for(i=0;i<num;i++){
        NSMutableDictionary* line = [commandTable objectAtIndex:i];
        NSString* name = [line objectForKey: @"Name"];
        if([name isEqualToString: itemName]){
            [line setObject: object forKey:key];
            retval++;
        }
    }
    
    return retval;
}

- (int) setCommandTableRow:(int)row setObject:(id)object forKey:(NSString*)key
{
    int num=(int)[commandTable count];

    if(row >= 0 && row<num){
        NSMutableDictionary* line = [commandTable objectAtIndex:row];
        [line setObject: object forKey:key];
        return 1;
    }
    
    return 0;
}



- (BOOL) loadCommandTableFile:(NSString*) filename
{
    BOOL success = FALSE;
    
    //DEBUG
	NSLog(@"Called: %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug output -tb-

    NSStringEncoding encoding=0;
	
    NSError* error=nil;
    NSString* myString = [NSString stringWithContentsOfFile:filename usedEncoding:&encoding error:&error];
	if(error) NSLog(@"Error >>>%@<<<\n",error);
	if(!myString){
	    NSLog(@"Could not read file!\n");
	    return FALSE;
	}
	//NSLog(@"Encoding >>>%i<<<\n",encoding);
	//NSLog(@"Read string >>>%@<<<\n",myString);
    //NSLog(@"Read with encoding %@ string >>>%@<<<\n",&encoding,myString);

    NSArray *csvtable = [myString csvRows];
	if(!csvtable) return FALSE;
	int nlines = (int)[csvtable count];
	//if(csvtable) NSLog(@"csvtable (%i lines) >>>%@<<<\n", nlines, csvtable);//TODO: enable with debug output setting??? -tb-
	if(nlines<=1) return FALSE;
	
	int indexName, indexSetpoint, indexValue, indexInit, indexComment, indexId;
	NSArray *colnames = [csvtable objectAtIndex: 0];
	indexName = (int)[colnames indexOfObject: @"Name"];
	indexSetpoint = (int)[colnames indexOfObject: @"Setpoint"];
	indexValue = (int)[colnames indexOfObject: @"Value"];
	indexInit = (int)[colnames indexOfObject: @"Init"];
	indexComment = (int)[colnames indexOfObject: @"Comment"];
	indexId = (int)[colnames indexOfObject: @"ID"];
	
	
    //DEBUG
	//NSLog(@"Called: %@::%@  indexName,indexValue,indexInit,indexComment,indexId is %i,%i,%i,%i,%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),indexName,indexValue,indexInit,indexComment,indexId);//TODO: debug output -tb-
	
	//NSLog(@"colnames >>>%@<<<\n", colnames);
	//NSLog(@"indexChan, indexName, indexURL, indexPath, indexLoAlarm, indexHiAlarm, indexLoLimit, indexHiLimit, indexType is %i, %i, %i, %i, %i, %i, %i, %i, %i \n", 
	//        indexChan, indexName, indexURL, indexPath, indexLoAlarm, indexHiAlarm, indexLoLimit, indexHiLimit, indexType);

    //now create command entry
    //NSMutableArray * newCommandTable = [[NSMutableArray alloc] initWithCapacity:10]; autorelease?
    NSMutableArray * newCommandTable = [[NSMutableArray array] retain];
    NSMutableDictionary* commandTableRow;
    NSArray *line;
	int init=0, id=0;
	NSString *name;
	NSString *setpoint;
	NSString *value;
	NSString *comment;
	int i;
    for(i=1; i<nlines; i++){
	    line = [csvtable objectAtIndex: i];
		//NSLog(@"Scan line: %@  \n",line);
//[self dumpSensorlist];// dumps the requestCache and others  -tb-


//TODO: check for double existing entries???
//        itemKey = [channelLookup objectForKey:[NSNumber numberWithInt:chan]];
//		if(itemKey) NSLog(@"The channel %i is already used by %@!\n",chan,itemKey);
//
	    name =  [line  objectAtIndex: indexName] ;
	    setpoint =  [line  objectAtIndex: indexSetpoint] ;
	    value =  [line  objectAtIndex: indexValue] ;
	    comment =  [line  objectAtIndex: indexComment] ;
	    init = [[line  objectAtIndex: indexInit] intValue];
	    id = [[line  objectAtIndex: indexId] intValue];

    //DEBUG

	//NSLog(@"Called: %@::%@: Command is: %@, %@, init:%i, Comment:%@, ID:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),
    //     name, value, init,comment,id);//TODO: debug output -tb-
         
        commandTableRow = [NSMutableDictionary dictionary];
	    [commandTableRow setObject: name		    forKey:@"Name"]; //used by processing
	    [commandTableRow setObject: setpoint		    forKey:@"Setpoint"]; //used by processing
	    [commandTableRow setObject: value		    forKey:@"Value"]; //used by processing
	    [commandTableRow setObject: [NSNumber numberWithInt: init]		    forKey:@"Init"]; //used by processing
	    [commandTableRow setObject: comment		forKey:@"Comment"]; //used by processing
	    [commandTableRow setObject: [NSNumber numberWithInt: id]		    forKey:@"ID"]; //used by processing
//	    [commandTableRow setObject:[NSNumber numberWithInt:0]		forKey:@"LoAlarm"]; //used by processing

        [newCommandTable addObject: commandTableRow];
        
        success = TRUE;


//TODO: check for double existing entries???
//		chantest = [self findChanOfItem: url path: path];
//		if(chantest != -1){
//		    NSLog(@"This item already exists! (%@  ,  %@)\n",url,path);
//			continue;
//		}
		
		//create new chan
		//NSLog(@"Create: URL:%@  ,  path:%@  \n",url,path);
//		newchan = [self createChannelWithUrl:url path:path chan:chan controlType:controlType];// if chan already used, it will assign a free chan and return it
//TODO: check for double existing entries???
//		if(newchan != chan) NSLog(@"Created chan %i instead of chan %i with  URL:%@  ,  path:%@  \n",newchan, chan, url,path);
        //... and make settings

	}

    //TODO: handle undo??? -tb-
    if(success){
        [savedCommandTable release];
        savedCommandTable = commandTable;
        commandTable = newCommandTable;
    }

    if(success) [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCommandTableChanged object:self];

    return success;
}


- (BOOL) saveAsCommandTableFile:(NSString*) filename
{
    //DEBUG        	NSLog(@"Called: %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug output -tb-
        
    int num = (int)[commandTable count];
    //DEBUG            NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
	NSMutableString *csvtableString = [NSMutableString stringWithString: @"Name,Setpoint,Value,Init,Comment,ID\n"];
    
    NSMutableDictionary* line;
   	NSString *name;
	NSString *setpoint;
	NSString *value;
	NSString *comment;
    int init, id;

    int i; //row index
    for(i=0; i<num; i++){
        line = [commandTable objectAtIndex:i];
        name = [line objectForKey: @"Name"];
        setpoint = [line objectForKey: @"Setpoint"];
        value = [line objectForKey: @"Value"];
        comment = [line objectForKey: @"Comment"];
        init = [[line objectForKey: @"Init"] intValue];
        id = [[line objectForKey: @"ID"] intValue];
        
		[csvtableString appendFormat: @"%@,%@,%@,%i,\"%@\",%i\n",name,setpoint,value,init,comment,id];
    }
    
	//NSLog(@"TABLE:>>>%@<<<\n",csvtableString);
    //return TRUE;
    
	BOOL success = [csvtableString writeToFile: filename atomically: YES encoding: NSASCIIStringEncoding  error: nil];
	//could use [filename stringByExpandingTildeInPath] instead of filename -tb-
	if(!success) NSLog(@"ERROR during writing the channel table to %@ ...\n",filename);
	
	return success;
}

- (NSString*) getCommandTableAsString
{
        //DEBUG        	NSLog(@"Called: %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug output -tb-
        
    int num = (int)[commandTable count];
    //DEBUG            NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
	NSMutableString *csvtableString = [NSMutableString stringWithString: @"Name,Setpoint,Value,Init,Comment,ID\n"];
    
    NSMutableDictionary* line;
   	NSString *name;
	NSString *setpoint;
	NSString *value;
	NSString *comment;
    int init, id;

    int i; //row index
    for(i=0; i<num; i++){
        line = [commandTable objectAtIndex:i];
        name = [line objectForKey: @"Name"];
        setpoint = [line objectForKey: @"Setpoint"];
        value = [line objectForKey: @"Value"];
        comment = [line objectForKey: @"Comment"];
        init = [[line objectForKey: @"Init"] intValue];
        id = [[line objectForKey: @"ID"] intValue];
        
		[csvtableString appendFormat: @"%@,%@,%@,%i,\"%@\",%i\n",name,setpoint,value,init,comment,id];
    }
    
    if(csvtableString == nil)  return @"";
    
    return csvtableString;
    

}








// listCommonScriptMethods
//-------------should use only these methods in scripts---------------------------------
- (NSString*) commonScriptMethods
{
    NSMutableString *methods = [[NSMutableString alloc] init];
    //I return two types of methods:
    #if 0
	// 1. manually added methods
	NSArray* selectorArray = [NSArray arrayWithObjects:
							  @"convertedValue:(int)channel",
							  @"maxValueForChan:(int)channel",
							  @"minValueForChan:(int)channel",
							  nil];
    
    [methods appendString: [selectorArray componentsJoinedByString:@"\n"]];
    [methods appendString: @"\n"];
	#endif
    

	// 2. all methods between methods commonScriptMethodSectionBegin and commonScriptMethodSectionBegin
    [methods appendString: methodsInCommonSection(self)];

    return [methods autorelease];
}







//-------------Methode to flag beginning of common script methods---------------------------------
- (void) commonScriptMethodSectionBegin { }





- (int) spectrumRequestRate
{
    return spectrumRequestRate;
}

- (void) setSpectrumRequestRate:(int)aSpectrumRequestRate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSpectrumRequestRate:spectrumRequestRate];
    
    spectrumRequestRate = aSpectrumRequestRate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSpectrumRequestRateChanged object:self];
}


//this is the pid2 of the "Spectrum Request Packets", section 4.1.2, p.20, of DP5  Programmers Guide
- (int) spectrumRequestType
{
    return spectrumRequestType;
}

- (void) setSpectrumRequestType:(int)aSpectrumRequestType
{
    if(aSpectrumRequestType<1) aSpectrumRequestType=1;
    if(aSpectrumRequestType>4) aSpectrumRequestType=4;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setSpectrumRequestType:spectrumRequestType];
    
    spectrumRequestType = aSpectrumRequestType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSpectrumRequestTypeChanged object:self];
}







- (BOOL) dropFirstSpectrum
{
    return dropFirstSpectrum;
}

- (void) setDropFirstSpectrum:(BOOL)aDropFirstSpectrum
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDropFirstSpectrum:dropFirstSpectrum];
    
    dropFirstSpectrum = aDropFirstSpectrum;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelDropFirstSpectrumChanged object:self];
}

- (BOOL) autoReadbackSetpoint
{
    return autoReadbackSetpoint;
}

- (void) setAutoReadbackSetpoint:(BOOL)aAutoReadbackSetpoint
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoReadbackSetpoint:autoReadbackSetpoint];
    
    autoReadbackSetpoint = aAutoReadbackSetpoint;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelAutoReadbackSetpointChanged object:self];
}


- (int) slowCounter
{
    return slowCounter;
}

- (void) setSlowCounter:(int)aSlowCounter
{
    slowCounter = aSlowCounter;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSlowCounterChanged object:self];
}

- (int) fastCounter
{
    return fastCounter;
}

- (void) setFastCounter:(int)aFastCounter
{
    fastCounter = aFastCounter;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelFastCounterChanged object:self];
}

- (int) realTime
{
    return realTime;
}

- (void) setRealTime:(int)aRealTime
{
    realTime = aRealTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelRealTimeChanged object:self];
}

- (int) acquisitionTime
{
    return acquisitionTime;
}

- (void) setAcquisitionTime:(int)aAcquisitionTime
{
    acquisitionTime = aAcquisitionTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelAcquisitionTimeChanged object:self];
}




//very simple method to control ADC value display , NOT persistent (according to Norman this is OK if controllable thru scripts) -tb-
- (double) setMaxValue: (double)val forChan:(int)channel
{
    if(channel>=0 && channel<10){ maxValue[channel]=val; return val;}
    return 0.0;
}

- (double) setMinValue: (double)val forChan:(int)channel
{
    if(channel>=0 && channel<10){ minValue[channel]=val; return val;}
    return 0.0;
}

- (void) setAlarmRangeLow:(double)theLowLimit high:(double)theHighLimit  forChan:(int)channel
{
    if(channel>=0 && channel<10){ lowLimit[channel]=theLowLimit; hiLimit[channel]=theHighLimit; }
}


- (void) commonScriptMethodSectionEnd { }
//-------------end of common script methods---------------------------------








- (NSString*) lastRequest
{
    return lastRequest;
}

- (void) setLastRequest:(NSString*)aLastRequest
{
    //the code wizard version
    #if 0
    [lastRequest autorelease];
    lastRequest = [aLastRequest copy];    
    #endif    
    
    //new version from e.g. ORPacFPModel.m (which one to use?)
    #if 1
	[aLastRequest retain];
	[lastRequest release];
	lastRequest = aLastRequest;    
    #endif    
}

- (int) isPollingSpectrum
{
    return isPollingSpectrum;
}

- (void) setIsPollingSpectrum:(int)aIsPollingSpectrum
{
    isPollingSpectrum = aIsPollingSpectrum;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelIsPollingSpectrumChanged object:self];
}


//currently not used any more - instead, we are polling gettimeofday ... in takeData ... -tb-
- (void) requestSpectrumTimedWorker
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestSpectrumTimedWorker) object:nil];

    NSLog(@"POLL  -----  Called %@::%@!  spectrumRequestRate: %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), spectrumRequestRate);//TODO: DEBUG -tb-
    [self requestSpectrum];
    
    if(isPollingSpectrum)
    	[self performSelector:@selector(requestSpectrumTimedWorker) withObject:nil afterDelay: spectrumRequestRate];

}


- (int) numSpectrumBins
{
    return numSpectrumBins;
}

- (void) setNumSpectrumBins:(int)aNumSpectrumBins
{
    //DEBUG NSLog(@"Called %@::%@! aNumSpectrumBins: %i  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aNumSpectrumBins);//TODO: DEBUG -tb-
    if(aNumSpectrumBins < 256) aNumSpectrumBins = 256;
    if(aNumSpectrumBins > 8192) aNumSpectrumBins = 8192;
    //allowed values: 256, 512, 1024, 2048, 4096, 8192
    int i, highestBit=0;
    //search highest bit ...
    for(i=0; i<15; i++){
        if( (aNumSpectrumBins >> i) & 0x1){
            highestBit = i;
        }
    }
    //DEBUG NSLog(@"Called %@::%@! highest bit: %i setTo: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),highestBit, 0x1 << highestBit);//TODO: DEBUG -tb-
    aNumSpectrumBins = 0x1 << highestBit;
    [[[self undoManager] prepareWithInvocationTarget:self] setNumSpectrumBins:numSpectrumBins];
    
    numSpectrumBins = aNumSpectrumBins;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelNumSpectrumBinsChanged object:self];
}

- (NSString*) textCommand
{
    if(textCommand==nil) return @"";
    return textCommand;
}

- (void) setTextCommand:(NSString*)aTextCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTextCommand:textCommand];
    
    [textCommand autorelease];
    textCommand = [aTextCommand copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelTextCommandChanged object:self];
}

- (int) resetEventCounterAtRunStart
{
    return resetEventCounterAtRunStart;
}

- (void) setResetEventCounterAtRunStart:(int)aResetEventCounterAtRunStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setResetEventCounterAtRunStart:resetEventCounterAtRunStart];
    
    resetEventCounterAtRunStart = aResetEventCounterAtRunStart;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelResetEventCounterAtRunStartChanged object:self];
}

- (int) lowLevelRegInHex
{
    return lowLevelRegInHex;
}

- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowLevelRegInHex:lowLevelRegInHex];

    lowLevelRegInHex = aLowLevelRegInHex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelLowLevelRegInHexChanged object:self];
}



//TODO: rm   slt - - 
#if 0
- (uint32_t) statusHighReg
{
    return statusHighReg;
}

- (void) setStatusHighReg:(uint32_t)aStatusRegHigh
{
    statusHighReg = aStatusRegHigh;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelStatusRegHighChanged object:self];
}

- (uint32_t) statusLowReg
{
    return statusLowReg;
}

- (void) setStatusLowReg:(uint32_t)aStatusRegLow
{
    statusLowReg = aStatusRegLow;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelStatusRegLowChanged object:self];
}
#endif








- (int) takeADCChannelData
{
    return takeADCChannelData;
}

- (void) setTakeADCChannelData:(int)aTakeADCChannelData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeADCChannelData:takeADCChannelData];
    
    takeADCChannelData = aTakeADCChannelData;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelTakeADCChannelDataChanged object:self];
}

- (int) takeRawUDPData
{
    return takeRawUDPData;
}

- (void) setTakeRawUDPData:(int)aTakeRawUDPData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeRawUDPData:takeRawUDPData];
    takeRawUDPData = aTakeRawUDPData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelTakeRawUDPDataChanged object:self];
}




#if 0
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelChargeBBFileChanged object:self];
}

- (bool) useBroadcastIdBB
{
    return useBroadcastIdBB;
}

- (void) setUseBroadcastIdBB:(bool)aUseBroadcastIdBB
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseBroadcastIdBB:useBroadcastIdBB];
    useBroadcastIdBB = aUseBroadcastIdBB;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelUseBroadcastIdBBChanged object:self];
}

- (int) idBBforWCommand
{
    return idBBforWCommand;
}

- (void) setIdBBforWCommand:(int)aIdBBforWCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIdBBforWCommand:idBBforWCommand];
    idBBforWCommand = aIdBBforWCommand;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelIdBBforWCommandChanged object:self];
}





- (int) takeEventData
{
    return takeEventData;
}

- (void) setTakeEventData:(int)aTakeEventData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeEventData:takeEventData];
    takeEventData = aTakeEventData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelTakeEventDataChanged object:self];
}

- (int) takeUDPstreamData
{
    return takeUDPstreamData;
}

- (void) setTakeUDPstreamData:(int)aTakeUDPstreamData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTakeUDPstreamData:takeUDPstreamData];
    takeUDPstreamData = aTakeUDPstreamData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelTakeUDPstreamDataChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPDataCommandChanged object:self];
}

- (uint32_t) BBCmdFFMask
{
    return BBCmdFFMask;
}

- (void) setBBCmdFFMask:(uint32_t)aBBCmdFFMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBBCmdFFMask:BBCmdFFMask];
    BBCmdFFMask = aBBCmdFFMask & 0xff;//is only 8 bit
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelBBCmdFFMaskChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCmdWArg4Changed object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCmdWArg3Changed object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCmdWArg2Changed object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCmdWArg1Changed object:self];
}

#endif









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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSltDAQModeChanged object:self];
}



#if 0
- (int) numRequestedUDPPackets
{
    return numRequestedUDPPackets;
}

- (void) setNumRequestedUDPPackets:(int)aNumRequestedUDPPackets
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumRequestedUDPPackets:numRequestedUDPPackets];
    numRequestedUDPPackets = aNumRequestedUDPPackets;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelNumRequestedUDPPacketsChanged object:self];
}
#endif






- (int) isListeningOnDataServerSocket
{
    return isListeningOnDataServerSocket;
}

- (void) setIsListeningOnDataServerSocket:(int)aIsListeningOnDataServerSocket
{
    isListeningOnDataServerSocket = aIsListeningOnDataServerSocket;
	dataReplyThreadData.isListeningOnDataServerSocket=isListeningOnDataServerSocket;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelIsListeningOnDataServerSocketChanged object:self];
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





#if 0
- (int) crateUDPDataReplyPort
{
    return crateUDPDataReplyPort;
}

- (void) setCrateUDPDataReplyPort:(int)aCrateUDPDataReplyPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataReplyPort:crateUDPDataReplyPort];
    crateUDPDataReplyPort = aCrateUDPDataReplyPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPDataReplyPortChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPDataIPChanged object:self];
}

- (int) crateUDPDataPort
{
    return crateUDPDataPort;
}

- (void) setCrateUDPDataPort:(int)aCrateUDPDataPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPDataPort:crateUDPDataPort];
    crateUDPDataPort = aCrateUDPDataPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPDataPortChanged object:self];
}
#endif







#if 0
- (uint32_t) eventFifoStatusReg
{
    return eventFifoStatusReg;
}

- (void) setEventFifoStatusReg:(uint32_t)aEventFifoStatusReg
{
    eventFifoStatusReg = aEventFifoStatusReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelEventFifoStatusRegChanged object:self];
}

- (uint32_t) pixelBusEnableReg
{
    return pixelBusEnableReg;
}

- (void) setPixelBusEnableReg:(uint32_t)aPixelBusEnableReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPixelBusEnableReg:pixelBusEnableReg];
    pixelBusEnableReg = aPixelBusEnableReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelPixelBusEnableRegChanged object:self];
}

- (int) selectedFifoIndex
{
    return selectedFifoIndex;
}

- (void) setSelectedFifoIndex:(int)aSelectedFifoIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedFifoIndex:selectedFifoIndex];
    selectedFifoIndex = aSelectedFifoIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSelectedFifoIndexChanged object:self];
}
#endif






- (int) isListeningOnServerSocket//used for DP5
{
    return isListeningOnServerSocket;
}

- (void) setIsListeningOnServerSocket:(int)aIsListeningOnServerSocket//used for DP5, ((TODO: rename it -tb-
{
    isListeningOnServerSocket = aIsListeningOnServerSocket;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelIsListeningOnServerSocketChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPCommandChanged object:self];
}





#if 0
- (int) crateUDPReplyPort
{
    return crateUDPReplyPort;
}

- (void) setCrateUDPReplyPort:(int)aCrateUDPReplyPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPReplyPort:crateUDPReplyPort];
    crateUDPReplyPort = aCrateUDPReplyPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPReplyPortChanged object:self];
}
#endif





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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPCommandIPChanged object:self];
}

- (int) crateUDPCommandPort
{
    return crateUDPCommandPort;
}

- (void) setCrateUDPCommandPort:(int)aCrateUDPCommandPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCrateUDPCommandPort:crateUDPCommandPort];
    crateUDPCommandPort = aCrateUDPCommandPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCrateUDPCommandPortChanged object:self];
}
- (BOOL) secondsSetInitWithHost
{
    return secondsSetInitWithHost;
}

- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSetInitWithHost:secondsSetInitWithHost];
    secondsSetInitWithHost = aSecondsSetInitWithHost;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSecondsSetInitWithHostChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelSltScriptArgumentsChanged object:self];
	
	//NSLog(@"%@::%@  is %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),sltScriptArguments);//TODO: debug -tb-
}

- (uint64_t) clockTime //TODO: rename to 'time' ? -tb-
{
    return clockTime;
}

- (void) setClockTime:(uint64_t)aClockTime
{
    clockTime = aClockTime;
 	//NSLog(@"   %@::%@:   clockTime: 0x%016qx from aClockTime: 0x%016qx   \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),clockTime , aClockTime);//TODO: DEBUG testing ...-tb-
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelClockTimeChanged object:self];
}


- (uint32_t) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(uint32_t)aStatusReg
{
    statusReg = aStatusReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelStatusRegChanged object:self];
}

- (uint32_t) controlReg
{
    return controlReg;
}

- (void) setControlReg:(uint32_t)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    controlReg = aControlReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelControlRegChanged object:self];
}

- (uint32_t) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (uint32_t) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (uint32_t) implementation  { return hwVersion & kImplemention;}
- (uint32_t) hwVersion       { return hwVersion ;}//=SLT FPGA version/revision

- (void) setHwVersion:(uint32_t) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelHwVersionChanged object:self];	
}


- (void) writeEvRes				{ [self writeReg:kEWSltV4CommandReg value:kEWCmdEvRes];   }
- (void) writeFwCfg				{ [self writeReg:kEWSltV4CommandReg value:kEWCmdFwCfg];   }
- (void) writeSltReset			{ [self writeReg:kEWSltV4CommandReg value:kEWCmdSltReset];   }
- (void) writeFltReset			{ [self writeReg:kEWSltV4CommandReg value:kEWCmdFltReset];   }

- (id) controllerCard		{ return self;	  }

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


#if 0 //omit #import "ORAmptekDP5Defs.h"
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	[self shipSltSecondCounter: kStopSubRunType];
	//TODO: I could set inhibit to measure the 'netto' run time precisely -tb-
    
#endif
}


- (void) runIsStartingSubRun:(NSNotification*)aNote
{
#if 0 //omit #import "ORAmptekDP5Defs.h"

	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	[self shipSltSecondCounter: kStartSubRunType];
#endif



}


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors

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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelPatternFilePathChanged object:self];
}

- (uint32_t) nextPageDelay
{
	return nextPageDelay;
}

- (void) setNextPageDelay:(uint32_t)aDelay
{	
	if(aDelay>102400) aDelay = 102400;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNextPageDelay:nextPageDelay];
    
    nextPageDelay = aDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelNextPageDelayChanged object:self];
	
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5PulserDelayChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5PulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kEWSltV4NumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (uint32_t) getAddress: (short) anIndex
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
	 postNotificationName:ORAmptekDP5SelectedRegIndexChanged
	 object:self];
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAmptekDP5WriteValueChanged
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelDisplayEventLoopChanged object:self];
	
}

- (uint32_t) pageSize
{
	return pageSize;
}

- (void) setPageSize: (uint32_t) aPageSize
{
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
	
    if (aPageSize > 100) pageSize = 100;
	else pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelPageSizeChanged object:self];
	
}  







#pragma mark ***UDP Communication

//  UDP K command connection   -------------------------------
//reply socket (server)
- (int) startListeningServerSocket
{



//for Amptek: we use the same socket, so we do not open a new socket -tb-
    if(UDP_COMMAND_CLIENT_SOCKET<=0){
	    //fprintf(stderr, "initGlobalUDPServerSocket: socket(...) created socket %i\n",GLOBAL_UDP_SERVER_SOCKET);
	    NSLog(@" %@::%@  UDP_COMMAND_CLIENT_SOCKET is %i, please open manually (open button).  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,UDP_REPLY_SERVER_SOCKET);//TODO: DEBUG -tb-
    }


	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-

    int retval=0;
#if 0
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
#endif





	[self setIsListeningOnServerSocket: 1];
	//start polling
	if(	[self isListeningOnServerSocket]) [self performSelector:@selector(receiveFromReplyServer) withObject:nil afterDelay: 0];

    return retval;//retval=0: OK, else error
	
	return 0;
}

- (void) stopListeningServerSocket
{



//TODO: remove - do nothing -tb-
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    if(UDP_REPLY_SERVER_SOCKET>-1) close(UDP_REPLY_SERVER_SOCKET);
    UDP_REPLY_SERVER_SOCKET = -1;
	
	[self setIsListeningOnServerSocket: 0];//TODO: rename to "isListening" -tb-2014-08
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

#define DEBUG_SPECTRUM_READOUT 0

- (int) receiveFromReplyServer
{

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromReplyServer) object:nil];

    //DEBUG 	       NSLog(@"Called %@::%@! xxxxx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-

    const int maxSizeOfReadbuffer=MAXDP5PACKETLENGTH *2;//was 4096 * 2; //typically MAXDP5PACKETLENGTH=32775
    unsigned char readBuffer[maxSizeOfReadbuffer];

	ssize_t retval=-1;
    sockaddr_fromLength = sizeof(sockaddr_from);
    //while( (retval = recvfrom(MY_UDP_SERVER_SOCKET, (char*)InBuffer,sizeof(InBuffer) , MSG_DONTWAIT,(struct sockaddr *) &servaddr, &AddrLength)) >0 ){
    //retval = recvfrom(UDP_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &sockaddr_from, &sockaddr_fromLength);
    
    int runLoop=TRUE;
    int loopCounter=0;
    while(runLoop){
        loopCounter++;
        if(loopCounter>10) runLoop=FALSE;//"security stop"
        if(retval==0) usleep(10);
        if(loopCounter%1000 == 0) NSLog(@"loopCounter %i \n",loopCounter);
        retval = recvfrom(UDP_COMMAND_CLIENT_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,(struct sockaddr *) &sockaddr_from, &sockaddr_fromLength);
	    if(retval>=0){
	        if(DEBUG_SPECTRUM_READOUT) printf("recvfromGlobalServer retval:  %ld (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
            //DEBUG 	    NSLog(@"loopCounter %i \n",loopCounter);
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        if(DEBUG_SPECTRUM_READOUT) NSLog(@" %@::%@ Got UDP data from UDP_COMMAND_CLIENT_SOCKET  !  numBytes: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) , retval);//TODO: DEBUG -tb-
            //is it the first response packet?
            if(countReceivedPackets==0 && retval>=6){
                if(readBuffer[0]==0xf5 && readBuffer[1]==0xfa){
                    uint16_t packetLenFromHeader=0;
                    uint16_t dataLenFromHeader=0;
                    uint16_t *readBuf16 = (uint16_t *)(&(readBuffer[4]));
                    dataLenFromHeader = ntohs(*readBuf16);//on Intel machines, we need to swap ... -tb-
                    packetLenFromHeader = dataLenFromHeader + 8;
                    if(DEBUG_SPECTRUM_READOUT) NSLog(@" %@::%@ DP5DataLen: %i   DP5PacketLen: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,dataLenFromHeader,packetLenFromHeader);
                    expectedDP5PacketLen = packetLenFromHeader;
                    if(expectedDP5PacketLen<retval){//expect more packets
                        waitForResponse = TRUE;
                    }
                }else{//ignore this packet, has bad header
                    waitForResponse = FALSE;
                    expectedDP5PacketLen = 0;//this
                }
            }
            
            #if 0
            //dump/debug !WARNING! SLOWS DOWN READOUT CONSIDERABLY (factor 1000 or so for MCA ...) -tb-
            int k;
            unsigned int val;
            for(k=0;k<retval;k++){
                val=readBuffer[k] & 0x000000ff;
                NSLog(@"%i: 0x%02x (%u)\n",k,val,val);
            }
            #endif
            
            //sum up packets if necessary, check received length
            memcpy(&(dp5Packet[currentDP5PacketLen]),readBuffer,retval);
            currentDP5PacketLen += retval;
            countReceivedPackets++;
            if(DEBUG_SPECTRUM_READOUT) NSLog(@" %@::%@ currentDP5PacketLen: %i   expectedDP5PacketLen: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,currentDP5PacketLen,expectedDP5PacketLen);
            if(currentDP5PacketLen >= expectedDP5PacketLen){
                if(DEBUG_SPECTRUM_READOUT) NSLog(@" %@::%@ RECEIVED FULL RESPONSE!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );
                [self parseReceivedDP5Packet];
                currentDP5PacketLen  = 0;
                countReceivedPackets = 0;
                expectedDP5PacketLen = 0;
                waitForResponse = FALSE;
            }
	        //if(	waitForResponse) [self  receiveFromReplyServer ];
            
	    }
        
        if(	!waitForResponse) runLoop=FALSE;
        //if(retval==0) usleep(10);
        //usleep(10);
    }
    
    double delayTime=0.0;
    
                //TODO: improve timing!!!! -tb-
                //NSLog(@" %@::%@ waitForResponse: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),waitForResponse );
                //waitForResponse is at this point always 0 except another command was already sent -tb-
    if(!waitForResponse) delayTime = 0.1; //TODO: could even be 1.0 or larger ... -tb-
	if(	[self isListeningOnServerSocket]) [self performSelector:@selector(receiveFromReplyServer) withObject:nil afterDelay: delayTime];
    
    return (int)retval;
    
    
        #if 0
    retval = recvfrom(UDP_REPLY_SERVER_SOCKET, readBuffer, maxSizeOfReadbuffer, MSG_DONTWAIT,NULL,NULL);
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING
//TODO: DEBUGGING

	    //printf("recvfromGlobalServer retval:  %i, maxSize %i\n",retval,maxSizeOfReadbuffer);
	    if(retval>=0){
	        //printf("recvfromGlobalServer retval:  %i (bytes), maxSize %i, from IP %s\n",retval,maxSizeOfReadbuffer,inet_ntoa(sockaddr_from.sin_addr));
			//printf("Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
			//NSLog(@"Got UDP data from %s\n", inet_ntoa(sockaddr_from.sin_addr));
	        NSLog(@" %@::%@ Got UDP data from %s!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,inet_ntoa(sockaddr_from.sin_addr));//TODO: DEBUG -tb-

	    }
        
        #endif
        
        
    
    
#if 0
        retval=0; //stops parsing reply
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
#endif
}

- (int) parseReceivedDP5Packet
{
	//DEBUG     NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    
    if(lastRequest){
         if(DEBUG_SPECTRUM_READOUT) NSLog(@"       %@::%@!  lastRequest>0! Clear it!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
        [self setLastRequest:nil];
    }
    
    //check length
    if(currentDP5PacketLen<8){
        NSLog(@"   ERROR: packet too small (<8 bytes) - NOT a valid DP5 packet!\n");
        return -1;
    }
    
    //check header
    if(dp5Packet[0]==0xf5 && dp5Packet[1]==0xfa){
        if(DEBUG_SPECTRUM_READOUT) NSLog(@"   MESSAGE: Header starts with 0xf5fa - OK\n");
        //TODO: packet counter in display?
    }else{
        NSLog(@"   ERROR: Header starts NOT with 0xf5fa - NOT a valid DP5 packet!\n");
        //TODO: handle header error
    }
    
    //read length
                uint16_t packetLenFromHeader=0;
                uint16_t dataLenFromHeader=0;
                uint16_t *readBuf16 = (uint16_t *)(&(dp5Packet[4]));
                dataLenFromHeader = ntohs(*readBuf16);//on Intel machines, we need to swap ... -tb-
                packetLenFromHeader = dataLenFromHeader + 8;
                if(DEBUG_SPECTRUM_READOUT) NSLog(@"   %@::%@ DP5DataLen: %i   DP5PacketLen: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,dataLenFromHeader,packetLenFromHeader);
                
    //check checksum  
    int i;
    uint16_t sum=0;
    for(i=packetLenFromHeader-3; i>=0; i--) sum += dp5Packet[i];          
    uint16_t checkSum2er =   ~(sum) +1;//((chkmsb & 0xff)<<8) | (chklsb & 0xff);

    if(DEBUG_SPECTRUM_READOUT) NSLog(@"   MESSAGE: checksum: %u (0x%08x),  2-complement:  %u (0x%08x)\n",sum,sum,checkSum2er,checkSum2er);
    uint32_t chkmsb = dp5Packet[packetLenFromHeader-2]   & 0x000000ff;
    uint32_t chklsb = dp5Packet[packetLenFromHeader-1]   & 0x000000ff;
    if(DEBUG_SPECTRUM_READOUT)NSLog(@"   MESSAGE: checksum bytes in header: MSB (0x%08x)  LSB (0x%08x)\n",chkmsb,chklsb);
    uint16_t checkSum2erFromHeader =  ((chkmsb & 0xff)<<8) | (chklsb & 0xff);
    
    if(checkSum2er==checkSum2erFromHeader){
        if(DEBUG_SPECTRUM_READOUT) NSLog(@"   MESSAGE: checksum - OK\n");
    }else{
        NSLog(@"   ERROR: computed checksum and checksum from packet differ - NOT a valid DP5 packet!\n");
        //TODO: handle checksum error
    }


    //parse contents
    uint8_t PID1 = dp5Packet[2];
    uint8_t PID2 = dp5Packet[3];
    uint16_t length = dataLenFromHeader;
    
    //check acknowledge commands
    if(DEBUG_SPECTRUM_READOUT)
    if(PID1==0xff){
        if(PID2==0){
            NSLog(@"   MESSAGE: this was a ACKNOWLEDGE packet: OK\n");
        }else{
            NSLog(@"   ERROR: this was a ACKNOWLEDGE packet: error code %u (0x%x)\n",PID2,PID2);
            //TODO: handle  error
        }
    }
    
    //check response packets (see page 55 of the "DP5 Programmer Guide" Rev A6)
    if(PID1==0x82){
        if(PID2==7){
            NSLog(@"   MESSAGE: this is a configuration readback packet\n");
            dp5Packet[length+6]=0;
            NSLog(@"   readback is: %s\n",&(dp5Packet[6]));
            [self parseReadbackCommandTableResponse:length];
            return 1;//OK
        }
    }
    
    
    
    //check status packets and spectrum (+optional status) packets
    int specLength=0;
    int hasStatus=0;
    int statusOffset=0;
    //check status packet
    if(PID1==0x80){
        hasStatus=1;
        statusOffset=6;
    }
    //check spectrum (+status) packets (see page 59 of the "DP5 Programmer Guide" Rev A6)
    if(PID1==0x81){
        switch(PID2){
        case 0x1:
        case 0x2: specLength =  256; break;
        case 0x3:
        case 0x4: specLength =  512; break;
        case 0x5:
        case 0x6: specLength = 1024; break;
        case 0x7:
        case 0x8: specLength = 2048; break;
        case 0x9:
        case 0xa: specLength = 4096; break;
        case 0xb:
        case 0xc: specLength = 8192; break;
        default: specLength = -1;
        }
        if((PID2 %2) ==0){
            hasStatus = 1;
            statusOffset = 6 + specLength *3;
            if(DEBUG_SPECTRUM_READOUT) NSLog(@"   MESSAGE: this is a spectrum+status packet, spectrum length is: %i     statusOffset: %i\n",specLength,statusOffset);
            //dp5Packet[length+6]=0;
            //NSLog(@"   readback is: %s\n",&(dp5Packet[6]));
        }else{
            hasStatus = 0;
            statusOffset = 0;
            if(DEBUG_SPECTRUM_READOUT) NSLog(@"   MESSAGE: this is a pure spectrum packet, spectrum length is: %i\n",specLength);
        }
        
        //show status
        if(DEBUG_SPECTRUM_READOUT) 
        if(hasStatus){
            uint32_t var32=0;
            uint16_t var16=0; var16=0;
            uint8_t var8=0;
            NSLog(@"STATUS:    (statusOffset: %i)\n",statusOffset);
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kFastCountOffset])) );
            NSLog(@"    kFastCountOffset: %i (0x%08x)\n",var32,var32);
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kSlowCountOffset])) );
            NSLog(@"    kSlowCountOffset: %i (0x%08x)\n",var32,var32);
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset +  kGPCounterOffset])) );
            NSLog(@"    kGPCounterOffset: %i (0x%08x)\n",var32,var32);
            
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kAccTimeOffset])) );
            //NSLog(@"    kAccTimeOffset: %i (0x%08x)\n",var32,var32);
            NSLog(@"    kAccTimeOffset: %i x 100 mS  + %i mS (0x%08x)\n",/*dp5Packet[statusOffset + kAccTimeOffset],*/ var32>>8,var32 & 0xff,var32);
            
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kRealtimeOffset])) );
            NSLog(@"    kRealtimeOffset: %i  x 1 mS (0x%08x)\n",var32,var32);
            
            var8 = dp5Packet[statusOffset + kFirmwareVersionOffset] ;
            NSLog(@"    kFirmwareVersionOffset: %i.%i  \n",(var8 >>4),var8 & 0x0f);
            
            var8 = dp5Packet[statusOffset + kFPGAVersionOffset] ;
            NSLog(@"    kFPGAVersionOffset: %i.%i  \n",(var8 >>4),var8 & 0x0f);
            
        }
        
        //update status display
        if(hasStatus){
            uint32_t var32=0;
            uint16_t var16=0; var16=0;
            uint8_t var8=0;
            int8_t var8signed=0;
            //NSLog(@"STATUS:    (statusOffset: %i)\n",statusOffset);
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kFastCountOffset])) );
            [self setFastCounter: var32];
            //NSLog(@"    kFastCountOffset: %i (0x%08x)\n",var32,var32);
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kSlowCountOffset])) );
            [self setSlowCounter: var32];
            //NSLog(@"    kSlowCountOffset: %i (0x%08x)\n",var32,var32);
            
            var8 =*( (uint8_t*) (&(dp5Packet[statusOffset + kAccTimeOffset])) );
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kAccTimeOffset])) );
            //NSLog(@"    kAccTimeOffset: %i (0x%08x)\n",var32,var32);
            //NSLog(@"    kAccTimeOffset: %i x 100 mS  + %i mS (0x%08x)\n",/*dp5Packet[statusOffset + kAccTimeOffset],*/ var32>>8,var32 & 0xff,var32);
            var32 >>= 8;
            [self setAcquisitionTime: var32 * 100 + var8];
            
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kRealtimeOffset])) );
            [self setRealTime: var32];
            //NSLog(@"    kRealtimeOffset: %i  x 1 mS (0x%08x)\n",var32,var32);
            
            var8signed =*( (int8_t*) (&(dp5Packet[statusOffset + kBoardTemperature])) );
            [self setBoardTemperature: var8signed];
            //if(DEBUG_SPECTRUM_READOUT) 
            //NSLog(@"    kRealtimeOffset: %i  degree celsius  (0x%08x)\n",var8signed,var8signed);
            
            var8signed =*( (int8_t*) (&(dp5Packet[statusOffset + kDeviceIDOffset])) );
            [self setDeviceId: var8signed];
            //if(DEBUG_SPECTRUM_READOUT) 
            //NSLog(@"    kDeviceIDOffset: %i     (0x%08x)\n",var8signed,var8signed);
            
            var8signed =*( (int8_t*) (&(dp5Packet[statusOffset + kDetectorTemperatureMSB])) );
            var32 = var8signed << 8;
            var8signed =*( (int8_t*) (&(dp5Packet[statusOffset + kDetectorTemperatureLSB])) );
            var32 |= var8signed ;
            [self setDetectorTemperature: var32];
            //NSLog(@"    detector temp (K): %i x 0.1  Kelvin (0x%08x)\n",var32,var32);

            var8 = dp5Packet[statusOffset + kFirmwareVersionOffset] ;
            var32 = var8 << 8;
            //NSLog(@"    kFirmwareVersionOffset: %i.%i  \n",(var8 >>4),var8 & 0x0f);
            var8 = dp5Packet[statusOffset + kFPGAVersionOffset] ;
            var32 |= var8 ;
            //NSLog(@"    kFPGAVersionOffset: %i.%i  \n",(var8 >>4),var8 & 0x0f);
            //NSLog(@"    firmware+fpga version: %i   (0x%08x)\n",var32,var32);
            [self setFirmwareFPGAVersion: var32];
            
            
            var32=*( (uint32_t*) (&(dp5Packet[statusOffset + kSerialNumberOffset])) );
            [self setSerialNumber: var32];
            //NSLog(@"    kSerialNumberOffset: %i (0x%08x)\n",var32,var32);
        }
        
        
        //ship the packet 
        uint32_t data[8400];
        uint32_t location = (uint32_t)[self uniqueIdNumber];
        uint32_t infoFlags = 0;
        uint32_t acqtime = 0;
        uint32_t realtime = 0;
        if(hasStatus){
            infoFlags = infoFlags | 0x1;
            acqtime = *( (uint32_t*) (&(dp5Packet[statusOffset + kAccTimeOffset])) );
            realtime = *( (uint32_t*) (&(dp5Packet[statusOffset + kRealtimeOffset])) );
        }
        
        int lengthBytes = 8*4 + currentDP5PacketLen; // 8 words header * 4 byte (each is uint32_t) + packet ...
        if(lengthBytes%4)     NSLog(@"ERROR in %@::%@!  lengthBytes %i not multiple of 4! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) ,lengthBytes);//TODO: DEBUG -tb-

        int length32 = lengthBytes/4;
        if(!needToDropFirstSpectrum){
			//time_t	ut_time;
			//time(&ut_time);
            struct timeval t;//    struct timezone tz; is obsolete ... -tb-
            //timing
            gettimeofday(&t,NULL);
        
			data[0] = (uint32_t)spectrumEventId | (length32);
			data[1] = location;    //called "deviceID" in the ROOT file
            //data[2] = ut_time;	   //sec
            data[2] = (uint32_t)t.tv_sec;	   //sec
			data[3] = (uint32_t)t.tv_usec;   //subsec
			data[4] = specLength;  //spectrum length
			data[5] = hasStatus;   //additional info
			data[6] = acqtime;	
			data[7] = realtime;	
            
            void *destination = (void*) &(data[8]);
            memcpy(destination, dp5Packet, currentDP5PacketLen);
            
			//[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
			//													object:[NSData dataWithBytes:data length:lengthBytes]];
            NSData* pdata = [[NSData alloc] initWithBytes:data length:lengthBytes];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
            [pdata release];
            pdata = nil;
            
        }else{
            needToDropFirstSpectrum = FALSE; //dropped one
        }


    }
    

                
    return 0;
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
  
	
    
    
    
    //TODO: FIXIT for Amptek, we do not need a listening socket, see comment in startListeningServerSocket -tb-
    //[self setIsListeningOnServerSocket: 1];//TODO: rename -tb-
    [self startListeningServerSocket];//TODO: rename -tb-
	
	return retval;
}

- (void) closeCommandSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
      if(UDP_COMMAND_CLIENT_SOCKET>-1) close(UDP_COMMAND_CLIENT_SOCKET);
      UDP_COMMAND_CLIENT_SOCKET = -1;
      
    [self stopListeningServerSocket];
	//[self setIsListeningOnServerSocket: 0];//TODO: rename to "isListening" -tb-2014-08
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveFromReplyServer) object:nil];

}

- (int) isOpenCommandSocket
{
	if(UDP_COMMAND_CLIENT_SOCKET>0) return 1; else return 0;
}






- (int) requestSpectrum
{
    return [self requestSpectrumOfType: spectrumRequestType];
}



//TODO: use command queue !!! -tb-
//TODO: use command queue !!! -tb-
//TODO: use command queue !!! -tb-
//TODO: use command queue !!! -tb-
//TODO: use command queue !!! -tb-
- (int) requestSpectrumOfType:(int)pid2
{
    switch(pid2){
    case 1: return [self sendUDPCommandString: @"0xf5fa02010000fe0e"]; break;
    case 2: return [self sendUDPCommandString: @"0xf5fa02020000fe0d"]; break;
    case 3: return [self sendUDPCommandString: @"0xf5fa02030000fe0c"]; break;
    case 4: return [self sendUDPCommandString: @"0xf5fa02040000fe0b"]; break;
    default:
	    NSLog(@"ERROR %@::%@ - request type not valid: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),pid2);//TODO: DEBUG -tb-
    }
    return -1;
}

- (int) sendTextCommand
{
    return [self shipSendTextCommandString: textCommand];
}

- (int) shipSendTextCommandString:(NSString*)cmd
{
    if(useCommandQueue){
        [self queueStringCommand: [NSString stringWithFormat:@"+wa:%@", cmd]];
    }else{
        return [self sendTextCommandString: cmd];
    }
    
    return 0;
}



//send a write ASCII command to Amptek DP5 -tb-
- (int) sendTextCommandString:(NSString*)cmd;
{
	//DEBUG    NSLog(@"Called %@::%@!  text command is: >%@< length %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),cmd,[cmd length]);//TODO: DEBUG -tb-

    if([cmd length]>512){
        NSLog(@"    ERROR: AmptekDP5: text command to int32_t! Contact a ORCA developer!\n");
        return 0;
    }


    uint16_t len=[cmd length];
    unsigned char buffer[520*2];
    
    buffer[0] =  0xf5;
    buffer[1] =  0xfa;
    buffer[2] =  0x20;
    buffer[3] =  0x02;
    buffer[4] =  (len >> 8);//length MSB
    buffer[5] =  (len & 0xff);//length LSB
    
    int i;
     
    for(i=0; i<len; i++){
        buffer[6+i] = [cmd characterAtIndex:i] & 0xff; //characterAtIndex: returns unichar = 16 bit
    }
    
    
    //DEBUGGING: set to 1 -tb-
    //DEBUGGING: ---->
    #if 0
    {
                //dump/debug !WARNING! SLOWS DOWN READOUT CONSIDERABLY  -tb-
            int k;
            unsigned int val;
            for(k=0;k<len+6;k++){
                val=buffer[k] & 0x000000ff;
                NSLog(@"%i: 0x%02x (%u)\n",k,val,val);
            }
    }
    #endif


    //checksum
    //int i;
    uint16_t sum=0;
    for(i=len+5; i>=0; i--) sum += buffer[i];          
    uint16_t checkSum2er =   ~(sum) +1;//((chkmsb & 0xff)<<8) | (chklsb & 0xff);

    buffer[len+6] =  checkSum2er >> 8;
    buffer[len+7] =  checkSum2er & 0xff;


    //send it
    int retval = [self sendUDPPacket:buffer length:len+8];



        //we *always* expect a response from the DP5 -tb-
        waitForResponse = TRUE;    //TODO: this should be handled from "receiveFromReplyServer" -tb-
        currentDP5PacketLen = 0;   //TODO: this should be handled from "receiveFromReplyServer" -tb-
        expectedDP5PacketLen = 0;  //TODO: this should be handled from "receiveFromReplyServer" -tb-
        countReceivedPackets = 0;  //TODO: this should be handled from "receiveFromReplyServer" -tb-




    return retval;
    //return [self sendUDPCommandString: crateUDPCommand];
}


//----------
- (int) readbackTextCommand
{
    //return [self readbackTextCommandString: textCommand];
    return [self shipReadbackTextCommandString: textCommand];
}

- (int) shipReadbackTextCommandString:(NSString*)cmd
{
    if(useCommandQueue){
        [self queueStringCommand: [NSString stringWithFormat:@"+ra:%@", cmd]];
    }else{
        return [self readbackTextCommandString: cmd];
    }
    
    return 0;
}


//send a read back ASCII command to Amptek DP5 -tb-
- (int) readbackTextCommandString:(NSString*)cmd;
{
	NSLog(@"Called %@::%@!  text command is: >%@< length is: %i (max. 512)\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),cmd,[cmd length]);//TODO: DEBUG -tb-

    if([cmd length]>512){
        NSLog(@"    ERROR: text command to int32_t!\n");
        return 0;
    }


    uint16_t len=[cmd length];
    unsigned char buffer[520*2];
    
    buffer[0] =  0xf5;
    buffer[1] =  0xfa;
    buffer[2] =  0x20;
    buffer[3] =  0x03;
    buffer[4] =  (len >> 8);//length MSB
    buffer[5] =  (len & 0xff);//length LSB
    
    int i;
     
      //TODO: should be improved - use cStringUsingEncoding:
    for(i=0; i<len; i++){
        buffer[6+i] = [cmd characterAtIndex:i] & 0xff; //characterAtIndex: returns unichar = 16 bit
    }
    
    
    #if 1
    {
                //dump/debug !WARNING! SLOWS DOWN READOUT CONSIDERABLY  -tb-
            int k;
            unsigned int val;
            for(k=0;k<len+6;k++){
                val=buffer[k] & 0x000000ff;
                NSLog(@"%i: 0x%02x (%u)\n",k,val,val);
            }
    }
    #endif


    //checksum
    //int i;
    uint16_t sum=0;
    for(i=len+5; i>=0; i--) sum += buffer[i];          
    uint16_t checkSum2er =   ~(sum) +1;//((chkmsb & 0xff)<<8) | (chklsb & 0xff);

    buffer[len+6] =  checkSum2er >> 8;
    buffer[len+7] =  checkSum2er & 0xff;


    //send it
    int retval = [self sendUDPPacket:buffer length:len+8];

    return retval;
    //return [self sendUDPCommandString: crateUDPCommand];
}


- (int) readbackCommandTableAsTextCommand
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-


    int num = (int)[commandTable count];
    //DEBUG    
        NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
    NSMutableString *stringCommand = [[[NSMutableString alloc] initWithCapacity:100]autorelease];
    int i; //row index
    for(i=0; i<num; i++){
        [stringCommand appendString:[[commandTable objectAtIndex:i] objectForKey:@"Name"] ];
        [stringCommand appendString:@"=???;"];
    }
    NSLog(@"stringCommand is:>%@<\n",stringCommand);
    
    //[self readbackTextCommandString: stringCommand];
    [self shipReadbackTextCommandString: stringCommand];
    //if([self commandQueueCount]>0)[self processOneCommandFromQueue];
    
    return num;
}


- (int) parseReadbackCommandTableResponse:(int)length
{
    //DEBUG    
        NSLog(@"Called %@::%@ length:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),length);//TODO: DEBUG -tb-
    int num=0;
    
    dp5Packet[length+6]=0;
    NSString *responseString = [NSString stringWithUTF8String: (char*) &(dp5Packet[6]) ];//0-terminated char string
    
    NSArray *commands = [responseString componentsSeparatedByString: @";"];
    num = (int)[commands count];
    //DEBUG
        NSLog(@"Called %@::%@  response is:%@\n  commands:%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),responseString,commands);//TODO: DEBUG -tb-
    
    int i;
    for(i=0; i<num; i++){
        if([[commands objectAtIndex:i] length] > 0){
            NSLog(@"Called %@::%@  command %i is %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),i,[commands objectAtIndex:i]);//TODO: DEBUG -tb-
            NSArray *command = [[commands objectAtIndex:i] componentsSeparatedByString: @"="];
            NSLog(@"Called %@::%@  command %@ has value %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[command objectAtIndex:0],[command objectAtIndex:1]);//TODO: DEBUG -tb-
            [self setCommandTableItem:[command objectAtIndex:0] setObject:[command objectAtIndex:1] forKey:@"Value"];
        }
    }
    
    if(num>0) [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelCommandTableChanged object:self];

    return num;
}




- (int) writeCommandTableSettingsAsTextCommand
{
    //DEBUG    
        NSLog(@"%@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-


    int num = (int)[commandTable count];
    //DEBUG    
        NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
    NSMutableString *stringCommand = [[[NSMutableString alloc] initWithCapacity:100]autorelease];
    int i; //row index
    for(i=0; i<num; i++){
        [stringCommand appendString:[[commandTable objectAtIndex:i] objectForKey:@"Name"] ];
        [stringCommand appendString:@"="];
        [stringCommand appendString:[[commandTable objectAtIndex:i] objectForKey:@"Setpoint"]];
        [stringCommand appendString:@";"];
    }
    NSLog(@"stringCommand is:>%@<\n",stringCommand);
    
    //[self sendTextCommandString: stringCommand];
    [self shipSendTextCommandString: stringCommand];
    //if([self commandQueueCount]>0)[self processOneCommandFromQueue];
    
    return num;
}


- (int) writeCommandTableInitSettingsAsTextCommand
{
    //DEBUG            NSLog(@"%@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-


    int num = (int)[commandTable count], count=0;
    //DEBUG            NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
    NSMutableString *stringCommand = [[[NSMutableString alloc] initWithCapacity:100]autorelease];
    int i; //row index
    for(i=0; i<num; i++){
        if([[[commandTable objectAtIndex:i] objectForKey:@"Init"] boolValue]){
            count++;
            [stringCommand appendString:[[commandTable objectAtIndex:i] objectForKey:@"Name"] ];
            [stringCommand appendString:@"="];
            [stringCommand appendString:[[commandTable objectAtIndex:i] objectForKey:@"Setpoint"]];
            [stringCommand appendString:@";"];
        }
    }
    //DEBUG     NSLog(@"stringCommand is:>%@<\n",stringCommand);
    
    if(count>0)
        [self sendTextCommandString: stringCommand];
    //[self shipSendTextCommandString: stringCommand];
    //if([self commandQueueCount]>0)[self processOneCommandFromQueue];
    
    return num;
}



- (int) readbackCommandOfRow:(int)row
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-


    int num = (int)[commandTable count];
    //DEBUG    
        NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
    NSMutableString *stringCommand = [[[NSMutableString alloc] initWithCapacity:100]autorelease];
        [stringCommand appendString:[[commandTable objectAtIndex:row] objectForKey:@"Name"] ];
        [stringCommand appendString:@"=???;"];

    NSLog(@"stringCommand is:>%@<\n",stringCommand);
    
    //[self readbackTextCommandString: stringCommand];
    [self shipReadbackTextCommandString: stringCommand];
    //if([self commandQueueCount]>0)[self processOneCommandFromQueue];
    
    return num;
}


- (int) writeCommandOfRow:(int)row
{
    //DEBUG    
        NSLog(@"%@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-


    int num = (int)[commandTable count];
    //DEBUG    
        NSLog(@"Called %@::%@ items in list: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),num);//TODO: DEBUG -tb-
        
    NSMutableString *stringCommand = [[[NSMutableString alloc] initWithCapacity:100]autorelease];
        [stringCommand appendString:[[commandTable objectAtIndex:row] objectForKey:@"Name"] ];
        [stringCommand appendString:@"="];
        [stringCommand appendString:[[commandTable objectAtIndex:row] objectForKey:@"Setpoint"]];
        [stringCommand appendString:@";"];

    NSLog(@"stringCommand is:>%@<\n",stringCommand);
    
    //[self sendTextCommandString: stringCommand];
    [self shipSendTextCommandString: stringCommand];
    //if([self commandQueueCount]>0)[self processOneCommandFromQueue];
    
    return num;
}




//-----





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
	//NSLog(@"Called %@::%@! Send string: >%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  aString);//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}

    if([aString length]==0)       return 1;
    
    
    
    // ---------- if starting with "0x..." parse string ...
    if([aString hasPrefix:@"0x"]){
        [self sendBinaryString:aString];
        //we *always* expect a response from the DP5 -tb-
        waitForResponse = TRUE;    //TODO: this should be handled from "receiveFromReplyServer" -tb-
        currentDP5PacketLen = 0;   //TODO: this should be handled from "receiveFromReplyServer" -tb-
        expectedDP5PacketLen = 0;  //TODO: this should be handled from "receiveFromReplyServer" -tb-
        countReceivedPackets = 0;  //TODO: this should be handled from "receiveFromReplyServer" -tb-
        return 0;
    }




    // ---------- ... else send string as converted to ASCII values
    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	ssize_t retval=0;
	
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
    return (int)retval;

}


//send to Amptek DP5
- (int) sendUDPPacket:(unsigned char*)packet length:(int) aLength
{
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)

	//DEBUGGING --->  NSLog(@"Called %@::%@! length: >%i<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  aLength);//TODO: DEBUG -tb-

    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}
    if(aLength==0)       return 1;
    
    
    const void *buffer   = (const void *)packet; 
	size_t length        = aLength;
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	ssize_t retval=0;
	
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
    return (int)retval;

}





- (int) sendBinaryString:(NSString*)aString
{
    //DEBUG     	NSLog(@"Called %@::%@! Send string: >%@< (length %i)\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),  aString,[aString length]);//TODO: DEBUG -tb-

    if(![aString hasPrefix:@"0x"]){
        NSLog(@"   not a binary command!\n");
        return 1;
    }
    
    char buffer[10];
    buffer[0] =  '0';
    buffer[1] =  'x';
    buffer[2] =  0;
    buffer[3] =  0;
    buffer[4] =  0;
    buffer[5] =  0;
    char binaryCommand[4096*2];
    int lenCmd = (int)[aString length]/2 -1;//drop '0x'

	const char* cstring = [aString cStringUsingEncoding:NSASCIIStringEncoding];


    int i;
    for(i=0;i<lenCmd; i++){
        buffer[2] =  cstring[(i+1)*2];
        buffer[3] =  cstring[(i+1)*2+1];
        int val =   (int)strtol(buffer, NULL, 0);
        binaryCommand[i] = val;

        //NSLog(@"   byte %i is: %s = %i\n",i,buffer,val);
    }
    
    
    
    
    
    
    	size_t length        = lenCmd;
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	ssize_t retval=0;
	
  //	if(port==0) port = GLOBAL_UDP_CLIENT_PORT;//use default port
	
  memset((char *) &UDP_COMMAND_sockaddrin_to, 0, sizeof(UDP_COMMAND_sockaddrin_to));
  UDP_COMMAND_sockaddrin_to.sin_family = AF_INET;
  UDP_COMMAND_sockaddrin_to.sin_port = htons(crateUDPCommandPort);
  if (inet_aton(receiverIPAddr, &UDP_COMMAND_sockaddrin_to.sin_addr)==0) {
	NSLog(@" %@::%@  inet_aton() failed \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
    //fprintf(stderr, "ERROR: sendtoGlobalClient3: inet_aton() failed\n");
	return 2;
    //exit(1);
  }
    fprintf(stderr, "    sendtoGlobalClient4: UDP Client: IP: %s, port: %i\n",receiverIPAddr,crateUDPCommandPort);
    //TODO: only recommended when using a char buffer ...  ((char*)buffer)[length]=0;    fprintf(stderr, "    sendtoGlobalClient3: %s\n",buffer); //DEBUG
	
	retval = sendto(UDP_COMMAND_CLIENT_SOCKET, binaryCommand, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
    return (int)retval;

    
    
    
    
    
    
    //
    return 0;
}





- (int) sendUDPCommandBinary//test -tb-
#if 0
{
    return [self sendUDPCommandString: crateUDPCommand];
}
#else
{
    //taken from ipe4reader6.cpp, function int sendtoGlobalClient3(const void *buffer, size_t length, char* receiverIPAddr, uint32_t port)
	NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
    if(UDP_COMMAND_CLIENT_SOCKET<=0){ NSLog(@"   socket not open\n"); return 1;}

   int sendlen=0;
   unsigned char sendline[10000];
    //request status packet: 0xf5 0xfa 1 1 0 0 0xfe 0x0f (oder 0xf5fa01010000fe0f)
      sendline[0]=0xf5;
      sendline[1]=0xfa;
      sendline[2]=1;
      sendline[3]=1;
      sendline[4]=0 ;
      sendline[5]=0 ;
      sendline[6]=0xfe;
      sendline[7]=0x0f;
      sendlen=8;

      #if 0
      sendline[0]=0xf5;
      sendline[1]=0xfa;
      sendline[2]=3;
      sendline[3]=4;
      sendline[4]=0 ;
      sendline[5]=0 ;
      sendline[6]=0xfe;
      sendline[7]=0x0a;
      sendlen=8;
      #endif
      
      #if 0
      sendline[0]=0xf5;
      sendline[1]=0xfa;
      sendline[2]=3;
      sendline[3]=1;
      sendline[4]=0 ;
      sendline[5]=0 ;
      sendline[6]=0xfe;
      sendline[7]=0x0d            ;
      sendlen=8;
      #endif
      

      
	size_t length        = sendlen;


    //const char *buffer   = [crateUDPCommand cStringUsingEncoding: NSASCIIStringEncoding];  //TODO: maybe use NSData and NSString::dataUsingEncoding:allowLossyConversion: ??? -tb-
    //const void *buffer   = [[aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES] bytes]; 
	//size_t length        = [aString lengthOfBytesUsingEncoding: NSASCIIStringEncoding];
	const char* receiverIPAddr = [crateUDPCommandIP cStringUsingEncoding: NSASCIIStringEncoding];;

	ssize_t retval=0;
	
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
	
	//retval = sendto(UDP_COMMAND_CLIENT_SOCKET, buffer, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
	retval = sendto(UDP_COMMAND_CLIENT_SOCKET, sendline, length, 0 /*flags*/, (struct sockaddr *)&UDP_COMMAND_sockaddrin_to, sockaddrin_to_len);
    return (int)retval;

}

#endif








//  UDP data packet connection ---------------------

//TODO: rm

#if 0
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
#endif












//TODO: rm
#if 0


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


////UNUSED
////UNUSED

////UNUSED
////UNUSED

////UNUSED
////UNUSED


//TODO: changed to pthreads - needs cleanup -tb-
// code moved to void* receiveFromDataReplyServerThreadFunctionXXX (void* p)
 
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
   pthread_create(&dataReplyThread, NULL, receiveFromDataReplyServerThreadFunctionXXX, (void*) &dataReplyThreadData);
     //note: pthread_create is not blocking -tb-

 //NSLog(@"retval: %i, l=%i\n",retval,l); with one fiber we had ca. 12 packets per loop ...
	//if(	[self isListeningOnDataServerSocket]) [self performSelector:@selector(receiveFromDataReplyServer) withObject:nil afterDelay: 0];

#endif

    return retval;
}

#endif








//TODO: remove it ...
#if 0
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
  
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelOpenCloseDataCommandSocketChanged object:self];
	
	return retval;
}



- (void) closeDataCommandSocket
{
	//debug NSLog(@"Called %@::%@!  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG -tb-
	//[model setCrateUDPCommand:[sender stringValue]];	
      if(UDP_DATA_COMMAND_CLIENT_SOCKET>-1) close(UDP_DATA_COMMAND_CLIENT_SOCKET);
      UDP_DATA_COMMAND_CLIENT_SOCKET = -1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmptekDP5ModelOpenCloseDataCommandSocketChanged object:self];
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




//TODO: obsolete, from slt -tb-
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


//TODO: obsolete, from slt -tb-
- (int) sendUDPDataCommandRequestUDPData
{
	return [self sendUDPDataCommandRequestPackets:  numRequestedUDPPackets];	
}

//TODO: obsolete, from slt -tb-
- (int) sendUDPDataCommandChargeBBFile
{
    NSString *cmd = [[NSString alloc] initWithFormat: @"KWC_chargeBBFile_%@", [self chargeBBFile]];
	//debug 
    NSLog(@" %@::%@ send KCommand:%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), cmd);//TODO: DEBUG -tb-
    [cmd autorelease]; //MAH 06/11/13 added autorelease to prevent memory leak
	return [self sendUDPDataCommandString:  cmd];	
}


//TODO: obsolete, from slt -tb-

- (void) loopCommandRequestUDPData
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loopCommandRequestUDPData) object:nil];
    if(	[self isOpenDataCommandSocket]) 
        [self sendUDPDataCommandRequestPackets:  30];
    [self performSelector:@selector(loopCommandRequestUDPData) withObject:nil afterDelay: 10.0];//repeat every 10 seconds
}

//TODO: obsolete, from slt -tb-
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

//TODO: obsolete, from slt -tb-
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
#endif










#pragma mark ***HW Access






#if 0




- (int)           chargeBBWithFile:(char*)data numBytes:(int) numBytes
{
   return 0;
}


- (int)           chargeBBusingSBCinBackgroundWithData:(NSData*)theData forFLT:(OREdelweissFLTModel*) aFLT
{



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

   return 0;
}

- (void) chargeFICStatus:(ORSBCLinkJobStatus*) jobStatus
{
}





#endif











//this uses a general write command
- (int)          writeToCmdFIFO:(char*)data numBytes:(int) numBytes
{
#if 0

    //DEBUG 	    
    NSLog(@"%@::%@ \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


   int32_t buf32[257]; //cannot exceed size of cmd FIFO
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
#endif





   
   return 0;
}



- (void)		  readAllControlSettingsFromHW
{
//DEBUG OUTPUT: 	
NSLog(@"WARNING: %@::%@: under construction! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
//TODO: rm   slt - -     [self readControlReg];
//TODO: rm   slt - -     [self readPixelBusEnableReg];
}

//TODO: rm   slt - - 

- (void) checkPresence
{

#if 0//TODO: remove SLT stuff -tb-   2014 

	@try {
		[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
#endif





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
		uint32_t time[256];
		uint32_t mask[20][256];
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
			ORIpeFLTModel* cards[20];//TODO: ORAmptekDP5Model -tb-
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
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"‚Äö√Ñ¬¢":"-"];
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

- (void) writeReg:(int)index value:(uint32_t)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (void) writeReg:(int)index  forFifo:(int)fifoIndex value:(uint32_t)aValue
{
	[self write: ([self getAddress:index]|(fifoIndex << 14)) value:aValue];
}

- (void)		  rawWriteReg:(uint32_t) address  value:(uint32_t)aValue
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
    [self write: address value: aValue];
}

- (uint32_t) rawReadReg:(uint32_t) address
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
	return [self read: address];

}

- (uint32_t) readReg:(int) index
{
	return [self read: [self getAddress:index]];

}

- (uint32_t) readReg:(int) index forFifo:(int)fifoIndex;
{
	return [ self read: ([self getAddress:index] | (fifoIndex << 14)) ];

}

- (id) writeHardwareRegisterCmd:(uint32_t) regAddress value:(uint32_t) aValue
{
	return [ORPMCReadWriteCommand writeLongBlock:&aValue
									   atAddress:regAddress
									  numToWrite:1];
}

- (id) readHardwareRegisterCmd:(uint32_t) regAddress
{
	return [ORPMCReadWriteCommand readLongBlockAtAddress:regAddress
									  numToRead:1];
}

- (void) readAllStatus
{
	//TODO: rm   slt - -[self readControlReg];
//TODO: rm   slt - - 	[self readStatusReg];
	//[self readReadOutControlReg];
	[self getTime];
//TODO: rm   slt - - 	[self readEventFifoStatusReg];
}


//TODO: rm   slt - -
#if 0
- (uint32_t) readControlReg
{
	uint32_t data = [self readReg:kEWSltV4ControlReg];
    [self setControlReg: data];
	return data;
}


- (void) writeControlReg
{
	[self writeReg:kEWSltV4ControlReg value:controlReg];
}

- (void) printControlReg
{
	uint32_t data = [self readControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register %@ is 0x%08x ----\n",[self fullID],data);
	NSLogFont(aFont,@"OnLine  : 0x%02x\n",(data & kCtrlOnLine) >> 14);
	NSLogFont(aFont,@"LedOff  : 0x%02x\n",(data & kCtrlLedOff) >> 15);
	NSLogFont(aFont,@"Invert  : 0x%02x\n",(data & kCtrlInvert) >> 16);
	NSLogFont(aFont,@"NumFIFOs: 0x%02x\n",(data & kCtrlNumFIFOs) >> 28);
}
#endif







//TODO: rm   slt - - 
#if 0
- (uint32_t) readStatusReg
{
	uint32_t data = [self readReg:kEWSltV4StatusReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kEWSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusReg:data];
	return data;
}

- (uint32_t) readStatusLowReg
{
	uint32_t data = [self readReg:kEWSltV4StatusLowReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kEWSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusLowReg:data];
	return data;
}

- (uint32_t) readStatusHighReg
{
	uint32_t data = [self readReg:kEWSltV4StatusHighReg];
//DEBUG OUTPUT:  	NSLog(@"   %@::%@: kEWSltV4StatusReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),data);//TODO: DEBUG testing ...-tb-
	[self setStatusHighReg:data];
	return data;
}

- (void) printStatusReg
{
	uint32_t data = [self readStatusReg];
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

	uint32_t low = [self readStatusLowReg];
	uint32_t high = [self readStatusHighReg];
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

#endif










//TODO: rm   slt - -
#if 0
- (void) writePixelBusEnableReg
{
	[self writeReg:kEWSltV4PixelBusEnableReg value: [self pixelBusEnableReg]];
}

- (void) readPixelBusEnableReg
{
    uint32_t val;
	val = [self readReg:kEWSltV4PixelBusEnableReg];
	[self setPixelBusEnableReg:val];	
}
#endif









- (int32_t) getSBCCodeVersion
{
	int32_t theVersion = 0;
    
    
    
    
    
    
    #if 0
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSoftwareVersion numToRead:1];
		//implementation is in HW_Readout.cc, void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)  ... -tb-
	}
	[pmcLink setSbcCodeVersion:theVersion];
    
    
    
    
    
    
    #endif
    
	return theVersion;
}

- (int32_t) getFdhwlibVersion
{
	int32_t theVersion = 0;
    
    
    #if 0
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetFdhwLibVersion numToRead:1];
	}
    
    
    
    #endif
	return theVersion;
}

- (int32_t) getSltPciDriverVersion
{
	int32_t theVersion = 0;
    
    
    
    
    #if 0
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSltPciDriverVersion numToRead:1];
	}
    #endif
    
    
    
    
    
	return theVersion;
}

- (int32_t) getPresentFLTsMap
{
	/*uint32_t*/ int32_t theMap = 0;
    
    
    #if 0
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theMap operation:kGetPresentFLTsMap numToRead:1];
	}
    #endif
    
    
    
    
    
    
	return theMap;
}

//TODO: rm   slt - - 
#if 0
- (void) readEventFifoStatusReg
{
	[self setEventFifoStatusReg:[self readReg:kSltV4EventFIFOStatusReg]];
}
#endif

- (uint64_t) readBoardID
{
	uint32_t low = [self readReg:kEWSltV4BoardIDLoReg];
	uint32_t hi  = [self readReg:kEWSltV4BoardIDHiReg];
	BOOL crc =(hi & 0x80000000)==0x80000000;
	if(crc){
		return (uint64_t)(hi & 0xffff)<<32 | low;
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
	uint32_t data = [self readReg:regIndex];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts %@)\n",regIndex==kSltV4InterruptRequestReg?@"Requested":@"Enabled");
	else {
		NSLogFont(aFont,@"The following interrupts are %@:\n",regIndex==kSltV4InterruptRequestReg?@"Requested":@"Enabled");
		NSLogFont(aFont,@"0x%04x\n",data & 0xffff);
	}
}
#endif


- (uint32_t) readHwVersion
{
	uint32_t value;
	@try {
		[self setHwVersion:[self readReg: kEWSltV4RevisionReg]];	
	}
	@catch (NSException* e){
	}
	return value;
}


- (uint32_t) readTimeLow
{
	return [self readReg:kEWSltV4TimeLowReg];
}

- (uint32_t) readTimeHigh
{
	return [self readReg:kEWSltV4TimeHighReg];
}

- (uint64_t) getTime
{
//TODO: rm   slt - - 	uint32_t th = [self readTimeHigh]; 
//TODO: rm   slt - - 	uint32_t tl = [self readTimeLow]; 
	uint32_t th = 1; 
	uint32_t tl = 2; 
	[self setClockTime: (((uint64_t) th) << 32) | tl];
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
 	//NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-

    //new version: write all parameters marked in Command Table
    [self writeCommandTableInitSettingsAsTextCommand];

#if 0 //old version: write manually
    //write "MCA disable"
    [self sendTextCommandString: @"MCAE=OFF;"];

    NSMutableString *argument = [[NSMutableString alloc] init];
    
    //write "number of bins" = MCAC (MCA Channels), p. 110
    [argument setString: [NSString stringWithFormat: @"MCAC=%i;", numSpectrumBins]];
 	NSLog(@"WARNING: %@::%@:  write MCA: >%@< \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),argument);//TODO: DEBUG testing ...-tb-
    [self sendTextCommandString: argument];
    [argument release];
    
    //write "MCA enable"
    [self sendTextCommandString: @"MCAE=ON;"];
#endif
return ;

//TODO: rm   slt - - 	[self writeControlReg];
//TODO: rm   slt - - 	[self writePixelBusEnableReg];
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
	//uint64_t p1 = ((uint64_t)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSltSwRelInhibit value:0];
	//int i = 0;
	//uint32_t lTmp;
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
	uint64_t p2  = ((uint64_t)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSltSwSetInhibit value:0];
 */
//	triggerSource = savedTriggerSource;
	//inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
//TODO: rm   slt - - 	[self printStatusReg];
//TODO: rm   slt - - 	[self printStatusLowHighReg];
//TODO: rm   slt - - 	[self printControlReg];
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
    useCommandQueue=YES;//just for debugging -tb-


	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setDropFirstSpectrum:[decoder decodeBoolForKey:@"dropFirstSpectrum"]];
	[self setAutoReadbackSetpoint:[decoder decodeBoolForKey:@"autoReadbackSetpoint"]];
	[self setSpectrumRequestRate:[decoder decodeIntForKey:@"spectrumRequestRate"]];
	[self setSpectrumRequestType:[decoder decodeIntForKey:@"spectrumRequestType"]];
	[self setNumSpectrumBins:[decoder decodeIntForKey:@"numSpectrumBins"]];
	[self setTextCommand:[decoder decodeObjectForKey:@"textCommand"]];
	[self setResetEventCounterAtRunStart:[decoder decodeIntForKey:@"resetEventCounterAtRunStart"]];
	[self setLowLevelRegInHex:[decoder decodeIntForKey:@"lowLevelRegInHex"]];
	[self setTakeADCChannelData:[decoder decodeIntForKey:@"takeADCChannelData"]];
	[self setTakeRawUDPData:[decoder decodeIntForKey:@"takeRawUDPData"]];
    
//TODO: rm   slt - - 
#if 0
	[self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFile"]];
	[self setUseBroadcastIdBB:[decoder decodeIntegerForKey:@"useBroadcastIdBB"]];
	[self setIdBBforWCommand:[decoder decodeIntegerForKey:@"idBBforWCommand"]];
	[self setTakeEventData:[decoder decodeIntegerForKey:@"takeEventData"]];
	[self setTakeUDPstreamData:[decoder decodeIntegerForKey:@"takeUDPstreamData"]];
	[self setCrateUDPDataCommand:[decoder decodeObjectForKey:@"crateUDPDataCommand"]];
	[self setBBCmdFFMask:[decoder decodeIntegerForKey:@"BBCmdFFMask"]];
	[self setCmdWArg4:[decoder decodeIntegerForKey:@"cmdWArg4"]];
	[self setCmdWArg3:[decoder decodeIntegerForKey:@"cmdWArg3"]];
	[self setCmdWArg2:[decoder decodeIntegerForKey:@"cmdWArg2"]];
	[self setCmdWArg1:[decoder decodeIntegerForKey:@"cmdWArg1"]];
	[self setCrateUDPReplyPort:[decoder decodeIntegerForKey:@"crateUDPReplyPort"]];
	[self setPixelBusEnableReg:[decoder decodeIntegerForKey:@"pixelBusEnableReg"]];
	[self setSelectedFifoIndex:[decoder decodeIntegerForKey:@"selectedFifoIndex"]];
	[self setNumRequestedUDPPackets:[decoder decodeIntegerForKey:@"numRequestedUDPPackets"]];
	[self setCrateUDPDataReplyPort:[decoder decodeIntegerForKey:@"crateUDPDataReplyPort"]];
	[self setCrateUDPDataIP:[decoder decodeObjectForKey:@"crateUDPDataIP"]];
	[self setCrateUDPDataPort:[decoder decodeIntegerForKey:@"crateUDPDataPort"]];
#endif
	[self setSltDAQMode:[decoder decodeIntForKey:@"sltDAQMode"]];
	[self setCrateUDPCommand:[decoder decodeObjectForKey:@"crateUDPCommand"]];
	[self setCrateUDPCommandIP:[decoder decodeObjectForKey:@"crateUDPCommandIP"]];
	[self setCrateUDPCommandPort:[decoder decodeIntForKey:@"crateUDPCommandPort"]];
	[self setSltScriptArguments:[decoder decodeObjectForKey:@"sltScriptArguments"]];



	[self setControlReg:		[decoder decodeIntForKey:@"controlReg"]];
	if([decoder containsValueForKey:@"secondsSetInitWithHost"])
		[self setSecondsSetInitWithHost:[decoder decodeBoolForKey:@"secondsSetInitWithHost"]];
	else[self setSecondsSetInitWithHost: YES];
	

	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"ORAmptekDP5ModelPatternFilePath"]];
//TODO: rm   slt 	[self setInterruptMask:			[decoder decodeIntegerForKey:@"ORAmptekDP5ModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORAmptekDP5ModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORAmptekDP5ModelPulserAmp"]];
		
	//special
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"ORAmptekDP5PageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"ORAmptekDP5DisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"ORAmptekDP5DisplayEventLoop"]];
    	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
    //Amptek commands/settings
    [self setCommandTable:		[decoder decodeObjectForKey:@"CommandTable"]];
    if(!commandTable) [self initCommandTable];
    
    minValue[0]=-128.0; maxValue[0]=128.0; lowLimit[0]=0.0; hiLimit[0]=80.0;
    minValue[1]=0.0;    maxValue[1]=300.0; lowLimit[1]=0.0; hiLimit[1]=280.0;
    { int i; for(i=2; i<10; i++){minValue[i]=-128.0; maxValue[i]=128.0; lowLimit[i]=0.0; hiLimit[i]=80.0;} }
    
	[[self undoManager] enableUndoRegistration];

	[self registerNotificationObservers];
		
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeBool:dropFirstSpectrum forKey:@"dropFirstSpectrum"];
	[encoder encodeBool:autoReadbackSetpoint forKey:@"autoReadbackSetpoint"];
	[encoder encodeInt:spectrumRequestRate forKey:@"spectrumRequestRate"];
	[encoder encodeInt:spectrumRequestType forKey:@"spectrumRequestType"];
	[encoder encodeInt:numSpectrumBins forKey:@"numSpectrumBins"];
	[encoder encodeObject:textCommand forKey:@"textCommand"];
	[encoder encodeInt:resetEventCounterAtRunStart forKey:@"resetEventCounterAtRunStart"];
	[encoder encodeInt:lowLevelRegInHex forKey:@"lowLevelRegInHex"];
	[encoder encodeInt:takeADCChannelData forKey:@"takeADCChannelData"];
	[encoder encodeInt:takeRawUDPData forKey:@"takeRawUDPData"];
	[encoder encodeInteger:takeEventData forKey:@"takeEventData"];
	[encoder encodeInteger:takeUDPstreamData forKey:@"takeUDPstreamData"];
	[encoder encodeInt:sltDAQMode forKey:@"sltDAQMode"];
	[encoder encodeObject:crateUDPCommand forKey:@"crateUDPCommand"];
	[encoder encodeObject:crateUDPCommandIP forKey:@"crateUDPCommandIP"];
	[encoder encodeInt:crateUDPCommandPort forKey:@"crateUDPCommandPort"];
	[encoder encodeBool:secondsSetInitWithHost forKey:@"secondsSetInitWithHost"];
	[encoder encodeObject:sltScriptArguments forKey:@"sltScriptArguments"];
	[encoder encodeInt:controlReg	forKey:@"controlReg"];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"ORAmptekDP5ModelPatternFilePath"];
//TODO: rm   slt 	[encoder encodeInteger:interruptMask	 forKey:@"ORAmptekDP5ModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"ORAmptekDP5ModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"ORAmptekDP5ModelPulserAmp"];
		
    //Amptek commands/settings
	[encoder encodeObject:commandTable  forKey:@"CommandTable"];
    
	//special
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
    
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"ORAmptekDP5PageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"ORAmptekDP5DisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"ORAmptekDP5DisplayEventLoop"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    
     //unused???
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORAmptekDP5DecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"AmptekDP5Event"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORAmptekDP5DecoderForSpectrum",			@"decoder",
				   [NSNumber numberWithLong:spectrumEventId],   @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			    @"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"AmptekDP5Spectrum"];
    
    
    
//TODO: UNUSED    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORAmptekDP5DecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"AmptekDP5Multiplicity"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORAmptekDP5DecoderForWaveForm",			@"decoder",
				   [NSNumber numberWithLong:waveFormId],        @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"AmptekDP5WaveForm"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORAmptekDP5DecoderForFLTEvent",			@"decoder",
				   [NSNumber numberWithLong:fltEventId],        @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"AmptekDP5FLTEvent"];
    
    return dataDictionary;
}

- (uint32_t) spectrumEventId	 { return spectrumEventId; }
- (void) setSpectrumEventId: (uint32_t) aDataId    { spectrumEventId = aDataId; }

- (uint32_t) fltEventId	     { return fltEventId; }
- (void) setFltEventId: (uint32_t) aDataId    { fltEventId = aDataId; }
- (uint32_t) eventDataId        { return eventDataId; }
- (uint32_t) multiplicityId	 { return multiplicityId; }
- (uint32_t) waveFormId	     { return waveFormId; }
- (void) setEventDataId: (uint32_t) aDataId    { eventDataId = aDataId; }
- (void) setMultiplicityId: (uint32_t) aDataId { multiplicityId = aDataId; }
- (void) setWaveFormId: (uint32_t) aDataId { waveFormId = aDataId; }

- (void) setDataIds:(id)assigner
{
    spectrumEventId = [assigner assignDataIds:kLongForm];
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
    fltEventId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setSpectrumEventId:[anotherCard spectrumEventId]];
    [self setEventDataId:[anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
    [self setWaveFormId:[anotherCard waveFormId]];
    [self setFltEventId:[anotherCard fltEventId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    if(objDictionary==nil) objDictionary = dictionary;
    if(objDictionary==nil) objDictionary = [NSMutableDictionary dictionary];

    [objDictionary setObject:[NSNumber numberWithInt:spectrumRequestType]	forKey:@"spectrumRequestType"];
    [objDictionary setObject:[NSNumber numberWithInt:spectrumRequestRate]	forKey:@"spectrumRequestRate"];
    [objDictionary setObject:[NSNumber numberWithInt:crateUDPCommandPort]	forKey:@"UDPPort"];
    [objDictionary setObject:crateUDPCommandIP	forKey:@"UDPIP"];
    
    
    [objDictionary setObject: [self getCommandTableAsString]	forKey:@"SettingsCommandTable"];
    //DEBUG NSLog(@"WARNING: %@::%@: command table is: %@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self getCommandTableAsString]);//TODO: DEBUG testing ...-tb-

	return objDictionary;
}







#pragma mark •••Related to Adc or Bit Processing Protocol
// methods for setting LoAlarm, HiAlarm, LoLimit (=minValue), HiLimit (=maxValue) (from IPESlowControlModel -tb-)
//- (void) setLoAlarmForChan:(int)channel value:(double)aValue;
//- (void) setHiAlarmForChan:(int)channel value:(double)aValue;
//- (void) setLoLimitForChan:(int)channel value:(double)aValue;
//- (void) setHiLimitForChan:(int)channel value:(double)aValue;

#pragma mark •••Adc or Bit Processing Protocol
//note that everything called by these routines MUST be threadsafe
- (void) processIsStarting
{
	//called when processing is started. nothing to do for now. 
	//called at the HW polling rate in the process dialog. 
	//For now we just use the local polling
}

- (void)processIsStopping
{
	//called when processing is stopping. nothing to do for now.
}



- (void) startProcessCycle
{	//called at the HW polling rate in the process dialog. 
	//ignore for now.
}

- (void) endProcessCycle
{  }

/** Note: Adc  Processing supports 30 channels; shipping SC packs channel number into 16 bit (0x00-0xff or 0 ... 255).
  * But there is no limit to the channel number (except it must be a int).
  *
  */ //-tb-
- (BOOL) processValue:(int)channel
{
	return channel==0;// ??? -tb-
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat: @"Amptek-DP5-%u",[self uniqueIdNumber]];
}


- (void) setProcessOutput:(int)channel value:(int)value
{  }  //nothing to do

- (double) convertedValue:(int)channel
{    
    if(channel==0) return [self boardTemperature];
    else return 0.0;
}



- (double) maxValueForChan:(int)channel
{
    if(channel>=0 && channel<10) return maxValue[channel];
    return 128.0;
}

- (double) minValueForChan:(int)channel
{
    if(channel>=0 && channel<10) return minValue[channel];
    return -128.0;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel
{
    if(channel>=0 && channel<10){
		*theLowLimit   =  lowLimit[channel] ;
		*theHighLimit  =  hiLimit [channel] ;
        return;
    }
		*theLowLimit   =   0.0 ;
		*theHighLimit  =  80.0 ;

}

#if 0
//MOVED TO COMMON SCRIPT METHODS -tb-

//very simple method to control ADC value display , NOT persistent (according to Norman this is OK if controllable thru scripts) -tb-
- (double) setMaxValue: (double)val forChan:(int)channel
{
    if(channel>=0 && channel<10){ maxValue[channel]=val; return val;}
    return 0.0;
}

- (double) setMinValue: (double)val forChan:(int)channel
{
    if(channel>=0 && channel<10){ minValue[channel]=val; return val;}
    return 0.0;
}

- (void) setAlarmRangeLow:(double)theLowLimit high:(double)theHighLimit  forChan:(int)channel
{
    if(channel>=0 && channel<10){ lowLimit[channel]=theLowLimit; hiLimit[channel]=theHighLimit; }
}

#endif


#pragma mark •••ID Helpers (see OrcaObject)
- (NSString*) identifier
{
    return [NSString stringWithFormat: @"Amptek-%u",[self uniqueIdNumber]];
}




#pragma mark ‚Ä¢‚Ä¢‚Ä¢Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
//TODO: UNDER construction -tb-
//NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-


    [self clearCommandQueue];

    if(takeEventData || [[userInfo objectForKey:@"doinit"]intValue]){
       accessAllowedToHardwareAndSBC = YES;
    }else{
       accessAllowedToHardwareAndSBC = NO;
    }





//TODO: rm
#if 0
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
#endif    
    
        savedUDPSocketState = [self isOpenCommandSocket] ;
    if(![self isOpenCommandSocket]) [self openCommandSocket];

    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORAmptekDP5Model"];    
    //----------------------------------------------------------------------------------------	
	
	//pollingWasRunning = [poller isRunning];
	//if(pollingWasRunning) [poller stop];
	
	//[self writeSetInhibit];  //TODO: maybe move to readout loop to avoid dead time -tb-
	
    
    //warm or cold start?
    //  for QuickStart: do not access the hardware (at least not registers relevant for SAMBA) -tb-
    if([[userInfo objectForKey:@"doinit"]intValue]){
        [self initBoard];		
        
#if 0
        //event mode
        if(takeEventData){
		    //[self initBoard];		
        }
        //UDP data stream mode
        if(takeUDPstreamData){
            //'re-init' stream loop
            [self sendUDPDataCommandString: @"KWC_stopStreamLoop"];	
            usleep(10000);//need to wait for a recvfrom() cycle ...
            [self sendUDPDataCommandString: @"KWC_startStreamLoop"];	
            usleep(10000);
            [self loopCommandRequestUDPData];
            //[self sendUDPDataCommandRequestPackets:  numRequestedUDPPackets];
            //[self performSelector:@selector(loopCommandRequestUDPData) withObject:nil afterDelay: 10.0];//repeat every 10 seconds
        }
#endif
        
	}	
	
    
#if 0
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
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
    if(accessAllowedToHardwareAndSBC){
	    //load all the data needed for the eCPU to do the HW read-out.
	    //    [self load_HW_Config];
	    ////TODO: remove SLT stuff -tb-   2014 [pmcLink runTaskStarted:aDataPacket userInfo:userInfo];
    }
#endif	

    //
	first = YES;
    needToDropFirstSpectrum = dropFirstSpectrum;//Amptek -tb-
     //NSLog(@"   %@::%@:  needToDropFirstSpectrum %i dropFirstSpectrum %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),needToDropFirstSpectrum,dropFirstSpectrum);//TODO: DEBUG testing ...-tb-

    //readout/poll loop
    if(spectrumRequestRate > 0){
	    //[self performSelector:@selector(requestSpectrumTimedWorker) withObject:nil afterDelay: spectrumRequestRate];
        [self setIsPollingSpectrum:YES];
    }
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{

        //spectrum readout is started in "takeData"!

        // -------TIMER-VARIABLES-----------
        static struct timeval starttime, /*stoptime,*/ currtime;//    struct timezone tz; is obsolete ... -tb-
        //struct timezone	timeZone;
	    static double currDiffTime=0.0, lastDiffTime=0.0, elapsedTime = 0.0;




	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pmc code.
//...        
        
        
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
        elapsedTime = currDiffTime - lastDiffTime;
        
        
        //if takeUDPstreamData is checked, check every 0.5 sec. the UDP buffer ...
        //if(takeUDPstreamData) 
        #if 0
        {
        if(elapsedTime >= 1.5){// ----> x= this value (e.g. 1.0/0.5 ...)
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
                        	uint32_t totalLength = (9 + waveformLength32);	// longs (1 page=1024 shorts [16 bit] are stored in 512 longs [32 bit])
							NSMutableData* theADCTraceData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
							uint32_t header = waveFormId | totalLength;
							
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
            
		    //code to be executed every second -END
		    lastDiffTime = currDiffTime;
		}
        }
        #endif
        
        if(isPollingSpectrum){
            double diffTimeSinceLastRequest =      (  (double)(currtime.tv_sec  - lastRequestTime.tv_sec)  ) +
                    ( ((double)(currtime.tv_usec - lastRequestTime.tv_usec)) * 0.000001 );
            if( diffTimeSinceLastRequest > spectrumRequestRate ){

	 //DEBUG   NSLog(@"=== waitForResponse: %i   expectedDP5PacketLen: %i=========\n", waitForResponse,expectedDP5PacketLen);

                //TODO
                if(waitForResponse){//we are still waiting for a reply of a previous request, do not send a new command ...
			        NSLog(@"================PENDING===================\n");
                    usleep(100000);
                }else{
//DEBUG TIMING --->			        NSLog(@"================START NEW REQUEST===================\n");
                    [self requestSpectrum];
                    gettimeofday(&lastRequestTime,NULL);
                }
            }else{//if we have plenty of time, we may take a small nap
                if( (spectrumRequestRate-diffTimeSinceLastRequest) > 0.5){
                    [self receiveFromReplyServer];//TODO: improve timing!!!!! -tb-
                    usleep(100);
                }
            }
        }


        
	}
	else {// the first time
		    //./ DO SOMETHING
            //DEBUG
        //DEBUGNSLog(@"Called %@::%@: FIRST TIME\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
			//DEBUGNSLog(@"===================================\n");
			//DEBUGNSLog(@"   Datataker Loop: first time: %f (elapsedTime %f)\n",currDiffTime,elapsedTime);
			//DEBUGNSLog(@"===================================\n");
		//TODO: -tb- [self writePageManagerReset];
		//TODO: -tb- [self writeClrCnt];
        
        
        
            //sleep(3);
        
        
        
        
        if(accessAllowedToHardwareAndSBC){

#if 0 //TODO: omit #import "ORAmptekDP5Defs.h"
		    uint64_t runcount = [self getTime];
		    [self shipSltEvent:kRunCounterType withType:kStartRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];

		    [self shipSltSecondCounter: kStartRunType];
#endif



        }
        
		first = NO;
        
        //init timer
        currDiffTime=0.0; lastDiffTime=0.0;
        //start timer -------TIMER------------
        //timing
        //see below ... gettimeofday(&starttime,NULL);
        gettimeofday(&starttime,NULL);
        //start timer -------TIMER------------

        //if(isPollingSpectrum){
            lastRequestTime = starttime;
            [self setIsPollingSpectrum:YES];

        //}
        if(needToDropFirstSpectrum) [self requestSpectrum];//request the to-be-dropped spectrum


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



                        	uint32_t totalLength = (9 + waveformLength32);	// longs (1 page=1024 shorts [16 bit] are stored in 512 longs [32 bit])
							NSMutableData* theADCTraceData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
							uint32_t header = waveFormId | totalLength;
							
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
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestSpectrumTimedWorker) object:nil];
    [self setIsPollingSpectrum:NO];
        
return;

//
//    for(id obj in dataTakers){
//        [obj runIsStopping:aDataPacket userInfo:userInfo];
//    }
    
    //if(accessAllowedToHardwareAndSBC)//TODO: remove SLT stuff -tb-   2014 
    //	[pmcLink runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestSpectrumTimedWorker) object:nil];
        [self setIsPollingSpectrum:NO];
        
return;
//    if(accessAllowedToHardwareAndSBC){
//    
//    
//    
//#if 0 //TODO: omit #import "ORAmptekDP5Defs.h"    
//        [self shipSltSecondCounter: kStopRunType];
//        uint64_t runcount = [self getTime];
//        [self shipSltEvent:kRunCounterType withType:kStopRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
//#endif
//
//
//
//
//
//    }
//    
//    for(id obj in dataTakers){
//        [obj runTaskStopped:aDataPacket userInfo:userInfo];
//    }    
//
////    if(accessAllowedToHardwareAndSBC)    //TODO: remove SLT stuff -tb-   2014 
////        [pmcLink runTaskStopped:aDataPacket userInfo:userInfo];
//    
//    if(pollingWasRunning) {
//        [poller runWithTarget:self selector:@selector(readAllStatus)];
//    }
//    
//    
////TODO: rm   slt - - 
//#if 0
//    //restore socket activity (on or off)
//    if(takeUDPstreamData){
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loopCommandRequestUDPData) object:nil];
//        if(! (savedUDPSocketState & 0x1)) [self closeDataCommandSocket];
//        //if(! (savedUDPSocketState & 0x2)) [self stopListeningDataServerSocket];
//        savedUDPSocketState=0;
//    }
//#endif
//
//
//    
//    [dataTakers release];
//    dataTakers = nil;

}

/** For the V4 SLT (Auger/KATRIN)the subseconds count 100 nsec tics! (Despite the fact that the ADC sampling has a 50 nsec base.)
  */ //-tb- 
- (void) shipSltSecondCounter:(unsigned char)aType
{
return;
#if 0 //TODO: omit #import "ORAmptekDP5Defs.h"
	//aType = 1 start run, =2 stop run, = 3 start subrun, =4 stop subrun, see #defines in ORAmptekDP5Defs.h -tb-
	uint32_t tl = [self readTimeLow]; 
	uint32_t th = [self readTimeHigh]; 

	

	[self shipSltEvent:kSecondsCounterType withType:aType eventCt:0 high:th low:tl ];
#endif





	#if 0
	uint32_t location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	uint32_t data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | (aType & 0xf);
			data[2] = 0;	
			data[3] = th;	
			data[4] = tl;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(int32_t)*(5)]];
	#endif
}

- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(uint32_t)c high:(uint32_t)h low:(uint32_t)l
{
	//uint32_t location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;



	uint32_t location = 0; //TODO: removed subclassing from IpeCard -tb- (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	uint32_t data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | ((aCounterType & 0xf)<<4) | (aType & 0xf);
			data[2] = c;	
			data[3] = h;	
			data[4] = l;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(int32_t)*(5)]];
}


- (BOOL) doneTakingData
{
	//TODO: remove SLT stuff? -tb-   2014 return [pmcLink doneTakingData];
    //see ORRUnModel::takeData: may return NO and empty buffers!!!! -tb-
return YES;
}

- (uint32_t) calcProjection:(uint32_t *)pMult  xyProj:(uint32_t *)xyProj  tyProj:(uint32_t *)tyProj
{ 
	//temp----
	int i, j, k;
	int sltSize = (int)pageSize * 20;	
	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	//uint32_t xyProj[20];
	//uint32_t tyProj[100];
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
	uint32_t lTimeL     = [self read: SLT_REG_ADDRESS(kSltLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	uint32_t timeStampH = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex];
	uint32_t timeStampL = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex+1];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
	NSLogFont(aFont,@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			  aPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
	
	//readout the SLT pixel trigger data
	uint32_t buffer[2000];
	uint32_t sltMemoryAddress = (SLTID << 24) | aPageIndex<<11;
	[self readBlock:sltMemoryAddress dataBuffer:(uint32_t*)buffer length:20*100 increment:1];
	uint32_t reorderBuffer[2000];
	// Re-organize trigger data to get it in a continous data stream
	uint32_t *pMult = reorderBuffer;
	memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(uint32_t));  
	memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(uint32_t));  
	
	int i;
	int j;	
	int k;	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	uint32_t xyProj[20];
	uint32_t tyProj[100];
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

- (void) tasksCompleted: (NSNotification*)aNote
{
	//nothing to do... this just removes a run-time exception
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢SBC_Linking protocol
- (NSString*) driverScriptName {return nil;} //no driver
- (NSString*) driverScriptInfo {return @"";}


- (NSString*) sbcLockName
{
	return ORAmptekDP5SettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/AmptekDP5/AmptekDP5v4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


@end

@implementation ORAmptekDP5Model (private)
- (uint32_t) read:(uint32_t) address
{
#if 0//TODO: remove SLT stuff -tb-   2014 
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	uint32_t theData;
	[pmcLink readLongBlockPmc:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
#endif


return 0;
}

- (void) write:(uint32_t) address value:(uint32_t) aValue
{
#if 0//TODO: remove SLT stuff -tb-   2014 
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink writeLongBlockPmc:&aValue
					  atAddress:address
					 numToWrite:1];
#endif



}


- (void) readBlock:(uint32_t)  address 
		dataBuffer:(uint32_t*) aDataBuffer
			length:(uint32_t)  length 
		 increment:(uint32_t)  incr
{
    //DEBUG   NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
#if 0//TODO: remove SLT stuff -tb-   2014 
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink readLongBlockPmc:   aDataBuffer
					  atAddress: address
					  numToRead: length];
#endif



}


@end






#if 0 //this is already defined in ORIpeSlowControlModel.m/.h -tb- 2015-08-26

//from http://www.macresearch.org/cocoa-scientists-part-xxvi-parsing-csv-data
//NSString category to read a CSV table from a given string and convert it to a array of arrays
//-tb- 2011-12-15

@implementation NSString (ParsingExtensions)

-(NSArray *)csvRows {
    NSMutableArray *rows = [NSMutableArray array];

    // Get newline character set
    NSMutableCharacterSet *newlineCharacterSet = (id)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [newlineCharacterSet formIntersectionWithCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];

    // Characters that are important to the parser
    NSMutableCharacterSet *importantCharactersSet = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@",\""];
    [importantCharactersSet formUnionWithCharacterSet:newlineCharacterSet];

    // Create scanner, and scan string
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    while ( ![scanner isAtEnd] ) {        
        BOOL insideQuotes = NO;
        BOOL finishedRow = NO;
        NSMutableArray *columns = [NSMutableArray arrayWithCapacity:10];
        NSMutableString *currentColumn = [NSMutableString string];
        while ( !finishedRow ) {
            NSString *tempString;
            if ( [scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString] ) {
                [currentColumn appendString:tempString];
            }

            if ( [scanner isAtEnd] ) {
                if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                finishedRow = YES;
            }
            else if ( [scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString] ) {
                if ( insideQuotes ) {
                    // Add line break to column text
                    [currentColumn appendString:tempString];
                }
                else {
                    // End of row
                    if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                    finishedRow = YES;
                }
            }
            else if ( [scanner scanString:@"\"" intoString:NULL] ) {
                if ( insideQuotes && [scanner scanString:@"\"" intoString:NULL] ) {
                    // Replace double quotes with a single quote in the column string.
                    [currentColumn appendString:@"\""]; 
                }
                else {
                    // Start or end of a quoted string.
                    insideQuotes = !insideQuotes;
                }
            }
            else if ( [scanner scanString:@"," intoString:NULL] ) {  
                if ( insideQuotes ) {
                    [currentColumn appendString:@","];
                }
                else {
                    // This is a column separating comma
                    [columns addObject:currentColumn];
                    currentColumn = [NSMutableString string];
                    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
                }
            }
        }
        if ( [columns count] > 0 ) [rows addObject:columns];
    }

    return rows;
}

@end

#endif
