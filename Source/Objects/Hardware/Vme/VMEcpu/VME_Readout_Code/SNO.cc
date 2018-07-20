/*
 *  SNO.cc
 *  OrcaIntel
 *
 *  Created by Mark Howe on 1/8/08.
 *  Copyright 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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


#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <dlfcn.h>

extern "C" {
#include "HW_Readout.h"
#include "SNO.h"
#include "SBC_Job.h"
#include "SBC_Readout.h"
#include "SNOCmds.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
}

#include "universe_api.h"
#include "ORMTCReadout.hh"

extern int32_t		dataIndex;
extern int32_t*		data;
extern char			needToSwap;
extern SBC_JOB		sbc_job;
extern pthread_mutex_t jobInfoMutex;

void loadXL2Xilinx_sharc(SBC_Packet* aPacket);
void loadXL2Xilinx_penn(SBC_Packet* aPacket);


void processSNOCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){		
		case kSNOMtcLoadXilinx: loadMtcXilinx(aPacket);	break;
		case kSNOXL2LoadClocks: loadXL2Clocks(aPacket);	break;
		case kSNOXL2LoadXilinx: startJob(&loadXL2Xilinx,aPacket); break;
		case kSNOMtcFirePedestalJobFixedTime: startJob(&firePedestalJobFixedTime, aPacket); break;
		case kSNOMtcEnablePedestalsFixedTime: enablePedestalsFixedTime(aPacket); break;			
		case kSNOMtcFirePedestalsFixedTime: firePedestalsFixedTime(aPacket); break;			
		case kSNOMtcLoadMTCADacs: loadMTCADacs(aPacket); break;
		case kSNOMtcatResetMtcat: mtcatResetMtcat(aPacket); break;
		case kSNOMtcatResetAll:mtcatResetAll(aPacket); break;
		case kSNOMtcatLoadCrateMask: mtcatLoadCrateMask(aPacket); break;
        case kSNOReadHVStop: hvEStopPoll(aPacket); break;
        case kSNOMtcTellReadout: mtcTellReadout(aPacket); break;
	}
}


void loadMtcXilinx(SBC_Packet* aPacket)
{
	SNOMtc_XilinxLoadStruct* p = (SNOMtc_XilinxLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOMtc_XilinxLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and offsets from the payload
	uint32_t baseAddress    = p->baseAddress;
	uint32_t addressModifier = p->addressModifier;
	uint32_t programReg      = baseAddress + p->programRegOffset;
	uint32_t fileSize        = p->fileSize;
	uint32_t lastByte		= fileSize;
	uint8_t* charData		= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOMtc_XilinxLoadStruct);	//point to the file data
	
	//--------------------------- The file format as of 1/7/97 -------------------------------------
	//
	// 1st field: Beginning of the comment block -- /
	//			  If no backslash then you will get an error message and Xilinx load will abort
	// Now include your comment.
	// The comment block is delimited by another backslash.
	// If no backslash at the end of the comment block then you will get error message.
	//
	// After the comment block include the data in ACSII binary.
	// No spaces or other characters in between data. It will complain otherwise.
	//
	//----------------------------------------------------------------------------------------------
	
	uint32_t result;
	uint32_t bitCount	= 0UL;
	uint32_t readValue	= 0UL;
	uint32_t aValue		= 0UL;
	uint8_t  firstPass	= 1;
	uint8_t  errorFlag	= 0;
	char  errorMessage[80];
	uint32_t byte = 0;
	memset(errorMessage,'\0',80);		

	const uint32_t DATA_HIGH_CLOCK_LOW = 0x00000001; 	 // bit 0 high and bit 1 low
	const uint32_t DATA_LOW_CLOCK_LOW  = 0x00000000;  	 // bit 0 low and bit 1 low
	
	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		aValue = 0x00000008;				// set  all bits, except bit 3[PROG_EN], low -- new step 1/16/97
		result = write_device(device, (char*)(&aValue), 4, programReg);
		if(result == 4){
			aValue = 0x00000002;			// set  all bits, except bit 1[CCLK], low				
			result = write_device(device, (char*)(&aValue), 4, programReg);
			usleep(10000);					// 100 msec delay
		}
		
		if(result != 4){
			strcpy(errorMessage,"Error writing to program register.");		
			errorFlag = 1;	//early exit
		}
				
		if(!errorFlag) for (byte=0; byte<lastByte; byte++){
			if ( firstPass && (*charData != '/') ){
				strcpy(errorMessage,"Invalid first character in Xilinx file.");		
				errorFlag = 2;	//early exit
				break;
			}
			
			if (firstPass){
			
				firstPass = 0;
			
				charData++;							// for the first slash
				byte++;  							// need to keep track of i
			
				while(*charData++ != '/'){
					byte++;
					if ( byte>lastByte ){			
						strcpy(errorMessage,"Comment block not delimited by a backslash..");		
						errorFlag = 3;
						break;		//early exit
					}
				}
				byte++;
			}
			
			if(errorFlag)break;		//early exit
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) ){		
				charData++;
			}
			else {
				
				bitCount++;
				if (      *charData == '1' ) aValue = DATA_HIGH_CLOCK_LOW;	// bit 0 high and bit 1 low
				else if ( *charData == '0' ) aValue = DATA_LOW_CLOCK_LOW;	// bit 0 low and bit 1 low
				else {
					strcpy(errorMessage,"Invalid character in Xilinx file.");		
					errorFlag = 4;
					break; //early exit
				}
				charData++;

				result = write_device(device, (char*)(&aValue), 4, programReg);
				if(result == 4){
					aValue |= (1UL << 1);	 // perform bitwise OR to set the bit 1 high[toggle clock high]	
					
					result = write_device(device, (char*)(&aValue), 4, programReg);
					if(result != 4)errorFlag = 6;
				}
				else errorFlag = 5;
				
				if(errorFlag){
					strcpy(errorMessage,"Xilinx load failed. Unable to toggle mtc clock.");		
					errorFlag = 7;
					break; //early exit
				}
			}
		}
		
		if(!errorFlag){
			
			usleep(10000); // 10 msec delay
			// check to see if the Xilinx was loaded properly 
			// read the bit 2, this should be high if the Xilinx was loaded
			result = read_device(device,(char*)(&readValue),4,programReg);
			
			if ((result != 4) | !(readValue & 0x000000010)){	// bit 4, PROGRAM*, should be high for Xilinx success		
				if(result!=4)strcpy(errorMessage,"Xilinx load failed for the MTC/D! (final check failed)");		
				else strcpy(errorMessage,"Xilinx load failed for the MTC/D! (PROGRAM*, bit 4 not high at end)");		
				errorFlag |= 0x80000000;
			}
		}
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
	}
	/* echo the structure back with the error code*/
	/* 0 == no Error*/
	/* non-0 means an error*/
	SNOMtc_XilinxLoadStruct* returnDataPtr = (SNOMtc_XilinxLoadStruct*)aPacket->payload;
	uint32_t errLen = strlen(errorMessage);
	if(errLen >= kSBC_MaxMessageSizeBytes-1){
		errLen = kSBC_MaxMessageSizeBytes-1;
		aPacket->message[kSBC_MaxMessageSizeBytes-1] = '\0';	
	}
	strncpy(aPacket->message,errorMessage,errLen);
	
	returnDataPtr->baseAddress      = baseAddress;
	returnDataPtr->programRegOffset = programReg;
	returnDataPtr->addressModifier  = addressModifier;
	returnDataPtr->errorCode		= errorFlag;
	returnDataPtr->fileSize         = byte;
	
	int32_t* lptr = (int32_t*)returnDataPtr;
	if(needToSwap) SwapLongBlock(lptr,sizeof(SNOMtc_XilinxLoadStruct)/sizeof(int32_t));
	
	writeBuffer(aPacket);  
	close_device(device);

}

