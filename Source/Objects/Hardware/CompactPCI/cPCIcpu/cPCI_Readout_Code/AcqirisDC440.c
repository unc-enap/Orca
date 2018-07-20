//
//  AcqirisDC440.c
//  Orca
//
//  Created by Mark Howe on Mon Sept 10, 2007
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#include <stdlib.h>

#include <sys/time.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include "SBC_Cmds.h"
#include "AcqirisDC440Cmds.h"
#include "AcqirisDC440.h"
#include "ORAcqirisDC440Readout.hh"
#include "CircularBuffer.h"
#include "SBC_Readout.h"

#define true -1
#define false 0


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);


// ### Global variables ###
ViInt32 NumInstruments;			// Number of instruments
ViSession InstrumentID[10];		// Array of instrument handles

typedef struct digitizerInfo{
	char name[20];
	int32_t busNumber;
	int32_t serialNumber;
	int32_t instrumentID;
} digitizerInfo;
digitizerInfo digitizer[10];
char acqirisInitFlag;
extern char needToSwap;

#define ADcTimeout		 500
#define kWaitForEndOfAcq 0x00000001	// Wait for end of acq.
#define kGetNumSeg       0x00000002	// Get number of segments.
#define kStopAcq         0x00000004	// Force stop acq.
#define kMaxNbrSegments  10

void decodeArgs(char* inputString,char** argv, int32_t numArgs)
{
	char **ap;
	for (ap = argv; (*ap = strsep(&inputString, ",")) != NULL;) {
		if (**ap != '\0') if (++ap >= &argv[numArgs]) break;
	}
}

void sendGetResponse(SBC_Packet* aPacket, int32_t status, char* aString)
{
	int32_t aCmd = aPacket->cmdHeader.cmdID;
	aPacket->cmdHeader.destination	= kAcqirisDC440;
	aPacket->cmdHeader.numberBytesinPayload	= sizeof(Acquiris_GetCmdStatusStruct);
	aPacket->cmdHeader.cmdID		= aCmd;
	aPacket->message[0] = '\0';
	Acquiris_GetCmdStatusStruct* p = (Acquiris_GetCmdStatusStruct*)aPacket->payload;	
	p->status = status;
	strcpy(p->responseBuffer,aString);
	if(needToSwap)SwapLongBlock(p,1); //NOTE: only swap the status, ascii doesn't get swapped.
	writeBuffer(aPacket);
}

void sendSetResponse(SBC_Packet* aPacket, int32_t status)
{
	int32_t aCmd = aPacket->cmdHeader.cmdID;
	aPacket->cmdHeader.destination	= kAcqirisDC440;
	aPacket->cmdHeader.cmdID		= aCmd;
	aPacket->cmdHeader.numberBytesinPayload	= sizeof(Acquiris_SetCmdStatusStruct);
	aPacket->message[0] = '\0';
	
	Acquiris_SetCmdStatusStruct* p = (Acquiris_SetCmdStatusStruct*)aPacket->payload;	
	p->status = status;	
	if(needToSwap)SwapLongBlock(p,sizeof(Acquiris_SetCmdStatusStruct)/sizeof(int32_t));
	writeBuffer(aPacket);
}

void sendStatus(SBC_Packet* aPacket, int32_t status)
{
	int32_t aCmd = aPacket->cmdHeader.cmdID;
	aPacket->cmdHeader.destination	= kAcqirisDC440;
	aPacket->cmdHeader.cmdID		= aCmd;
	aPacket->cmdHeader.numberBytesinPayload = sizeof(Acquiris_StatusStruct);
	aPacket->message[0] = '\0';
	
	Acquiris_StatusStruct* p = (Acquiris_StatusStruct*)aPacket->payload;	
	p->status = status;	
	if(needToSwap)SwapLongBlock(p,sizeof(Acquiris_StatusStruct)/sizeof(int32_t));
	writeBuffer(aPacket);
}


#define argd(a)		((ViReal64)atof(argv[a]))
#define argl(a)		atol(argv[a])

