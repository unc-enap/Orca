//
//  ORManualPlot2DModel.m
//  Orca
//
//  Created by Mark Howe on Fri Mar 23,2012.
//  Copyright (c) 2012  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORManualPlot2DModel.h"
#import "OR2dRoi.h"

NSString* ORManualPlot2DLock					= @"ORManualPlot2DLock";
NSString* ORManualPlot2DDataChanged				= @"ORManualPlot2DDataChanged";
NSString* ORManualPlot2DModelXTitleChanged		= @"ORManualPlot2DModelXTitleChanged";
NSString* ORManualPlot2DModelYTitleChanged		= @"ORManualPlot2DModelYTitleChanged";
NSString* ORManualPlot2DModelPlotTitleChanged	= @"ORManualPlot2DModelPlotTitleChanged";

@implementation ORManualPlot2DModel

#pragma mark •••initialization
- (id) init 
{
    self = [super init];
	dataSetLock = [[NSLock alloc] init];
    histogram = nil;
    return self;    
}

- (void) dealloc
{
    [histogram release];
    [xTitle release];
    [yTitle release];
    [plotTitle release];
	[dataSetLock release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[rois release];
    [super dealloc];
}

- (NSString*) fullName
{
	return [self fullID];
}
- (NSString*) fullNameWithRunNumber
{
	//fake out so we can inherit
	return [self fullID];
}

- (void) clear
{
	[dataSetLock lock];
    [histogram release];
    histogram = [[NSMutableData dataWithLength:numberBinsPerSide*numberBinsPerSide*sizeof(int32_t)]retain];
    maxX = numberBinsPerSide-1;
    minX = 0;
    maxY = numberBinsPerSide-1;
    minY = 0;
	[dataSetLock unlock];
}

- (unsigned short) numberBinsPerSide
{
    return numberBinsPerSide;
}

- (void) setNumberBinsPerSide:(unsigned short)bins
{
	if(bins>256){
		NSLog(@"Sorry -- number of bins in the manual 2D plot is limited to 256x256\n");
		bins=256;
	}
	[dataSetLock lock];
    numberBinsPerSide = bins;
    
    [histogram release];
    histogram = [[NSMutableData dataWithLength:numberBinsPerSide*numberBinsPerSide*sizeof(int32_t)]retain];
    
	[dataSetLock unlock];
    [self clear];
}

- (uint32_t)valueAtX:(unsigned short)aXBin y:(unsigned short)aYBin
{
	uint32_t theResult = 0;
	if(aXBin<numberBinsPerSide && aYBin<numberBinsPerSide){
		[dataSetLock lock];
        uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
        if(histogramPtr){
            aXBin = aXBin % numberBinsPerSide;   // Error Check Our x Value
            aYBin = aYBin % numberBinsPerSide;   // Error Check Our y Value
            theResult =  histogramPtr[aXBin + aYBin*numberBinsPerSide];
        }
		[dataSetLock unlock];
	}
	return theResult;
}

- (void) setBinAtX:(int)aXBin y:(int)aYBin to:(uint32_t)aValue;
{
    uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
	if(histogramPtr && aXBin<numberBinsPerSide && aYBin<numberBinsPerSide){
		[dataSetLock lock];	
		histogramPtr[aXBin + aYBin*numberBinsPerSide] = aValue;
		[dataSetLock unlock];	
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlot2DDataChanged object:self];
	}
}

- (void) incrementBinAtX:(int)aXBin y:(int)aYBin by:(uint32_t)incValue;
{
    uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
	if(histogramPtr && aXBin<numberBinsPerSide && aYBin<numberBinsPerSide){
		[dataSetLock lock];	
		histogramPtr[aXBin + aYBin*numberBinsPerSide]+=incValue;
		[dataSetLock unlock];	
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlot2DDataChanged object:self];
	}
}

#pragma mark ***Accessors
- (void) postUpdate
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlot2DDataChanged object:self];    
}

- (NSString*) xTitle
{
    if(xTitle)return xTitle;
	else return @"x";
}

- (void) setXTitle:(NSString*)aString
{
    [xTitle autorelease];
    xTitle = [aString copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlot2DModelXTitleChanged object:self];
}

- (NSString*) yTitle
{
    if(yTitle)return yTitle;
	else return @"y";
}

- (void) setYTitle:(NSString*)aString
{
    [yTitle autorelease];
    yTitle = [aString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlot2DModelYTitleChanged object:self];
}

- (NSString*) plotTitle
{
	if(plotTitle) return plotTitle;
	else return @"2D Manual Plot";
}

- (void) setPlotTitle:(NSString*)aString
{
    [plotTitle autorelease];
    plotTitle = [aString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlot2DModelPlotTitleChanged object:self];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"ManualPlot2D"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORManualPlot2DController"];
}

- (NSString*) helpURL
{
	return @"Subsystems/Manual_2DPlotter.html";
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
 	rois = [[decoder decodeObjectForKey:@"rois"] retain];
    [[self undoManager] enableUndoRegistration];

	dataSetLock = [[NSLock alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:rois forKey:@"rois"];
}

#pragma mark •••Data Source
- (NSMutableArray*) rois
{
	if(!rois){
		rois = [[NSMutableArray alloc] init];
		[rois addObject:[[[OR2dRoi alloc] initAtPoint:NSMakePoint(50,50)] autorelease]];
	}
	return rois;
}
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue
{
    return [self getDataSetAndNumBinsPerSize:xValue];
}

- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    [self getXMin:aMinX xMax:aMaxX yMin:aMinY yMax:aMaxY];
}

- (NSData*) getDataSetAndNumBinsPerSize:(unsigned short*)value
{
    *value = numberBinsPerSide;
    return[[histogram retain] autorelease];
}

- (void) getXMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    *aMinX = minX;
    *aMaxX = maxX;
    *aMinY = minY;
    *aMaxY = maxY;
}

- (NSString*) commonScriptMethods
{
	NSArray* selectorArray = [NSArray arrayWithObjects:
							  @"clear",
							  @"numberBinsPerSide",
							  @"setNumberBinsPerSide:(unsigned short)",
							  @"valueAtX:(unsigned short) y:(unsigned short)",
							  @"setBinAtX:(int) y:(int) to:(uint32_t)",
							  @"incrementBinAtX:(int) y:(int) by:(uint32_t)",
							  @"setXTitle:(NSString*)",
							  @"setYTitle:(NSString*)",
							  @"setPlotTitle:(NSString*)",
							  nil];
	
	return [selectorArray componentsJoinedByString:@"\n"];
}

@end