void loadXL2Clocks(SBC_Packet* aPacket)
{
	SNOXL2_ClockLoadStruct* p = (SNOXL2_ClockLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOXL2_ClockLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and offsets from the payload
	uint32_t addressModifier		= p->addressModifier;
	uint32_t xl2_select_reg			= p->xl2_select_reg;
	//uint32_t xl2_select_xl2			= p->xl2_select_xl2;
	uint32_t xl2_clock_cs_reg		= p->xl2_clock_cs_reg;
	//uint32_t xl2_master_clk_en		= p->xl2_master_clk_en;
	uint32_t xl2_master_clk_en		= 0x00008000;
	//uint32_t allClocksEnabled		= p->allClocksEnabled;
	uint32_t allClocksEnabled		= 0x00008444;
	uint8_t* charData				= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOXL2_ClockLoadStruct);				//point to the clock file data

	uint8_t  errorFlag	= 0;
	char errorMessage[80];
	memset(errorMessage,'\0',80);		

	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		//do the clock load
		//-------------- variables -----------------
		uint32_t result;
		uint32_t theOffset	= 0;	
		uint32_t writeValue;
		uint32_t bit17		= 0x00020000;
		
		//result = write_device(device, (char*)(&xl2_select_xl2), 4, xl2_select_reg);			//select the XL2 --do we need to do this, the value is wiped next line
			
		//enable master clock
		result = write_device(device, (char*)(&bit17), 4, xl2_select_reg);					//xl2_clock_cs_reg requires bit 17 set
		if(result != 4){
			strcpy(errorMessage,"Error selecting clock reg.");		
			errorFlag = 1;	//early exit
		}
		else {
			result = write_device(device, (char*)(&xl2_master_clk_en), 4, xl2_clock_cs_reg);	//enable master clock
			if(result != 4){
				strcpy(errorMessage,"Error enabling master clock.");		
				errorFlag = 2;	//early exit
			}
		}
		if(!errorFlag){
			int j;
			for(j = 1; j<=3; j++){			// there are three clocks, Memory, Sequencer and ADC
				
				// skip the comment line
				while ( *charData != '\r' ) charData++;
				
				charData++;
				
				// the first field has to be a ONE or a ZERO
				if ( ( *charData != '1') && ( *charData != '0')) {
					strcpy(errorMessage,"Invalid first characer in clock file.");		
					errorFlag = 1;
					break; //early exit
				}
				int i;
				for (i = 1; i<=4; i++){		// there are four lines of data per clock
					while ( *charData != '\r' ){    
						
						writeValue = xl2_master_clk_en;	// keep the master clock enabled
						if( *charData == '1' ){
							writeValue |= (1UL<< (1 + theOffset));
						}
						charData++;
						
						result = write_device(device, (char*)(&writeValue), 4, xl2_clock_cs_reg);
						if(result != 4){
							strcpy(errorMessage,"Error loading clock bit.");		
							errorFlag = 2;	//early exit
							break;
						}
						
						if (theOffset == 0)	writeValue += 1;
						else				writeValue |= (1UL << theOffset);
						
						result = write_device(device, (char*)(&writeValue), 4, xl2_clock_cs_reg);
						if(result != 4){
							strcpy(errorMessage,"Error loading clock bit.");		
							errorFlag = 3;	//early exit
							break;
						}
						
					}
					
					charData++;
				}
				theOffset += 4;
			}
			
			// keep the master clock enabled and enable all three clocks
			writeValue = allClocksEnabled;	
			result = write_device(device, (char*)(&writeValue), 4, xl2_clock_cs_reg);
			if(result != 4){
				strcpy(errorMessage,"Error loading clock bit.");		
				errorFlag = 4;	//early exit
			}
			
		}
		if(!errorFlag){
			writeValue = 0UL;
			result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);			//deselect all
			if(result != 4){
				strcpy(errorMessage,"Error deselecting xl2.");		
				errorFlag = 5;	//early exit
			}
		}
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
	}
	
	/* echo the structure back with the error code*/
	/* 0 == no Error*/
	/* non-0 means an error*/
	SNOXL2_ClockLoadStruct* returnDataPtr = (SNOXL2_ClockLoadStruct*)aPacket->payload;
	uint32_t errLen = strlen(errorMessage);
	if(errLen >= kSBC_MaxMessageSizeBytes-1){
		errLen = kSBC_MaxMessageSizeBytes-1;
		aPacket->message[kSBC_MaxMessageSizeBytes-1] = '\0';	
	}
	strncpy(aPacket->message,errorMessage,errLen);
	
	returnDataPtr->errorCode		= errorFlag;
	
	int32_t* lptr = (int32_t*)returnDataPtr;
	if(needToSwap) SwapLongBlock(lptr,sizeof(SNOXL2_ClockLoadStruct)/sizeof(int32_t));
	
	writeBuffer(aPacket);  
	close_device(device);
	
}