void processAcquirisDC440Command(SBC_Packet* aPacket)
{
	int32_t status;
	char *argv[32];
	ViInt32 i;
	char aString[kMaxAsciiCmdLength];
	switch(aPacket->cmdHeader.cmdID){		
		case kAcqiris_GetSerialNumbers:
			NumInstruments = 0;
			status = FindAcqirisDC440s();
			
			aString[0] = '\0';
			for (i = 0; i < NumInstruments; i++){
				sprintf(&aString[strlen(aString)],"%d,%d,%s,",digitizer[i].instrumentID,digitizer[i].serialNumber,digitizer[i].name);
			}
		
			aPacket->cmdHeader.destination	= kAcqirisDC440;
			aPacket->cmdHeader.cmdID		= kAcqiris_GetSerialNumbers;
			aPacket->cmdHeader.numberBytesinPayload   = sizeof(Acquiris_GetCmdStatusStruct);
			aPacket->message[0] = '\0';
			
			Acquiris_GetCmdStatusStruct* p = (Acquiris_GetCmdStatusStruct*)aPacket->payload;
			p->status = 0;
			if(needToSwap)SwapLongBlock(p,1); //just the first one, not the ascii
			strcpy(p->responseBuffer,aString);
			writeBuffer(aPacket);
			
		break;
		
		//the following are 'set' commands, they all return a single long status value
		case kAcqiris_SetConfigVertical:
			decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,6);
			status = AcqrsD1_configVertical(argl(0),argl(1),argd(2),argd(3),argl(4),argl(5));
			sendSetResponse(aPacket,status);
		break;

		case kAcqiris_SetConfigHorizontal:
			decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,3);
			status = AcqrsD1_configHorizontal(argl(0),argd(1),argd(2));
			sendSetResponse(aPacket,status);
		break;

		case kAcqiris_SetConfigMemory:
			decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,3);
			status = AcqrsD1_configMemory(argl(0),argl(1),argl(2));
			sendSetResponse(aPacket,status);
		break;
		
		case kAcqiris_SetConfigTrigClass:
			decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,7);
			status = AcqrsD1_configTrigClass(argl(0),argl(1),argl(2),argl(3),argl(4),argd(5),argd(6));
			sendSetResponse(aPacket,status);
		break;

		case kAcqiris_SetConfigTrigSource:
			decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,6);
			status = AcqrsD1_configTrigSource(argl(0),argl(1),argl(2),argl(3),argd(4),argd(5));
			sendSetResponse(aPacket,status);
		break;

		//the following are 'get' commands and return info in the Acqiris_Packet struct
		case kAcqiris_GetMemory:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				ViInt32 numberSamples,numberSegments;
				status = AcqrsD1_getMemory(argl(0),&numberSamples,&numberSegments);
				sprintf(aString,"%ld,%ld",numberSamples,numberSegments);
				sendGetResponse(aPacket,status,aString);
			}
		break;


		case kAcqiris_GetHorizontal:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				double sampleInterval,delayTime;
				status = AcqrsD1_getHorizontal(argl(0),&sampleInterval,&delayTime);
				sprintf(aString,"%G,%G",sampleInterval,delayTime);
				sendGetResponse(aPacket,status,aString);
			}
		break;

		case kAcqiris_GetVertical:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,2);
				ViReal64 fullScale,offset;
				ViInt32 coupling,bandwidth;
				status = AcqrsD1_getVertical(argl(0),argl(1),&fullScale,&offset,&coupling,&bandwidth);
				sprintf(aString,"%G,%G,%ld,%ld",fullScale,offset,coupling,bandwidth);
				sendGetResponse(aPacket,status,aString);
			}
		break;

		case kAcqiris_GetTrigSource:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,2);
				ViInt32 coupling,slope;
				ViReal64 level1,level2;
				status = AcqrsD1_getTrigSource(argl(0),argl(1),&coupling,&slope,&level1,&level2);
				sprintf(aString,"%ld,%ld,%G,%G",coupling,slope,level1,level2);
				sendGetResponse(aPacket,status,aString);
			}
		break;

		case kAcqiris_GetTrigClass:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				ViInt32 sourcePattern,trigClass,validatepattern,holdType;
				ViReal64 holdValue1,holdValue2;
				status = AcqrsD1_getTrigClass(argl(0),&trigClass,&sourcePattern,&validatepattern,&holdType,&holdValue1,&holdValue2);
				sprintf(aString,"%ld,%ld",trigClass,sourcePattern);
				sendGetResponse(aPacket,status,aString);
			}
		break;


		case kAcqiris_GetNbrChannels:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				ViInt32 numChannels;
				status = AcqrsD1_getNbrChannels(argl(0),&numChannels);
				sprintf(aString,"%ld",numChannels);
				sendGetResponse(aPacket,status,aString);
			}
		break;
		
		case kAcqiris_StartRun:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				status = AcqrsD1_acquire(argl(0)); // Start the acquisition
				sendStatus(aPacket,status);
			}
		break;
		
		case kAcqiris_StopRun:
			{
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				ViSession dev = argl(0);
				Stop(dev);
				status = 0;
				sendStatus(aPacket,status);
			}
		break;

		case kAcqiris_DataAvailable:
			{
				ViBoolean done = 0;
				decodeArgs(((Acquiris_AsciiCmdStruct*)aPacket->payload)->argBuffer,argv,1);
				status = AcqrsD1_acqDone(argl(0), &done);
				int32_t lDone = done;
				sendStatus(aPacket,lDone);
			}
		break;
		
		case kAcqiris_GetDataRequest:
			{
				Acquiris_ReadDataRequest* p = (Acquiris_ReadDataRequest*)aPacket->payload;
				if(needToSwap)SwapLongBlock(p,sizeof(Acquiris_ReadDataRequest)/sizeof(int32_t));
				Readout_DC440(p->boardID,p->numberSamples,p->enableMask,p->dataID,p->location,1,0); 
			}
		break;
		
		case kAcqiris_Get1WaveForm:
			{	
				Acquiris_ReadDataRequest* p = (Acquiris_ReadDataRequest*)aPacket->payload;
				printf("get1waveform for %d\n",p->boardID);
				if(Acquire (p->boardID)){
					Acquiris_ReadDataRequest* p = (Acquiris_ReadDataRequest*)aPacket->payload;
					if(needToSwap)SwapLongBlock(p,sizeof(Acquiris_ReadDataRequest)/sizeof(int32_t));
					Readout_DC440(p->boardID,p->numberSamples,p->enableMask,p->dataID,p->location,0,0); 
					AcqrsD1_stopAcquisition(p->boardID);
				}
				else {
					aPacket->cmdHeader.numberBytesinPayload = sizeof(Acquiris_WaveformResponseStruct);
					aPacket->cmdHeader.destination	= kAcqirisDC440;
					aPacket->cmdHeader.cmdID		= kAcqiris_DataReturn;
					//sprintf(aPacket->message,"empty waveform");
					Acquiris_WaveformResponseStruct* responsePtr = (Acquiris_WaveformResponseStruct*)aPacket->payload;
					responsePtr->numWaveformStructsToFollow = 0;
					writeBuffer(aPacket);
				}

			}
		break;
		
	}
}

