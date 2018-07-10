//
//  ORXYFit.m
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

#import "ORXYFit.h"
#import "ORCARootServiceDefs.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"

@implementation ORXYFit

- (id) init
{
	self = [super init];
	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
	return self;
}

#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if( ![ds respondsToSelector:@selector(plotter:index:x:y:)] || 
	    ![ds respondsToSelector:@selector(numberPointsInPlot:)]){
		ds = nil;
	}
	dataSource = ds; // Don't retain to avoid cycle retention problems
}

- (void) doFit
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
	id roi = [aPlot roi];
	
	[self setMinChannel:[roi minChannel]];
	[self setMaxChannel:[roi maxChannel]+1];
	
	BOOL roiVisible = [dataSource plotterShouldShowRoi:aPlot];
	if(roiVisible){
		//get the data for the fit
		NSMutableArray* dataArray = [NSMutableArray array];
		int numPoints = [dataSource numberPointsInPlot:aPlot];
		long maxChan = MIN([self maxChannel],numPoints-1);
		int ix;
		for (ix=0; ix<=maxChan;++ix) {	
			double x,y;
			[dataSource plotter:aPlot index:ix x:&x y:&y];
			NSLog(@"%f %f\n",x,y);
			[dataArray addObject:[NSNumber numberWithDouble:y]];
		}
		
		[fitParams release];	
		[fitParamNames release];
		[fitParamErrors release];
		[chiSquare release];
		
		fitParams		= nil;	
		fitParamNames	= nil;
		fitParamErrors	= nil;
		chiSquare		= nil;
		fitValid		= NO;
			
		if([dataArray count]){
			NSMutableDictionary* serviceRequest = [NSMutableDictionary dictionary];
			[serviceRequest setObject:@"OROrcaRequestFitProcessor" forKey:@"Request Type"];
			[serviceRequest setObject:@"Normal"					 forKey:@"Request Option"];
			
			NSMutableDictionary* requestInputs = [NSMutableDictionary dictionary];

			[requestInputs setObject:[NSNumber numberWithInt:minChannel] forKey:@"FitLowerBound"];
			[requestInputs setObject:[NSNumber numberWithInt:maxChannel] forKey:@"FitUpperBound"];	
			
			NSString* 	theFitFunction = kORCARootFitShortNames[fitType];
			
			if([theFitFunction hasPrefix:@"arb"]){
				theFitFunction = [[fitFunction copy] autorelease];
			}
			else if([theFitFunction hasPrefix:@"pol"]){
				theFitFunction = [theFitFunction stringByAppendingFormat:@"%d",fitOrder];
			}

			[requestInputs setObject:theFitFunction	 forKey:@"FitFunction"];
			[requestInputs setObject:[NSArray array] forKey:@"FitParameters"];
			[requestInputs setObject:@""			 forKey:@"FitOptions"];
			[requestInputs setObject:dataArray		 forKey:@"FitYValues"];
			
			[serviceRequest setObject:requestInputs	forKey:@"Request Inputs"];
			
			//we do this via a notification so that this object (which is a widget) is decoupled from the ORCARootService object.
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:serviceRequest forKey:ServiceRequestKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceRequestNotification object:self userInfo:userInfo];
		}
	}
}



@end