#define FATAL_ERROR(n,message) {strncpy(errorMessage,message,80);	errorFlag = n;	goto earlyExit;}

static __inline__ int64_t elapsed_ticks(int64_t t1, int64_t t2) {
	return t2 - t1;
}

static __inline__ int64_t getticks(void) {
	unsigned a, d;
	asm volatile("rdtsc" : "=a" (a), "=d" (d));
	return ((int64_t) a) | (((int64_t) d) << 32);
}

static double parse_cpu_freq(void) {
	FILE* cpuinfo;
	double freq = 0;
	
	if ((cpuinfo = fopen("/proc/cpuinfo", "r")) == NULL) {
		// fixme!
		//printf("cpuinfo failed\n");
		return 2166.957;
	}
	
	while (!feof(cpuinfo)) {
		char buffer[80];
		
		fgets(buffer, 80, cpuinfo);
		if (strlen(buffer) == 0) continue;
		
		if (strncasecmp(buffer, "cpu MHz", 7) == 0) {
			char* tok = strtok(buffer, ":");
			
			if (tok != NULL) {
				tok = strtok((char*) NULL, ":");
				freq = strtod(tok, NULL);
			}
			break;
		}
	}
	return freq;
}

void fineSleep(const uint64_t ticks) {
	int64_t tim1, tim2;
	tim1 = getticks();
	do {
		tim2 = getticks();
	} while (elapsed_ticks(tim1, tim2) < (int64_t) ticks);
}

void loadXL2Xilinx(SBC_Packet* aPacket)
{
	loadXL2Xilinx_penn(aPacket);
}

