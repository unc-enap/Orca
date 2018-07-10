//
//  ORFFT.m
//  Orca
//
//  Created by Mark Howe on 2/13/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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

#import "ORFFT.h"
#import "ORCARootServiceDefs.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"

NSString* ORFFTWindowChanged = @"ORFFTWindowChanged";
NSString* ORFFTOptionChanged = @"ORFFTOptionChanged";
	
@implementation ORFFT

#pragma mark ***Initialization
- (id) init
{
	self = [super init];
	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if( ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	dataSource = ds; // Don't retain to avoid cycle retention problems
}

- (id) dataSource					{ return dataSource; }

- (long) minChannel					{ return minChannel; }
- (long) maxChannel					{ return maxChannel; }
- (BOOL) serviceAvailable			{ return serviceAvailable;}
- (int) fftOption					{ return fftOption;}
- (int) fftWindow					{ return fftWindow;}

- (void) setMinChannel:(long)aChannel 
{ 
	minChannel = aChannel; 
}

- (void) setMaxChannel:(long)aChannel 
{ 
	maxChannel = aChannel; 
}

- (void) setFftWindow:(int)aValue
{ 
	fftWindow = aValue; 
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFFTWindowChanged object:self];
}

- (void) setFftOption:(int)aValue
{
	fftOption = aValue; 
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFFTOptionChanged object:self];
}

- (void) doFFT
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
	id roi = [aPlot roi];
	
	BOOL roiVisible = [dataSource plotterShouldShowRoi:aPlot];
	if(roiVisible){
		NSMutableArray* dataArray = [NSMutableArray array];
		long minChan = [roi minChannel];
		long maxChan = [roi maxChannel];
		int ix;
		for (ix=minChan; ix<maxChan-1;++ix) {		
			double xValue,yValue;
			[dataSource plotter:aPlot index:ix x:&xValue y:&yValue];
			[dataArray addObject:[NSNumber numberWithDouble:yValue]];
		}
	
		if([dataArray count]){
			NSMutableDictionary* serviceRequest = [NSMutableDictionary dictionary];
			[serviceRequest setObject:@"OROrcaRequestFFTProcessor" forKey:@"Request Type"];
			[serviceRequest setObject:@"Normal"					 forKey:@"Request Option"];
			
			NSMutableDictionary* requestInputs = [NSMutableDictionary dictionary];
			[requestInputs setObject:dataArray forKey:@"Waveform"];
			NSString* fftOptionString = kORCARootFFTNames[fftOption];
			int i = fftWindow;
			if(i>0){
				fftOptionString = [fftOptionString stringByAppendingString:@","];
				fftOptionString = [fftOptionString stringByAppendingString:kORCARootFFTWindowOptions[i]];
			}
			[requestInputs setObject:fftOptionString forKey:@"FFTOptions"];
			
			[serviceRequest setObject:requestInputs	forKey:@"Request Inputs"];
			
			//we do this via a notification so that this object (which is a widget) is decoupled from the ORCARootService object.
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:serviceRequest forKey:ServiceRequestKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceRequestNotification object:self userInfo:userInfo];
		}
	}
}

- (void) processResponse:(NSDictionary*)aResponse
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	BOOL responseOK = ([aResponse objectForKey:@"Request Error"] == nil);
	if(responseOK){
		if([[aResponse objectForKey:@"Request Type"] isEqualToString:@"OROrcaRequestFFTProcessor"]) {
			NSMutableDictionary* reponseInfo = [NSMutableDictionary dictionaryWithObject:aResponse forKey:ORCARootServiceResponseKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceReponseNotification object:self userInfo:reponseInfo];
		}
	}
	else {
		NSLog(@"----------------------------------------\n");
		NSLog(@"Error returned for FFT on %@\n",[[aPlotView window] title]);
		NSLog(@"Error message: %@\n",[aResponse objectForKey:@"Request Error"]);
		if([[aResponse objectForKey:@"Request Type"] isEqualToString:@"OROrcaRequestFFTProcessor"]){
			NSLog(@"Check the ROOT installation: --it appears that it was not compiled with fftw support\n");
		}
		NSLog(@"----------------------------------------\n");
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    		
    [self setMinChannel:	[decoder decodeInt32ForKey:@"minChannel"]];
    [self setMaxChannel:	[decoder decodeInt32ForKey:@"maxChannel"]];
	[self setFftOption:		[decoder decodeIntForKey:@"fftOption"]];
	[self setFftWindow:		[decoder decodeIntForKey:@"fftWindow"]];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt32:minChannel forKey:@"minChannel"];
    [encoder encodeInt32:maxChannel forKey:@"maxChannel"];
	[encoder encodeInt:fftOption forKey:@"fftOption"];
    [encoder encodeInt:fftWindow forKey:@"fftWindow"];
}
@end
