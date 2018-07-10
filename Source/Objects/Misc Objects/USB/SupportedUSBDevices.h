/*
 *  SupportedUSBDevices.h
 *  Orca
 *
 *  Created by Mark Howe on 11/7/08.
 *  Copyright 2008 University of North Carolina. All rights reserved.
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

//If adding a device, don't forget to increment the following
#define kNumberSupportedDevices 15

static struct supportedUSbDevices {
	unsigned long vendorID;
	unsigned long productID;
	NSString*	  modelName;
} supportedUSBDevice[kNumberSupportedDevices] = {
	{ 0x0957,	0x0407,	@"ORPulser332220Model"	},
	{ 0x16DC,	0x1,	@"ORCCUSBModel"			},
	{ 0x0a07,	0x00C8,	@"ORADU200Model"		},
	{ 0x0403,	0x6001,	@"ORUSBtoBPICModel"		},
	{ 0x041F,	0x1207,	@"ORLDA102Model"		},
	{ 0x0A2D,	0x0019,	@"MCA927"				},
	{ 0x0CD5,	0x0001,	@"LabJack"				},
	//{ 0x0CD5,	0x0009,	@"LabJackUE9"			},
	{ 0x1657,	0x3150,	@"SIS3150"				},
    { 0x0957,	0x2307,	@"ORPulser33500Model"	},
    { 0x0957,	0x2C07,	@"ORPulser33500Model"	},
	{ 0x1fb9,	0x301,	@"ORLakeShore336"       },
    { 0x21E1,	0x0,	@"ORDT5720Model"        },
    { 0x21E1,   0x0,    @"ORDT5725Model"        },
    { 0x0699,   0x036a, @"ORTDS2024Model"       },
    { 0x0699,   0x03a2, @"ORTDS2004Model"       }
    //If adding a device, don't forget to increment kNumberSupportedDevices above...
};