void loadXL2Xilinx_penn(SBC_Packet* aPacket)
{
	//
	//this function is meant to be launched as a job
	//
	SNOXL2_XilinixLoadStruct* p = (SNOXL2_XilinixLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOXL2_XilinixLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and other data from the payload
	uint32_t addressModifier		= p->addressModifier;
	uint32_t xl2_select_reg			= p->xl2_select_reg;
	uint32_t xl2_control_status_reg		= p->xl2_control_status_reg;
	uint32_t xl2_xilinx_user_control	= p->xl2_xilinx_user_control;
	uint32_t selectBits			= p->selectBits;
	uint32_t xl2_select_xl2			= p->xl2_select_xl2;
	uint32_t xl2_xlpermit			= p->xl2_xlpermit;
	uint32_t xl2_enable_dp			= 0x00000008UL;
	uint32_t xl2_disable_dp			= 0x00000004UL;
	uint32_t xl2_control_bit11		= 0x00000800UL;
	uint32_t xl2_control_clock		= 0x00000400UL;
	uint32_t xl2_control_data		= 0x00000200UL;
	uint32_t xl2_control_done_prog		= 0x00000100UL;
	uint32_t length					= p->fileSize;
	uint8_t* charData				= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOXL2_XilinixLoadStruct);				//point to the clock file data
	
	char  errorMessage[80];
	memset(errorMessage,'\0',80);		
	uint32_t  errorFlag	 = 0;
    if(errorFlag){} //fix a stupid compiler warning
	uint8_t  finalStatus = 0; //assume failure

	// these have to be adjustable and crate dependent
	uint theRegDelay = 500;   //the coarse delay for register settings in us
	double theXilinxDelay = 10;  //the fine delay in between the XilinX bits in us

	//const double ticks_to_nsec = 1000 / parse_cpu_freq();
	const double nsec_to_ticks = parse_cpu_freq() / 1000;
	theXilinxDelay *= 1e3 * nsec_to_ticks;
	
	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		//--------------------------- The file format as of 4/17/96 -------------------------------------
		//
		// 1st field: Beginning of the comment block -- /
		//			  If no backslash then you will get an error message and Xilinx load will abort
		// Now include your comment.
		// The comment block is delimited by another backslash.
		// If no backslash at the end of the comment block then you will get error message.
		//
		// After the comment block include the data in ACSII binary.
		// No spaces or other characters in between data. It will complain otherwise.
		//
		//----------------------------------------------------------------------------------------------
		
		uint32_t bitCount		= 0UL;
		uint32_t writeValue		= 0UL;
		uint32_t readValue = 0UL;
		uint8_t  firstPass		= 1;
		uint32_t index			= length; 
		uint32_t result;

		//select the cards that will be inited
		writeValue = 0UL;
		result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);
		
		usleep(theRegDelay);	//200 ms

		//here we differ from penn, they start with what is going to happen then they say where
		// make sure that the XL2 DP bit is set low and bit 11 (xilinx active) is high -- this is not yet sent to the MB
		result = write_device(device, (char*)(&xl2_control_bit11), 4, xl2_control_status_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: Setting DP bit")
			
		usleep(theRegDelay);	//200 ms
		
		result = write_device(device, (char*)(&selectBits), 4, xl2_select_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: select xl2")

		//usleep(theRegDelay);	//200 ms
		
		// now tell the fecs we are going to load xilinx
		// now toggle this on the MB and turn on the XL2 xilinx load permission bit
		// DO NOT USE CXL2_Secondary_Reg_Access here unless you retain the state
		// of the select bits in register zero!!!!		
		writeValue = xl2_xlpermit | xl2_enable_dp;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_xlpermit | xl2_enable_dp")	
		
		//usleep(theRegDelay);	//200 ms
		
		// turn off the DP bit but keep the permission 
		writeValue = xl2_xlpermit | xl2_disable_dp;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_xlpermit | xl2_disable_dp")	

		usleep(theRegDelay);	//200 ms
		
		// toggle xilinx active and control clock high
		writeValue = xl2_control_bit11 | xl2_control_clock;
		result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_control_bit11 | xl2_control_clock")
		
		//usleep(theRegDelay);	//200 ms
			
		uint32_t i;
		for (i = 1;i < index;i++){
			
			if(sbc_job.killJobNow) FATAL_ERROR(666,"Job Killed. Early Exit.")
			
			if ((firstPass) && (*charData != '/')) FATAL_ERROR(2,"Bad Xilinx File: Invalid first characer in xilinx file");
			
			if (firstPass){
				charData++;							// for the first backslash
				i++;  								// need to keep track of i
				while(*charData++ != '/'){
					
					i++;
					if (i>index) FATAL_ERROR(1,"Bad Xilinx File: Comment block not delimited by a backslash")
				}
			}
			firstPass = 0;
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) )charData++;
			else {
				
				bitCount++;
				
				//status reg is: bit8 done, bit9 data, bit10 clock, bit11 xil active
				if      (*charData == '1')  writeValue = xl2_control_bit11 | xl2_control_data;	// bit set in data to load
				else if (*charData == '0')	writeValue = xl2_control_bit11;						// bit not set in data
				else						FATAL_ERROR(2,"Bad Xilinx File: Invalid character in Xilinx file")
				charData++;	
				
				uint32_t val = writeValue | xl2_control_clock;
				result = write_device(device, (char*)(&val), 4, xl2_control_status_reg); // changed PMT 1/17/98 to match Penn code
				if(result!=4)FATAL_ERROR(3,"Write Error: xl2_control_status_reg")
				fineSleep(theXilinxDelay);
				
				result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg); // changed PMT 1/17/98 to match Penn code
				if(result!=4)FATAL_ERROR(4,"Write Error: xl2_control_status_reg")
				fineSleep(theXilinxDelay);
			}
			pthread_mutex_lock (&jobInfoMutex);     //begin critical section
			sbc_job.progress = 100*i/index;			//percent done
			pthread_mutex_unlock (&jobInfoMutex);   //end critical section
			
		}

		usleep(theRegDelay);	//200 ms
		// QRA :5/31/97 -- do this before reading the DON_PROG bit. Xilinx Load on our
		// system now works. Why this should make any diferrence is a puzzle. 
		// More Changes, RGV, PW : turn off XLPERMIT & clear this register

		//penn deselects the fec cards first keeps xl2 only
		result = write_device(device, (char*)(&xl2_select_xl2), 4, xl2_select_reg);			
		if(result!=4)FATAL_ERROR(7,"Write Error: xl2_select_reg")
		usleep(theRegDelay);	//200 ms
		
		//clear xilinx csr
		writeValue = 0UL;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4)FATAL_ERROR(5,"Write Error: xl2_xilinx_user_control")
			usleep(theRegDelay);	//200 ms
		
		//check that the load was OK
		readValue = 0UL;
		result = read_device(device,(char*)(&readValue),4,xl2_control_status_reg);
		if(result!=4)FATAL_ERROR(9,"Write Error: xl2_control_status_reg")
		if (!(readValue & xl2_control_done_prog)){	
			usleep(theRegDelay);
			result = read_device(device,(char*)(&readValue),4,xl2_control_status_reg);
			if(result!=4)FATAL_ERROR(10,"Write Error: Checking Prog Done")
				if (!(readValue & xl2_control_done_prog)){	
					if(result!=4)FATAL_ERROR(11,"Xilinx load failed XL2! (Status bit checked twice)")
						}
				else finalStatus = 1;
		}
		else finalStatus = 1;

		//clear the csr and keep the DP bit not to reset the XilinX
		writeValue = 0x0UL | xl2_control_done_prog;
		result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg);	
		if(result!=4)FATAL_ERROR(6,"Write Error: xl2_control_status_reg")

	earlyExit:
		// now deselect all cards
		writeValue = 0UL;
		result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
	}

	close_device(device);

	pthread_mutex_lock (&jobInfoMutex);     //begin critical section
	sbc_job.progress    = 100;
	sbc_job.running     = 0;
	sbc_job.killJobNow  = 0;
	sbc_job.finalStatus = finalStatus;
	strncpy(sbc_job.message,errorMessage,255);
	sbc_job.message[255] = '\0';
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
	
}

