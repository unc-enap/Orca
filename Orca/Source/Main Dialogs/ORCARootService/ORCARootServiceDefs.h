/*
 *  ORCARootServiceDefs.h
 *  Orca
 *
 *  Created by Mark Howe on 4/26/07.
 *  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#define ORCARootServiceRequestNotification	@"ORCARootServiceRequestNotification"
#define ORCARootServiceCancelRequest		@"ORCARootServiceCancelRequest"
#define ORCARootServiceConnectedKey			@"ORCARootServiceConnectedKey"
#define ORCARootServiceFitFunctionKey		@"ORCARootServiceFitFunctionKey"
#define ORCARootServiceFitOrderKey			@"ORCARootServiceFitOrderKey"
#define ORCARootServiceFitFunction			@"ORCARootServiceFitFunction"
#define ServiceRequestKey					@"ServiceRequestKey"
#define ORCARootServiceConnectionChanged	@"ORCARootServiceConnectionChanged"
#define ORCARootServiceFFTOptionKey			@"ORCARootServiceFFTOptionKey"
#define ORCARootServiceBroadcastConnection  @"ORCARootServiceBroadcastConnection"
#define ORCARootServiceReponseNotification  @"ORCARootServiceReponseNotification"
#define ORCARootServiceTitleKey				@"ORCARootServiceTitleKey"
#define ORCARootServiceResponseKey			@"ORCARootServiceResponseKey"
#define ORCARootServiceFFTWindowKey			@"ORCARootServiceFFTWindowKey"

#define kNumORCARootFitTypes 5
static NSString* kORCARootFitNames[kNumORCARootFitTypes] = {
	@"gaussian",
	@"exponential",
	@"polynomial",
	@"landau",
	@"arbitrary"
};

static NSString* kORCARootFitShortNames[kNumORCARootFitTypes] = {
	@"gaus",
	@"expo",
	@"pol",
	@"landau",
	@"arbitrary"

};

#define kNumORCARootFFTOptions 4 
static NSString* kORCARootFFTNames[kNumORCARootFFTOptions] = {
	@"ES",
	@"M",
	@"P",
	@"EX"
};

#define kNumORCARootFFTWindows 3
static NSString* kORCARootFFTWindowOptions[kNumORCARootFFTWindows] = {
	@"",
	@"WinBlack",
	@"WinHamm",
};

static NSString* kORCARootFFTWindowNames[kNumORCARootFFTWindows] = {
	@"None",
	@"Blackman",
	@"Hamming",
};

#define RemoveORCARootWarnings { 	\
			if(kORCARootFitNames[0] != nil){} \
			if(kORCARootFFTNames[0] != nil){} \
			if(kORCARootFitShortNames[0] != nil){} \
			if(kORCARootFFTWindowOptions[0] != nil){} \
			if(kORCARootFFTWindowNames[0] != nil){}\
} 
