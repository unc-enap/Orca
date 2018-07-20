//
//  ORPlotFFT.m
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#import "ORPlotFFT.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"

NSString* ORPlotFFTShowChanged = @"ORPlotFFTShowChanged";

@implementation ORPlotFFT

- (id) init 
{
    self = [super init];
	dataLock = [[NSRecursiveLock alloc] init];
    return self;    
}



- (void) dealloc
{
	[realArray release];
	[imaginaryArray release];
	[powerSpectrumArray release];
	[dataLock release];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors
- (NSUInteger) numberChans
{
	return [realArray count];
}

#pragma mark ¥¥¥Data Management
-(void)clear
{
	[dataSetLock lock];
	[realArray release];
	[imaginaryArray release];
	[powerSpectrumArray release];
	powerSpectrumArray = nil;
	realArray = nil;
	imaginaryArray = nil;
    [self setTotalCounts:0];
	[dataSetLock unlock];
}

- (NSArray*) powerSpectrumArray
{
	return powerSpectrumArray;
}

- (void) setPowerSpectrumArray:(NSArray*)anArray
{
	[dataLock lock];
	[anArray retain];
	[powerSpectrumArray release];
	powerSpectrumArray = anArray;
	[dataLock unlock];
}

- (NSArray*) realArray
{
	return realArray;
}

- (void) setRealArray:(NSArray*)aaRealArray imaginaryArray:(NSArray*)anImaginaryArray
{
	[dataLock lock];
	[aaRealArray retain];
	[realArray release];
	realArray = aaRealArray;
	[anImaginaryArray retain];
	[imaginaryArray release];
	imaginaryArray = anImaginaryArray;
	int i;
	int n = (int)[imaginaryArray count];
	NSMutableArray* array = [NSMutableArray array];
	for(i=0;i<n;i++){
		float r = [[realArray objectAtIndex:i] floatValue];
		float ii = [[imaginaryArray objectAtIndex:i] floatValue];
		[array addObject:[NSNumber numberWithFloat:(r*r)+(ii*ii)]];
	}
	[self setPowerSpectrumArray:array];
    if(aaRealArray || anImaginaryArray)[self incrementTotalCounts];
	[dataLock unlock];
}

- (void) incrementTotalCounts
{
	[super incrementTotalCounts];
}

- (BOOL) showReal
{
	return showReal;
}

- (void) setShowReal:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowReal:showReal];
	showReal = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPlotFFTShowChanged object:self];
}

- (BOOL) showImaginary
{
	return showImaginary;
}

- (void) setShowImaginary:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowImaginary:showImaginary];
	showImaginary = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPlotFFTShowChanged object:self];
}

- (BOOL) showPowerSpectrum
{
	return showPowerSpectrum;
}

- (void) setShowPowerSpectrum:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowPowerSpectrum:showPowerSpectrum];
	showPowerSpectrum = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPlotFFTShowChanged object:self];
}

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
/*	[dataSetLock lock];
    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
    int i;
    for (i=0; i<numberBins; ++i) {
        fprintf(aFile, "%d\n",histogram[i]);
    }
    fprintf(aFile, "END\n\n");
	[dataSetLock unlock];
*/
}

- (int)	numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
	if(set == 0) return (int)(showReal?[realArray count]:0);
	else if(set==1)return (int)(showImaginary?[imaginaryArray count]:0);
	else return (int)(showPowerSpectrum?[powerSpectrumArray count]:0);
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	[dataLock lock];
	int set = (int)[aPlotter tag];
	if(set==0){
		*yValue = [[realArray objectAtIndex:i] floatValue];
		*xValue = i;
	}
    else if(set==1){
		*yValue =  [[imaginaryArray objectAtIndex:i] floatValue];
		*xValue = i;
	}
    else {
		*yValue =  [[powerSpectrumArray objectAtIndex:i] floatValue];
		*xValue = i;
	}
	[dataLock unlock];
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	[dataLock lock];
    @try{
        if(set==0)      return [[realArray objectAtIndex:x] floatValue];
        else if(set==1) return [[imaginaryArray objectAtIndex:x] floatValue];
        else            return [[powerSpectrumArray objectAtIndex:x] floatValue];
    }
    @catch(NSException*e){
        
    }
    @finally
    {
        [dataLock unlock];
    }
}

- (NSColor*) colorForDataSet:(int)set
{
    if(set==0) return [NSColor blueColor];
	else if(set==1)return [NSColor redColor];
	else return [NSColor blackColor];
}

- (void) processResponse:(NSDictionary*)aResponse
{
	[dataSet processResponse:aResponse];
}

#pragma mark ¥¥¥Data Source Methods

- (id)   name
{
    return [NSString stringWithFormat:@"%@ FFT Counts: %u",[self key], [self totalCounts]];
}

- (BOOL) canJoinMultiPlot
{
    return NO;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"ORPlotFFTController"];
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	dataLock = [[NSRecursiveLock alloc] init];
	[self setShowReal:[decoder decodeBoolForKey:@"showReal"]];
	[self setShowImaginary:[decoder decodeBoolForKey:@"showImaginary"]];
	[self setShowPowerSpectrum:[decoder decodeBoolForKey:@"showPowerSpectrum"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:showReal forKey:@"showReal"];
	[encoder encodeBool:showImaginary forKey:@"showImaginary"];
	[encoder encodeBool:showPowerSpectrum forKey:@"showPowerSpectrum"];
}


@end