void loadXL2Xilinx_sharc(SBC_Packet* aPacket)
{
	//
	//this function is meant to be launched as a job
	//
	SNOXL2_XilinixLoadStruct* p = (SNOXL2_XilinixLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOXL2_XilinixLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and other data from the payload
	uint32_t addressModifier		= p->addressModifier;
	uint32_t selectBits				= p->selectBits;
	uint32_t xl2_select_reg			= p->xl2_select_reg;
	//uint32_t xl2_select_xl2			= p->xl2_select_xl2;
	uint32_t xl2_control_status_reg	= p->xl2_control_status_reg;
	uint32_t xl2_control_bit11		= p->xl2_control_bit11;
	uint32_t xl2_xilinx_user_control= p->xl2_xilinx_user_control;
	uint32_t xl2_xlpermit			= p->xl2_xlpermit;
	uint32_t xl2_enable_dp			= p->xl2_enable_dp;
	uint32_t xl2_disable_dp			= p->xl2_disable_dp;
	uint32_t xl2_control_clock		= p->xl2_control_clock;
	uint32_t xl2_control_data		= p->xl2_control_data;
	uint32_t xl2_control_done_prog	= p->xl2_control_done_prog;
	uint32_t length					= p->fileSize;
	uint8_t* charData				= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOXL2_XilinixLoadStruct);				//point to the clock file data
	
	char  errorMessage[80];
	memset(errorMessage,'\0',80);		
	uint32_t  errorFlag	 = 0;
    if(errorFlag){} //fix a stupid compiler warning
	uint8_t  finalStatus = 0; //assume failure
	
	// these have to be adjustable and crate dependent
	uint theRegDelay = 100000;   //the coarse delay for register settings in us
	double theXilinxDelay = 15;  //the fine delay in between the XilinX bits in us
	
	//const double ticks_to_nsec = 1000 / parse_cpu_freq();
	const double nsec_to_ticks = parse_cpu_freq() / 1000;
	theXilinxDelay *= 1e3 * nsec_to_ticks;
	
	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		//--------------------------- The file format as of 4/17/96 -------------------------------------
		//
		// 1st field: Beginning of the comment block -- /
		//			  If no backslash then you will get an error message and Xilinx load will abort
		// Now include your comment.
		// The comment block is delimited by another backslash.
		// If no backslash at the end of the comment block then you will get error message.
		//
		// After the comment block include the data in ACSII binary.
		// No spaces or other characters in between data. It will complain otherwise.
		//
		//----------------------------------------------------------------------------------------------
		
		uint32_t bitCount		= 0UL;
		uint32_t writeValue		= 0UL;
        uint32_t readValue = 0UL;
		uint8_t  firstPass		= 1;
		uint32_t index			= length; 
		uint32_t result;
		
		//select the cards that will be inited
		result = write_device(device, (char*)(&selectBits), 4, xl2_select_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: select xl2")
			
			usleep(theRegDelay);	//200 ms
		
		// make sure that the XL2 DP bit is set low and bit 11 (xilinx active) is high -- this is not yet sent to the MB
		result = write_device(device, (char*)(&xl2_control_bit11), 4, xl2_control_status_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: Setting DP bit")
			
			usleep(theRegDelay);	//200 ms
		
		// now toggle this on the MB and turn on the XL2 xilinx load permission bit
		// DO NOT USE CXL2_Secondary_Reg_Access here unless you retain the state
		// of the select bits in register zero!!!!		
		writeValue = xl2_xlpermit | xl2_enable_dp;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_xlpermit | xl2_enable_dp")	
			
			usleep(theRegDelay);	//200 ms
		
		// turn off the DP bit but keep 
		writeValue = xl2_xlpermit | xl2_disable_dp;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_xlpermit | xl2_disable_dp")	
			
			usleep(theRegDelay);	//200 ms
		
		// set  bit 11 high, bit 10 high
		writeValue = xl2_control_bit11 | xl2_control_clock;
		result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_control_bit11 | xl2_control_clock")
			
			usleep(theRegDelay);	//200 ms
		
		uint32_t i;
		for (i = 1;i < index;i++){
			
			if(sbc_job.killJobNow) FATAL_ERROR(666,"Job Killed. Early Exit.")
				
				if ((firstPass) && (*charData != '/')) FATAL_ERROR(2,"Bad Xilinx File: Invalid first characer in xilinx file");
			
			if (firstPass){
				charData++;							// for the first backslash
				i++;  								// need to keep track of i
				while(*charData++ != '/'){
					
					i++;
					if (i>index) FATAL_ERROR(1,"Bad Xilinx File: Comment block not delimited by a backslash")
						}
			}
			firstPass = 0;
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) )charData++;
			else {
				
				bitCount++;
				
				if      (*charData == '1')  writeValue = xl2_control_bit11 | xl2_control_data;	// bit set in data to load
				else if (*charData == '0')	writeValue = xl2_control_bit11;						// bit not set in data
				else						FATAL_ERROR(2,"Bad Xilinx File: Invalid character in Xilinx file")
					charData++;	
				
				uint32_t val = writeValue | xl2_control_clock;
				result = write_device(device, (char*)(&val), 4, xl2_control_status_reg); // changed PMT 1/17/98 to match Penn code
				if(result!=4)FATAL_ERROR(3,"Write Error: xl2_control_status_reg")
					fineSleep(theXilinxDelay);
				
				result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg); // changed PMT 1/17/98 to match Penn code
				if(result!=4)FATAL_ERROR(4,"Write Error: xl2_control_status_reg")
					fineSleep(theXilinxDelay);
			}
			pthread_mutex_lock (&jobInfoMutex);     //begin critical section
			sbc_job.progress = 100*i/index;			//percent done
			pthread_mutex_unlock (&jobInfoMutex);   //end critical section
			
		}
		
		usleep(theRegDelay);	//200 ms
		// QRA :5/31/97 -- do this before reading the DON_PROG bit. Xilinx Load on our
		// system now works. Why this should make any diferrence is a puzzle. 
		// More Changes, RGV, PW : turn off XLPERMIT & clear this register
		writeValue = 0UL;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4)FATAL_ERROR(5,"Write Error: xl2_xilinx_user_control")
			
			usleep(theRegDelay);	//200 ms
		
		//check that the load was OK
		result = write_device(device, (char*)(&xl2_control_done_prog), 4, xl2_control_status_reg);	
		if(result!=4)FATAL_ERROR(6,"Write Error: xl2_control_status_reg")
			//		result = write_device(device, (char*)(&xl2_select_xl2), 4, xl2_select_reg);			
			writeValue = 0x0;
		result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);			
		if(result!=4)FATAL_ERROR(7,"Write Error: xl2_select_reg")
			
			result = write_device(device, (char*)(&xl2_control_bit11), 4, xl2_control_status_reg);
		if(result!=4)FATAL_ERROR(8,"Write Error: xl2_control_status_reg")
			readValue = 0UL;
		result = read_device(device,(char*)(&readValue),4,xl2_control_status_reg);
		if(result!=4)FATAL_ERROR(9,"Write Error: xl2_control_status_reg")
			
			if (!(readValue & xl2_control_done_prog)){	
				usleep(theRegDelay);
				result = read_device(device,(char*)(&readValue),4,xl2_control_status_reg);
				if(result!=4)FATAL_ERROR(10,"Write Error: Checking Prog Done")
					if (!(readValue & xl2_control_done_prog)){	
						if(result!=4)FATAL_ERROR(11,"Xilinx load failed XL2! (Status bit checked twice)")
							}
					else finalStatus = 1;
			}
			else finalStatus = 1;
		
		result = write_device(device, (char*)(&xl2_control_done_prog), 4, xl2_control_status_reg);	//BLW 10/31/02-set bit 11 low, similar to previous version
		if(result!=4)FATAL_ERROR(12,"Write Error: xl2_control_status_reg")
			
			earlyExit:
			// now deselect all cards
			writeValue = 0UL;
		result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
	}
	
	close_device(device);
	
	pthread_mutex_lock (&jobInfoMutex);     //begin critical section
	sbc_job.progress    = 100;
	sbc_job.running     = 0;
	sbc_job.killJobNow  = 0;
	sbc_job.finalStatus = finalStatus;
	strncpy(sbc_job.message,errorMessage,255);
	sbc_job.message[255] = '\0';
	pthread_mutex_unlock (&jobInfoMutex);   //end critical section
	
}

