//
//  ORWaveformSpecialBitsController.m
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import "ORMaskedWaveform.h"
#import "ORPlotView.h"
#import "ORBitStrip.h"
#import "ORWaveformSpecialBitsController.h"

@implementation ORWaveformSpecialBitsController

#pragma mark ¥¥¥Initialization
- (void) awakeFromNib
{
    [super awakeFromNib];
	
	int i;
	NSArray* bitNames = [[(ORMaskedIndexedWaveformWithSpecialBits*)model bitNames] retain];
	for(i=0;i<[model numBits];i++){
		ORBitStrip* aPlot = [[ORBitStrip alloc] initWithTag:1+i andDataSource:self];
		if(i<[bitNames count]) [aPlot setBitName:[bitNames objectAtIndex:i]];
		[aPlot setBitNum:i];
		[aPlot setLineColor:[NSColor blueColor]];
		[plotView addPlot: aPlot];
		[aPlot release];
	}
	[bitNames release];
 
}

#pragma mark ¥¥¥Data Source
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y
{
    int thePlotTag = [aPlot tag];
	if(thePlotTag == 0){
		unsigned long aMask =  [(ORMaskedIndexedWaveformWithSpecialBits*)model mask];
		*y =  ([model value:index] & aMask) + [model scaleOffset];
		*x = index;
	}
	else {
		int bit;
        unsigned long aMask =  [model firstBitMask];
		for(bit=0;bit<[model numBits];bit++){
			if(thePlotTag == bit+1){
 				unsigned long aValue = [model value:index];
				*y =  ((aValue & (aMask << bit)))!=0;
				*x = index;
				break;
			}
		}
	}
}

//#if 0
//2017-02-15 -tb- commented out to force using the 'slow' plotting methods (required to take the offset index into account

- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y
{
    NSUInteger length = [model plotter:aPlot indexRange:aRange stride:stride x:x y:y];
    if (length == 0) return length;
    double* yptr = (double*)[y bytes];
    NSUInteger i;
    if ([aPlot tag] == 0) {
		unsigned long aMask =  [(ORMaskedIndexedWaveformWithSpecialBits*)model mask];
        long scaleOffset = [model scaleOffset];
        for (i=0;i<length;i++) {
            yptr[i] = (((long)yptr[i]) & aMask) + scaleOffset;
        }
    } else {
		int bit;
		for(bit=0;bit<[model numBits];bit++){
			if([aPlot tag] == bit+1){
				unsigned long aMask =  [model firstBitMask];
                for (i=0;i<length;i++) {
                    yptr[i] = (((long)yptr[i]) & (aMask << bit)) != 0;
                }
				break;
			}
		}
    }
    return length;
}
//#endif

@end