char Acquire(ViSession dev)
{
	ViBoolean done		= 0;
	int32_t timeoutCounter = 50000;
	int32_t status = AcqrsD1_acquire(dev);					// Start the acquisition
	printf("Acquire on %d: status: %d\n",dev, status);

	while (!done && --timeoutCounter){
		status = AcqrsD1_acqDone(dev, &done);		// Poll for the end of the acquisition
		printf("AcqrsD1_acqDone %d: status: %d done: %d\n",dev, status, done);
	}
	if (timeoutCounter<=0){
		printf("Timeout on %ld\n",dev);
		AcqrsD1_stopAcquisition(dev);	// Acquisition do not complete successfully
	}
	return done;
}


//////////////////////////////////////////////////////////////////////////////////////////
void ClearAcqirisInitFlag(void)
{
	acqirisInitFlag = 0;
}

int32_t FindAcqirisDC440s(void)
{
// The following call will find the number of digitizers on the computer, regardless of
// their connection(s) to ASBus.
	ViStatus status = AcqrsD1_getNbrPhysicalInstruments(&NumInstruments);
	int32_t i;
	// Initialize the digitizers and setup a digitizer->ID array for ORCA
	for (i = 0; i < NumInstruments; i++){
		char resourceName[20];
		sprintf(resourceName, "PCI::INSTR%d", i);
		if(acqirisInitFlag){
			ViString options = "";
			AcqrsD1_InitWithOptions(resourceName, VI_FALSE, VI_FALSE, options, &(InstrumentID[i]));
			AcqrsD1_calibrate(InstrumentID[i]);
			acqirisInitFlag = 1;
		}
		ViChar name[20];
		ViInt32 serialNumber,busNumber,digitizerNumber;
		InstrumentID[i] = i;
		AcqrsD1_getInstrumentData(InstrumentID[i],name,&serialNumber,&busNumber,&digitizerNumber);
		strcpy(digitizer[i].name,(const char *)name);
		digitizer[i].busNumber		= busNumber;
		digitizer[i].serialNumber	= serialNumber;
		digitizer[i].instrumentID	= InstrumentID[i];
		printf("%d: %d %d %d\n",i, busNumber,serialNumber,InstrumentID[i]);
	}
	return status;	
}