#define kMtcControlReg 0x00007000
#define kMtcSerialReg 0x00007004
#define kMtcSoftGtReg 0x0000700c
#define kMtcOcGtReg 0x00007080
#define MTC_SERIAL_REG_SEN 0x00000001
#define MTC_SERIAL_SHFTCLKPS 0x00000020
#define MTC_CSR_LOAD_ENPS 0x00000008

static double nsec_to_ticks = 0;

void enablePedestalsFixedTime(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
	
    uint32_t error_code = 0;
	uint32_t aValue = 0;
	short j;

	//calibrate the fineSleep delay loop
	nsec_to_ticks = parse_cpu_freq() / 1000;
	
	TUVMEDevice* device = get_new_device(0x0, 0x29, 4, 0x10000);
	if(device != 0){
		for (j = 23; j >= 0; j--){							
			aValue = 0UL | MTC_SERIAL_REG_SEN;
			if (write_device(device, (char*)(&aValue), 4, kMtcSerialReg) != sizeof(aValue)) {
				LogBusError("Error setting MTC serial register.\n");
				error_code = 2;
				goto earlyExit;
			}
			aValue = 0UL | MTC_SERIAL_SHFTCLKPS;
			if (write_device(device, (char*)(&aValue), 4, kMtcSerialReg) != sizeof(aValue)) {
				LogBusError("Error setting pulser in the MTC serial register.\n");
				error_code = 3;
				goto earlyExit;
			}
		}

		//load enable pulser
		aValue = 0UL;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			LogBusError("Error loading pulser.\n");
			error_code = 4;
			goto earlyExit;
		}
		aValue = MTC_CSR_LOAD_ENPS;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			LogBusError("Error loading pulser.\n");
			error_code = 6;
			goto earlyExit;
		}
		aValue = 0UL;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			LogBusError("Error loading pulser.\n");
			error_code = 6;
			goto earlyExit;
		}
	earlyExit:
		;
		//todo: get back into a well defined state
	}
	else {
		error_code = 1;
	}
	
	close_device(device);		
	
        p[0] = error_code;
        if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
        writeBuffer(aPacket);
}


void firePedestalJobFixedTime(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));

    uint32_t pedestal_count = p[0];
    uint64_t pedestal_delay = p[1] * 100ULL * nsec_to_ticks; //p[1] is the delay in [100 nsec]
    uint32_t csr_mask = p[2];
    uint32_t error_code = 0;
    if(error_code){} //fix a stupid compiler warning
	uint32_t aValue = 0;
	uint32_t i = 0;

	char  errorMessage[80];
	memset(errorMessage,'\0',80);		
	uint8_t finalStatus = 0; //assume failure

	TUVMEDevice* device = get_new_device(0x0, 0x29, 4, 0x10000);
	if(device != 0){
		//enable pulser (and pedestal)
		aValue = csr_mask;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			strcpy(errorMessage, "Error enabling pedestals and pulser.\n");
			error_code = 2;
			goto earlyExit;
		}

		aValue = 0; //doesn't matter
		for (i = 0; i < pedestal_count; i++){
			fineSleep(pedestal_delay);
			if (write_device(device, (char*)(&aValue), 4, kMtcSoftGtReg) != sizeof(aValue)) {
				strcpy(errorMessage, "Error firing pedestal.\n");
				error_code = 4;
				goto earlyExit;
			}
			pthread_mutex_lock (&jobInfoMutex);     //begin critical section
			sbc_job.progress = 100 * (i + 1) / pedestal_count;	//percent done
			pthread_mutex_unlock (&jobInfoMutex);   //end critical section
		}
	
		//disable pedestals and pulser
		aValue = 0;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			strcpy(errorMessage, "Error disabling pedestals and pulser.\n");
			error_code = 6;
			goto earlyExit;
		}

		finalStatus = 1; //success
		
	earlyExit:
		;
		//todo: get back into a well defined state
	}
	else {
		strcpy(errorMessage, "VME device failed.\n");
		error_code = 1;
	}
	
	close_device(device);		

	pthread_mutex_lock (&jobInfoMutex);     //begin critical section
	sbc_job.progress    = 100;
	sbc_job.running     = 0;
	sbc_job.killJobNow  = 0;
	sbc_job.finalStatus = finalStatus;
	strncpy(sbc_job.message,errorMessage,255);
	sbc_job.message[255] = '\0';
	pthread_mutex_unlock (&jobInfoMutex);   //end critical section
}

