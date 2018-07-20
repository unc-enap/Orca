//
//  ORWaveform.m
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

#import "ORWaveform.h"
#import "OR1dRoi.h"

NSString* ORWaveformUseUnsignedChanged   = @"ORWaveformUseUnsignedChanged";

@implementation ORWaveform

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [waveform release];
    waveform = nil;
 	[rois release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (BOOL) useUnsignedValues
{
	return useUnsignedValues;
}

- (void) setUseUnsignedValues:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseUnsignedValues:useUnsignedValues];
    useUnsignedValues = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORWaveformUseUnsignedChanged object:self];
}

- (int) unitSize
{
	return unitSize;
}

- (void) setUnitSize:(int)aUnitSize
{
    if(aUnitSize==0)aUnitSize = 1;
	unitSize = aUnitSize;
}

- (uint32_t) dataOffset
{
	return dataOffset;
}

- (void) setDataOffset:(uint32_t)newOffset
{
	dataOffset=newOffset;
}

-(uint32_t) numberBins
{
    if(waveform){
		[dataSetLock lock];
		uint32_t temp;
		if(unitSize == 0)unitSize = 1;
		temp =  (uint32_t)(([waveform length] - dataOffset)/unitSize);
		[dataSetLock unlock];
		return temp;
	}
    else return 64*1024;
}

-(int32_t) value:(uint32_t)aChan
{
  return [self value:aChan callerLockedMe:false];
}

-(int32_t) value:(uint32_t)aChan callerLockedMe:(BOOL)callerLockedMe
{
    double tempVal = 0;
    [self manyValues:NSMakeRange(aChan,1) to:&tempVal stride:1 callerLockedMe:callerLockedMe];
    return (int32_t)tempVal;
}

-(NSUInteger) manyValues:(NSRange)overRange to:(double*)output stride:(NSUInteger)stride callerLockedMe:(BOOL)callerLockedMe
{

#define FORLOOP(atype)              \
NSUInteger maxLength = (([waveform length] - dataOffset)/unitSize - overRange.location); \
NSUInteger maxRange =  (overRange.length >= maxLength) ?  maxLength : overRange.length;   \
const atype* cptr = (const atype*)[waveform bytes];         \
if (cptr != 0) {                                            \
    cptr += dataOffset/sizeof(atype);                       \
    NSUInteger j;                                           \
    for (j=0;j<maxRange;j+=stride) {                        \
        output[i] = cptr[j + overRange.location];           \
        i+=1;                                               \
    }                                                       \
}

    
#define MANYVALUERANGE(atype)    \
    case sizeof(atype):  {       \
        if (useUnsignedValues) { \
            FORLOOP(unsigned atype) \
        } else {                 \
            FORLOOP(atype)     \
        }                        \
        break;                   \
    }

    if(!callerLockedMe) [dataSetLock lock];
    NSUInteger i=0;
    switch(unitSize){
        MANYVALUERANGE(char)
        MANYVALUERANGE(short)
        MANYVALUERANGE(int)
        default: break;
    }
	if(!callerLockedMe) [dataSetLock unlock];
    return i;
}

- (double) getTrapezoidValue:(unsigned int)channel rampTime:(unsigned int)ramp gapTime:(unsigned int)gap
{
    // Average two regions of waveform, each of duration [ramp], separated
    // by a region of duration [gap], with the first region starting at
    // [channel], and return the difference divided by the ramp time.

    if(channel+2*ramp+gap >= [self numberBins]) return 0;

    [dataSetLock lock];
    double value = 0;
    unsigned int ch;
    for(ch = 0; ch < ramp; ch++) {
      value += [self value:(channel + ch + ramp + gap) callerLockedMe:true];
      value -= [self value:(channel + ch) callerLockedMe:true];
    }
    [dataSetLock unlock];

    return value / ramp;
}

#pragma mark ¥¥¥Data Management
- (void) clear
{
	[dataSetLock lock];
    [waveform release];
    waveform = nil;
	
    [self setTotalCounts:0];
	[dataSetLock unlock];
	
}

#pragma mark ¥¥¥Data Source Methods
- (id) name
{
    return [NSString stringWithFormat:@"%@ Waveform  Counts: %u",[self key], [self totalCounts]];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return (int)[self numberBins];
}

- (uint32_t) startingByteOffset:(id)aPlotter  dataSet:(int)set
{
	return dataOffset;
}

- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set
{
	return unitSize;
}

- (void) setWaveform:(NSData*)aWaveform
{
	[dataSetLock lock];
	
	if(![self paused]){
		[aWaveform retain];
		[waveform release];
		waveform = aWaveform;
    }
	
    if(aWaveform)[self incrementTotalCounts];
	[dataSetLock unlock];

}

- (NSData*) rawData
{
	NSData* theRawData;
	[dataSetLock lock];
	theRawData =  [waveform retain];
	[dataSetLock unlock];
	return [theRawData autorelease];
}

- (BOOL) canJoinMultiPlot
{
    return YES;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"ORWaveformController"];
}

#pragma mark ¥¥¥Archival
static NSString *ORWaveformDataOffset 	= @"Waveform Data Offset";
static NSString *ORWaveformUnitSize 	= @"Waveform Data Unit Size";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setDataOffset:(int32_t)[decoder decodeIntegerForKey:ORWaveformDataOffset]];
    [self setUnitSize:[decoder decodeIntForKey:ORWaveformUnitSize]];
    [self setUseUnsignedValues:[decoder decodeBoolForKey:@"UseUnsignedValues"]];
	rois = [[decoder decodeObjectForKey:@"rois"] retain];
    [[self undoManager] enableUndoRegistration];
	 
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:dataOffset forKey:ORWaveformDataOffset];
    [encoder encodeInteger:unitSize forKey:ORWaveformUnitSize];
    [encoder encodeBool:useUnsignedValues forKey:@"UseUnsignedValues"];
    [encoder encodeObject:rois forKey:@"rois"];

}

#pragma mark ¥¥¥Data Source
- (NSMutableArray*) rois
{
	if(!rois){
		rois = [[NSMutableArray alloc] init];
		[rois addObject:[[[OR1dRoi alloc] initWithMin:20 max:30] autorelease]];
	}
	return rois;
}

- (int) numberPointsInPlot:(id)aPlot
{
	return (int)[self numberBins];
}

- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y
{
    [x setLength:aRange.length*sizeof(double)];
    [y setLength:aRange.length*sizeof(double)];
    NSUInteger numCopied = [self manyValues:aRange to:(double *)[y bytes] stride:stride callerLockedMe:NO];
    NSUInteger i;
    double *ptr = (double*)[x bytes];
    for(i=0;i<numCopied;i++) {
        ptr[i] = i*stride+aRange.location;
    }
    [x setLength:numCopied*sizeof(double)];
    [y setLength:numCopied*sizeof(double)];
    return numCopied;
}


- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y
{
	*y =  [self value:index];
	*x = index;
}

//subclasses will override these
- (uint32_t) mask
{
	return 0;
}
- (uint32_t) specialBitMask
{
	return 0;
}

@end

