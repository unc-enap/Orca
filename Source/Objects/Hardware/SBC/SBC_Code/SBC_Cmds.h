
/*---------------------------------------------------------------------------
/    SBC_Cmds.h
/  command protocol for the PCI controller
/
/    02/21/06 Mark A. Howe
/    CENPA, University of Washington. All rights reserved.
/    ORCA project
/  ---------------------------------------------------------------------------
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

#ifndef _H_SBCCMDS_
#define _H_SBCCMDS_

#include <sys/types.h>
#include <stdint.h>
#include "SBC_Config.h"

#define kNoReply 0
#define kReply	 1

/*destinations*/
#define kSBC_Process           0x1
#define kAcqirisDC440          0x2
#define kSNO				   0x3
#define kPMC				   0x4
#define kMJD                   0x5
#define kKATRIN                0x6

/* SBC commands */
#define kSBC_Command           0x01
#define kSBC_ReadBlock         0x02
#define kSBC_WriteBlock        0x03
#define kSBC_LoadConfig        0x04
#define kSBC_RunInfoRequest    0x05
#define kSBC_DataBlock         0x06
#define kSBC_AcqirisDC440Cmd   0x07
#define kSBC_CBBlock           0x08
#define kSBC_StartRun          0x0a
#define kSBC_StopRun           0x0b
#define kSBC_CBRead            0x0c
#define kSBC_ConnectionStatus  0x0d
#define kSBC_LAM			   0x10
#define kSBC_CBTest			   0x11
#define kSBC_PacketOptions	   0x12
#define kSBC_KillJob		   0x13
#define kSBC_JobStatus		   0x14
#define kSBC_CmdBlock		   0x15
#define kSBC_TimeDelay		   0x16
#define kSBC_PauseRun          0x17
#define kSBC_ResumeRun         0x18
#define kSBC_GeneralRead       0x19
#define kSBC_GeneralWrite      0x20
#define kSBC_SetPollingDelay   0x21
#define kSBC_ErrorInfoRequest  0x22
#define kSBC_GenericJob        0x23
#define kSBC_MacAddressRequest 0x24
#define kSBC_GetTimeRequest    0x25
#define kSBC_GetAccurateTime   0x26

#define kSBC_Exit              0xFFFFFFFF /*close socket and quit application*/

typedef 
    struct {
        uint32_t destination;    /*should be kSBC_Command*/  /*or kSBC_Process ? -tb- */
        uint32_t cmdID;
        uint32_t numberBytesinPayload;
    }
SBC_CommandHeader;

typedef 
    struct {
        uint32_t milliSecondDelay;
    }
SBC_TimeDelay;

typedef 
    struct {
        uint32_t unixTime;
    }
SBC_time_struct;

typedef
    struct {
        uint32_t seconds;
        uint32_t microSeconds;
    }
SBC_accurate_time_struct;

typedef
    struct {
        SBC_info_struct runInfo;
    }
SBC_RunInfo;

typedef
    struct {
        SBC_error_struct errorInfo;
    }
SBC_ErrorInfo;


#define kMaxOptions 10
typedef 
    struct {
        uint32_t option[kMaxOptions];
    }
SBC_CmdOptionStruct;

typedef 
    struct {
        uint32_t address;        /*first address*/
        uint32_t numLongs;        /*number of longs to read*/
    }
SBC_ReadBlockStruct;

typedef 
    struct {
        uint32_t address;        /*first address*/
        uint32_t numLongs;        /*number Longs of data to follow*/
        /*followed by the requested data, number of longs from above*/
    }
SBC_WriteBlockStruct;

typedef 
    struct {
        uint32_t address;        /*first address*/
        uint32_t addressModifier;
        uint32_t addressSpace;
        uint32_t unitSize;        /*1,2,or 4*/
        uint32_t errorCode;    /*filled on return*/
        uint32_t numItems;        /*number of items to read*/
    }
SBC_VmeReadBlockStruct;

typedef 
    struct {
        uint32_t address;        /*first address*/
        uint32_t addressModifier;
        uint32_t addressSpace;
        uint32_t unitSize;        /*1,2,or 4*/
        uint32_t errorCode;    /*filled on return*/
        uint32_t numItems;        /*number Items of data to follow*/
        /*followed by the requested data, number of items from above*/
    }
SBC_VmeWriteBlockStruct;

typedef 
    struct {
        uint32_t address;        /*first address*/
        int32_t errorCode;    /*filled on return*/
        uint32_t numItems;        /*number Items of data to follow*/
        /*followed by the requested data, number of items from above*/
    }
SBC_IPEv4WriteBlockStruct;

typedef 
    struct {
        uint32_t address;        /*first address*/
        int32_t errorCode;     /*filled on return*/
        uint32_t numItems;        /*number of items to read*/
    }
SBC_IPEv4ReadBlockStruct;

typedef 
    struct {
        char numToAck;        /*a total count*/
        /*followed the slot numbers of the lams to Ack (bytes)*/
    }
SBC_LamAckStruct;

typedef 
    struct {
        char	 label[32];
		uint32_t data;
    }
SBC_LabeledData;

typedef 
    struct {
		uint32_t lamNumber;
        uint32_t numFormatedWords;
		uint32_t formatedWords[256];
		uint32_t numberLabeledDataWords;
		SBC_LabeledData labeledData[256];
    }
SBC_LAM_Data;


#define kSBC_MaxPayloadSizeBytes    2*1024*1024
#define kSBC_MaxMessageSizeBytes    256
typedef 
    struct {
        uint32_t numBytes;                //filled in automatically
        SBC_CommandHeader cmdHeader;
        char message[kSBC_MaxMessageSizeBytes];
        char payload[kSBC_MaxPayloadSizeBytes];
    }
SBC_Packet;

#define kMaxNumberLams		 7
#define kSBC_LAM_Busy		 1
#define kSBC_LAM_Open		 1
typedef 
	struct {
		char isWaitingForAck;
		char isValid;
		SBC_Packet lam_Packet;
	} 
SBC_LAM_info_struct;

//---------------------

typedef 
    struct {
		uint32_t running;		//1==yes, 0==no
		uint32_t finalStatus;   //has meaning only if the job is done
		uint32_t progress;		//0-100%
    }
SBC_JobStatusStruct;

//---------------------

typedef
    struct {
         uint32_t readIndex;
         uint32_t writeIndex;
         uint32_t lostByteCount;
         uint32_t amountInBuffer;
         uint32_t wrapArounds;
    }
BufferInfo;

typedef
    struct {
        uint8_t macAddress[8];
    }
SBC_MAC_AddressStruct;

#endif
