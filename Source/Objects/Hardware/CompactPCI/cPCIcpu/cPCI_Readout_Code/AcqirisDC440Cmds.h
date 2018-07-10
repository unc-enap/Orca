//-----------------------------------------------------------
//  AcqirisDC440Cmds.h
//  OrcaIntel
//  Created by Mark Howe on 6/26/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#ifndef _H_ACQIRISDC440CMDS_
#define _H_ACQIRISDC440CMDS_
#include <sys/types.h>
#include <stdint.h>

#define kAcqiris_GetSerialNumbers		0x01
#define kAcqiris_SetConfigVertical		0x02
#define kAcqiris_SetConfigHorizontal	0x03
#define kAcqiris_SetConfigMemory		0x04
#define kAcqiris_SetConfigTrigClass		0x05
#define kAcqiris_SetConfigTrigSource	0x06
#define kAcqiris_GetHorizontal			0x07
#define kAcqiris_GetVertical			0x08
#define kAcqiris_GetMemory				0x09
#define kAcqiris_GetNbrChannels			0x0A
#define kAcqiris_GetTrigSource			0x0B
#define kAcqiris_StartRun				0x0C
#define kAcqiris_StopRun				0x0D
#define kAcqiris_DataAvailable			0x0E
#define kAcqiris_GetDataRequest			0x0F
#define kAcqiris_Get1WaveForm			0x10
#define kAcqiris_DataReturn				0x11
#define kAcqiris_GetTrigClass			0x12
#define kMaxAsciiCmdLength 256

typedef 
	struct {
		char argBuffer[kMaxAsciiCmdLength];
	}
Acquiris_AsciiCmdStruct;

#define kMaxAsciiCmdLength 256
typedef 
	struct {
		int32_t status;
		char responseBuffer[kMaxAsciiCmdLength];
	}
Acquiris_GetCmdStatusStruct;

typedef 
	struct {
		int32_t status;
	}
Acquiris_SetCmdStatusStruct;

typedef 
	struct {
		int32_t status;
	}
Acquiris_StatusStruct;

//special struct for requesting data.
typedef 
	struct {
		uint32_t boardID;
		uint32_t numberSamples;
		uint32_t dataID;	
		uint32_t location;
		uint32_t enableMask;	
	}
Acquiris_ReadDataRequest;

//special struct for requesting data.
typedef 
	struct {
		int32_t hitMask;
		int32_t numWaveformStructsToFollow;
	}
Acquiris_WaveformResponseStruct;

typedef 
	struct {
		int32_t orcaHeader;
		int32_t location;
		int32_t timeStampLo;
		int32_t timeStampHi;
		int32_t offsetToValidData;
		int32_t numShorts;
		//followed by a number of bytes
	}
Acquiris_OrcaWaveformStruct;


typedef 
	struct {
		uint32_t numLongs;		/*number Longs of data to follow*/
		/*followed by the requested data, number of longs from above*/
	}
Acquiris_RecordBlockStruct;


#endif