void ReleaseAcqirisDC440s(void)
{
	int32_t i;
	for (i = 0; i < NumInstruments; i++){
		Stop(InstrumentID[i]);
	}
	if(NumInstruments)AcqrsD1_closeAll();
	acqirisInitFlag = 0;
}

char Arm(ViSession dev)
{
    ViStatus    status;
    char        bRetVal = true;
    
    // Make sure that acquisition is stopped - Do we need this check?
	if((status = AcqrsD1_stopAcquisition( dev ) ) != VI_SUCCESS ){
		bRetVal = false;
	}
    
    // Arm the digitizer
    if ( ( status = AcqrsD1_acquire( dev ) ) != VI_SUCCESS ){
        bRetVal = false;
    }
    
    return( bRetVal );
}

ViInt32 StopAcquisition (ViSession dev,int32_t aStopOption)
{
    ViStatus    status = 0;
    ViInt32     nbrSegmentsRead = 0;

 // Wait for the end of acquisition.  This call blocks until acquisition stops (or until timeout)
    if ( aStopOption & kWaitForEndOfAcq ){
        if ( AcqrsD1_waitForEndOfAcquisition( dev, ADcTimeout ) == ACQIRIS_ERROR_TIMEOUT ) {
            //AcqrsD1_stopAcquisition( dev );
			return 0;
        }
    }
    if ( aStopOption & kStopAcq ){
        status = AcqrsD1_stopAcquisition( dev );
        if ( status != VI_SUCCESS ) {
        }  
    }
    
 // Report number of segments acquired.
    if ( aStopOption & kGetNumSeg){
        status = AcqrsD1_reportNbrAcquiredSegments( dev, &nbrSegmentsRead );
        if ( status != VI_SUCCESS ){
        }
        else if ( nbrSegmentsRead > kMaxNbrSegments ){
			ViInt32  nbrSamples, nbrSegments;
			status = AcqrsD1_getMemory( dev, &nbrSamples, &nbrSegments );
			status = AcqrsD1_reportNbrAcquiredSegments( dev, &nbrSegmentsRead );
            nbrSegmentsRead = kMaxNbrSegments;
        }
	
    }
    
 // Stop the current acquisition.
    return( nbrSegmentsRead );
}


//////////////////////////////////////////////////////////////////////////////////////////

void StartUp(ViSession dev)
{
	Stop(dev);
	AcqrsD1_acquire(dev);			// Start the acquisition	
}

void Stop(ViSession dev)
{
	AcqrsD1_stopAcquisition(dev);
	AcqrsD1_forceTrig(dev);
	AcqrsD1_waitForEndOfAcquisition(dev, 100); //really should do some error checking here
}


//////////////////////////////////////////////////////////////////////////////////////////