void firePedestalsFixedTime(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));

    uint32_t pedestal_count = p[0];
    uint64_t pedestal_delay = p[1] * 100 * nsec_to_ticks; //p[1] is the delay in [100 nsec]
    uint32_t csr_mask = p[2];
    
    uint32_t error_code = 0;
	uint32_t gtidDiff = 0;
	uint32_t aValue = 0;
	uint32_t beforeGTId, afterGTId;
	uint32_t i = 0;
	
	TUVMEDevice* device = get_new_device(0x0, 0x29, 4, 0x10000);
	if(device != 0){
		//enable pedestals and pulser
		aValue = csr_mask;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			LogBusError("Error enabling pedestals and pulser.\n");
			error_code = 2;
			goto earlyExit;
		}

		//read GTId
		if (read_device(device, (char*)(&aValue), 4, kMtcOcGtReg) != sizeof(aValue)) {
			LogBusError("Error reading GTID.\n");
			error_code = 3;
			goto earlyExit;
		}
		beforeGTId = aValue & 0x00ffffff;

		aValue = 0; //doesn't matter
		for (i = 0; i < pedestal_count; i++){
			fineSleep(pedestal_delay);
			if (write_device(device, (char*)(&aValue), 4, kMtcSoftGtReg) != sizeof(aValue)) {
				LogBusError("Error firing pedestal.\n");
				error_code = 4;
				goto earlyExit;
			}
		}

		//read GTId
		if (read_device(device, (char*)(&aValue), 4, kMtcOcGtReg) != sizeof(aValue)) {
			LogBusError("Error reading GTID.\n");
			error_code = 5;
			goto earlyExit;
		}
		afterGTId = aValue & 0x00ffffff;
		
		//disable pedestals and pulser
		aValue = 0;
		if (write_device(device, (char*)(&aValue), 4, kMtcControlReg) != sizeof(aValue)) {
			LogBusError("Error disabling pedestals and pulser.\n");
			error_code = 6;
			goto earlyExit;
		}
		
		//calculate diff (24 bit rollover)
		if (beforeGTId < afterGTId) gtidDiff = afterGTId - beforeGTId;
		else gtidDiff = 0x01000000 + afterGTId - beforeGTId;
		
	earlyExit:
		;
		//todo: get back into a well defined state
	}
	else {
		error_code = 1;
	}
	
	close_device(device);		
	
    p[0] = error_code;
	p[1] = gtidDiff;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}


#define kMtcDacCntReg		0x00007008
#define kMtcMaskReg         0x00007034
#define MTC_DAC_CNT_DACSEL	0x00004000
#define MTC_DAC_CNT_DACCLK	0x00008000

void loadMTCADacs(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
	
    uint32_t error_code = 0;
	uint16_t index, dacIndex;
	int16_t bitIndex = 0;
	uint16_t dacValues[14];
	uint32_t aValue = 0;
	uint32_t dacValue;
	uint32_t triggerMask = 0;

	// STEP 3: load the DAC values from the database into dacValues[14]
	for (index = 0; index < 14 ; index++){
		dacValues[index] = (uint16_t) p[index];
	}
	
	TUVMEDevice* device = get_new_device(0x0, 0x29, 4, 0x10000);
	if(device != 0){
		//clocking in MTCA DACs may generate triggers, so unset the trigger mask
		//read trigger mask
		if (read_device(device, (char*)(&aValue), 4, kMtcMaskReg) != sizeof(aValue)) {
			LogBusError("Error reading trigger mask.\n");
			error_code = 2;
			goto earlyExit;
		}
		triggerMask = aValue & 0x03ffffff; //26 bits valid only
		
		//unset trigger mask
		aValue = 0;
		if (write_device(device, (char*)(&aValue), 4, kMtcMaskReg) != sizeof(aValue)) {
			LogBusError("Error unsetting trigger mask.\n");
			error_code = 3;
			goto earlyExit;
		}
		
		// STEP 4: Set DACSEL in Register 2 high[in hardware it's inverted -- i.e. it is set low]
		aValue = MTC_DAC_CNT_DACSEL;
		if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
			LogBusError("Error setting DACSEL high.\n");
			error_code = 4;
			goto earlyExit;
		}
		
		// STEP 5: now parallel load the 16bit word into the serial shift register
		// STEP 5a: the first 4 bits are loaded zeros 
		for (index = 0; index < 4 ; index++){
			// data bit, with DACSEL high, clock low
			aValue = 0UL | MTC_DAC_CNT_DACSEL;
			if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
				LogBusError("Error clocking in leading zeros.\n");
				error_code = 5;
				goto earlyExit;
			}
			
			// clock high
			aValue = 0UL | MTC_DAC_CNT_DACSEL | MTC_DAC_CNT_DACCLK;
			if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
				LogBusError("Error clocking in leading zeros.\n");
				error_code = 6;
				goto earlyExit;
			}
			
			// clock low
			aValue = 0UL | MTC_DAC_CNT_DACSEL;
			if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
				LogBusError("Error clocking in leading zeros.\n");
				error_code = 7;
				goto earlyExit;
			}
		}
		
		//STEP 5b:  now build the word and load the next 12 bits, load MSB first
		for (bitIndex = 11; bitIndex >= 0 ; bitIndex--){
			dacValue = 0UL;
			for (dacIndex = 0; dacIndex < 14 ; dacIndex++){
				if ( dacValues[dacIndex] & (1UL << bitIndex) )
					dacValue |= (1UL << dacIndex);
			}
			
			// data bit, with DACSEL high, clock low
			aValue = dacValue | MTC_DAC_CNT_DACSEL;
			if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
				LogBusError("Error clocking in DAC bit: %d.\n", bitIndex);
				error_code = 8;
				goto earlyExit;
			}
			
			// clock high
			aValue = dacValue | MTC_DAC_CNT_DACSEL | MTC_DAC_CNT_DACCLK;
			if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
				LogBusError("Error clocking in DAC bit: %d.\n", bitIndex);
				error_code = 9;
				goto earlyExit;
			}
			
			// clock low
			aValue = dacValue | MTC_DAC_CNT_DACSEL;
			if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
				LogBusError("Error clocking in DAC bit: %d.\n", bitIndex);
				error_code = 10;
				goto earlyExit;
			}
		}
		
		// STEP 5: Set DACSEL in Register 2 low[in hardware it's inverted -- i.e. it is set high], with all other bits low
		aValue = 0UL;
		if (write_device(device, (char*)(&aValue), 4, kMtcDacCntReg) != sizeof(aValue)) {
			LogBusError("Error setting DACSEL low.\n");
			error_code = 11;
			goto earlyExit;
		}

		//set trigger mask back
		aValue = triggerMask;
		if (write_device(device, (char*)(&aValue), 4, kMtcMaskReg) != sizeof(aValue)) {
			LogBusError("Error setting trigger mask back.\n");
			error_code = 12;
			goto earlyExit;
		}
		
	earlyExit:
		;
		//todo: get back into a well defined state
	}
	else {
		error_code = 1;
	}

	close_device(device);
	
    p[0] = error_code;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}

