/*
 *  Sno_Monitor_Adcs.h
 *  Orca
 *
 *  Created by Mark Howe on 12/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
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

#define  kNumFecMonitorAdcs	 21
#define  kTemperatureADC	9	// index of temperature ADC

typedef enum eFecMonitorState {
	kFecMonitorNeverMeasured,
	kFecMonitorInRange,
	kFecMonitorOutOfRange,
	kFecMonitorReadError
} eFecMonitorState;

static const struct  {
	unsigned short	mask;
	bool			check_expected_value;
	float			error_delta; 
	float			multiplier;
	float			expected_value;
	char*			label;
	char*			units;
} fecVoltageAdc[kNumFecMonitorAdcs] = {
	{0x0000,	false, 	0.3,	0.039, 	0.0,	"HV Curr",		"mA"},
	{0x0200,	true,	0.3,	0.039, 	-1.0,	"-1.0V Ref",	"V"},
	{0x0400,	true,	0.3,	0.039, 	-2.0,	"-2.0V Ref",	"V"},
	{0x0600,	true,	0.3,	0.039, 	-3.3,	"-3.3V Sup",	"V"},
	{0x0800,	true,	0.3,	0.192, 	-5.2,	"-5.2V Sup",	"V"},
	{0x0A00,	true,	0.3,	0.039, 	-2.0,	"-2.0V Sup",	"V"},
	{0x0C00,	true,	0.3,	0.192, 	-15.0,	" -15V Sup",	"V"},
	{0x0E00,	true,	0.3,	0.339, 	-24.0,	" -24V Sup",	"V"},
	{0x2000,	false,	0.3,	0.039, 	0.0,	"Cal. DAC",		"V"},
	{0x2200,	true,	0.5,	0.650, 	35.0,	"Temp",			"C"},
	{0x2400,	true,	0.3,	0.039, 	0.8,	" 0.8V Ref",	"V"},
	{0x2600,	true,	0.3,	0.039, 	1.0,	" 1.0V Ref",	"V"},
	{0x2800,	true,	0.3,	0.039, 	3.3,	" 3.3V Sup",	"V"},
	{0x2A00,	true,	0.3,	0.039, 	4.0,	" 4.0V Ref",	"V"},
	{0x2C00,	true,	0.3,	0.039, 	4.0,	" 4.0V Sup",	"V"},
	{0x2E00,	true,	0.3,	0.192, 	5.0,	" 5.0V Ref",	"V"},
	{0x3000,	true,	0.3,	0.192, 	8.0,	" 8.0V Sup",	"V"},
	{0x3200,	true,	0.3,	0.192, 	15.0,	"  15V Sup",	"V"},
	{0x3400,	true,	0.3,	0.339, 	24.0,	"  24V Sup",	"V"},
	{0x3600,	true,	0.3,	0.192, 	5.0,	"   5V Sup",	"V"},
	{0x3800,	true,	0.3,	0.192, 	6.5,	" 6.5V Sup",	"V"}
};

static const unsigned short groundMask = 0x0A00;


