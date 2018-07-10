
#ifndef _H_SBC_JOB_
#define _H_SBC_JOB_

#include "SBC_Cmds.h"
#include <sys/types.h>
#include <stdint.h>
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

typedef struct {
	pthread_t		jobThreadId;	//job thread ID
	pthread_attr_t	jobThreadAttr;	//job thread attributes
	char			running;	//there can be only one
	char			killJobNow;		//set to 1 to stop early
	SBC_Packet		workingPacket;	//copy of the SBC packet for use by the job
	uint32_t		progress;		//number from 0 - 100%
	uint32_t		finalStatus;	//a success flag- 1=OK, 0=BAD
	char			message[256];
	
} SBC_JOB;

#endif