void mtcatResetMtcat(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    unsigned char mtcat_id = p[0];
    int32_t error_code = 0;
 
    char* dl_err;
    void* hdl = NULL;
    int (*reset_mtcat) (unsigned char);

    hdl = dlopen("libmtcat_lj.so", RTLD_LAZY);
    if (hdl == NULL) {
        error_code = 1;
        LogError("libmtcat_lj.so not found\n");
        goto exit;
    }
    dlerror();

    reset_mtcat = (int(*)(unsigned char)) dlsym(hdl, "reset_mtcat");
    if ((dl_err = dlerror()) != NULL) {
        LogError("%s, %d\n", dl_err, stderr);
        error_code = 2;
        goto early_exit;
    }

    error_code = reset_mtcat(mtcat_id);

early_exit:    
    dlclose(hdl);
    
exit:
    p[0] = error_code;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}

void mtcatResetAll(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    int32_t error_code = 0;

    char* dl_err;
    void* hdl = NULL;
    int (*reset_all) ();

    hdl = dlopen("libmtcat_lj.so", RTLD_LAZY);
    if (hdl == NULL) {
        error_code = 1;
        LogError("libmtcat_lj.so not found\n");
        goto exit;
    }
    dlerror();

    reset_all = (int(*)())dlsym(hdl, "reset_all");
    if ((dl_err = dlerror()) != NULL) {
        LogError("%s, %d\n", dl_err, stderr);
        error_code = 2;
        goto early_exit;
    }

    error_code = reset_all();
    
early_exit:    
    dlclose(hdl);
    
exit:
    p[0] = error_code;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}

void mtcatLoadCrateMask(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    unsigned int crate_mask = p[0];
    unsigned char mtcat_id = p[1];
    uint32_t error_code = 0;

    char* dl_err;
    void* hdl = NULL;
    int (*load_crate_mask) (unsigned int, unsigned char);
    
    //printf("load crate mask 0x%08x to mtca+ %d\n", crate_mask, mtcat_id);

    hdl = dlopen("libmtcat_lj.so", RTLD_LAZY);
    if (hdl == NULL) {
        error_code = 1;
        LogError("libmtcat_lj.so not found\n");
        goto exit;
    }
    dlerror();
    
    load_crate_mask = (int(*)(unsigned int, unsigned char))dlsym(hdl, "load_crate_mask");
    if ((dl_err = dlerror()) != NULL) {
        LogError("%s, %d\n", dl_err, stderr);
        error_code = 2;
        goto early_exit;
    }
    
    error_code = load_crate_mask(crate_mask, mtcat_id);
    //printf("done with error_code: %d\n", error_code);
    
early_exit:    
    dlclose(hdl);
    
exit:
    p[0] = error_code;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}

void hvEStopPoll(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    //unsigned int crate_mask = p[0];
    //unsigned char mtcat_id = p[1];
    int32_t responseFromHv = 0;
    
    char* dl_err;
    void* hdl = NULL;
    //int (*load_crate_mask) (unsigned int, unsigned char);
    int (*hv_stop_ok)( );
    
    //printf("load crate mask 0x%08x to mtca+ %d\n", crate_mask, mtcat_id);
    
    hdl = dlopen("libmtcat_lj.so", RTLD_LAZY);
    if (hdl == NULL) {
        responseFromHv = 300;
        LogError("libmtcat_lj.so not found\n");
        goto exit;
    }
    
    dlerror();
    
    hv_stop_ok = ( int(*)() )dlsym(hdl, "hv_stop_ok");
    if ((dl_err = dlerror()) != NULL) {
        LogError("%s, %d\n", dl_err, stderr);
        responseFromHv = 100;
        goto early_exit;
    }
    
    responseFromHv = hv_stop_ok();
    //printf("done with error_code: %d\n", error_code);
    
early_exit:
    dlclose(hdl);
    
exit:
    p[0] = responseFromHv;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}

void mtcTellReadout(SBC_Packet* aPacket)
{
    uint32_t* p = (uint32_t*) aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    unsigned int cmd = p[0];
    uint32_t error_code = 0;
    SBC_card_info empty_card_info;
    ORMTCReadout* mtc_readout = new ORMTCReadout(&empty_card_info);

	switch(cmd){
		case kSNOMtcTellReadoutHardEnd:
            mtc_readout->setIsNextStopHard(true);
            break;
        default:
            error_code = 1;
            break;
    }
    
    p[0] = error_code;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    writeBuffer(aPacket);
}
