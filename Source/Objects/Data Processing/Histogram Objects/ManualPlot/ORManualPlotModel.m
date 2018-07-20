//
//  ORManualPlotModel.m
//  Orca
//
//  Created by Mark Howe on Fri Apr 27 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORManualPlotModel.h"
#import "NSNotifications+Extensions.h"
#import "ORDataSet.h"
#import "ORCARootServiceDefs.h"
#import "ORXYRoi.h"

NSString* ORManualPlotModelCommentChanged = @"ORManualPlotModelCommentChanged";
NSString* ORManualPlotModelCol3TitleChanged = @"ORManualPlotModelCol3TitleChanged";
NSString* ORManualPlotModelCol2TitleChanged = @"ORManualPlotModelCol2TitleChanged";
NSString* ORManualPlotModelCol1TitleChanged = @"ORManualPlotModelCol1TitleChanged";
NSString* ORManualPlotModelCol0TitleChanged = @"ORManualPlotModelCol0TitleChanged";
NSString* ORManualPlotModelColKey0Changed	= @"ORManualPlotModelColKey0Changed";
NSString* ORManualPlotModelColKey1Changed	= @"ORManualPlotModelColKey1Changed";
NSString* ORManualPlotModelColKey2Changed	= @"ORManualPlotModelColKey2Changed";
NSString* ORManualPlotModelColKey3Changed	= @"ORManualPlotModelColKey3Changed";
NSString* ORManualPlotLock					= @"ORManualPlotLock";
NSString* ORManualPlotDataChanged			= @"ORManualPlotDataChanged";

@implementation ORManualPlotModel

#pragma mark •••initialization
- (id) init 
{
    self = [super init];
	dataSetLock = [[NSLock alloc] init];
	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
    return self;    
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [comment release];
	[dataSetLock release];
	[fftDataSet release];
    [col3Title release];
    [col2Title release];
    [col1Title release];
    [col0Title release];
	[calibration release];
	[data release];
 	[roiSet release];
    [super dealloc];
}

- (void) clear
{
	[dataSetLock lock];
	[data release];
	data = nil;
	[dataSetLock unlock];	
}
- (void) addValue1:(float)v1 value2:(float)v2 
{
	[dataSetLock lock];
	if(!data) data = [[NSMutableArray array] retain];
	[data addObject:[NSArray arrayWithObjects:
					 [NSNumber numberWithFloat:v1],
					 [NSNumber numberWithFloat:v2],
					 [NSNumber numberWithFloat:0],
					 [NSNumber numberWithFloat:0],
					 nil]];
	[dataSetLock unlock];	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlotDataChanged object:self];
	
}
- (void) addValue1:(float)v1 value2:(float)v2 value3:(float)v3
{
	[dataSetLock lock];
	if(!data) data = [[NSMutableArray array] retain];
	[data addObject:[NSArray arrayWithObjects:
					 [NSNumber numberWithFloat:v1],
					 [NSNumber numberWithFloat:v2],
					 [NSNumber numberWithFloat:v3],
					 [NSNumber numberWithFloat:0],
					 nil]];
	[dataSetLock unlock];	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlotDataChanged object:self];
}

- (void) addValue1:(float)v1 value2:(float)v2 value3:(float)v3 value4:(float)v4
{
	[dataSetLock lock];
	if(!data) data = [[NSMutableArray array] retain];
	[data addObject:[NSArray arrayWithObjects:
					 [NSNumber numberWithFloat:v1],
					 [NSNumber numberWithFloat:v2],
					 [NSNumber numberWithFloat:v3],
					 [NSNumber numberWithFloat:v4],
					 nil]];
	[dataSetLock unlock];	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlotDataChanged object:self];
	
}

- (void) setHistogramBins:(int)nBins xLow:(float)xLow xHigh:(float)xHigh
{
  [self clearData];
  int i;
  for(i=0; i<nBins+2; i++) {
    [self addValue1:(xLow + (xHigh-xLow)*(i-1)/nBins) value2:0];
  }
}

- (void) fillHistogram:(float)value
{
  [self fillHistogram:value weight:1];
}

- (void) fillHistogram:(float)value weight:(float)weight
{
  int nBins = (int)[data count];
  if(nBins == 0) {
    NSLogColor([NSColor redColor],@"Must call setHistogramBins before filling!\n");
    return;
  }
  float xLow = [[self dataAtRow:0 column:0] floatValue];
  float xHigh = [[self dataAtRow:(nBins-1) column:0] floatValue];
  int iBin;
  if(value < xLow) iBin = 0;
  else if(value >= xHigh) iBin = nBins-1;
  else iBin = 1 + ((value - xLow)/(xHigh-xLow) * nBins);

  float binX = [[self dataAtRow:iBin column:0] floatValue];
  float currentCounts = [[self dataAtRow:iBin column:1] floatValue];

  [dataSetLock lock];
  [data replaceObjectAtIndex:iBin withObject:[NSArray arrayWithObjects:
    [NSNumber numberWithFloat:binX],
    [NSNumber numberWithFloat:(currentCounts+weight)],
    [NSNumber numberWithFloat:0],
    [NSNumber numberWithFloat:0],
    nil]];
  [dataSetLock unlock];	

  [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlotDataChanged object:self];
}


#pragma mark ***Accessors

- (NSString*) comment
{
    return comment;
}

- (void) setComment:(NSString*)aComment
{
    [comment autorelease];
    comment = [aComment copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCommentChanged object:self];
}
- (void) postUpdate
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotDataChanged object:self];    
}

- (id) calibration
{
	return calibration;
}

- (void) setCalibration:(id)aCalibration
{
	[aCalibration retain];
	[calibration release];
	calibration  = aCalibration;
}
- (NSString*) col3Title
{
    return col3Title;
}

- (void) setCol3Title:(NSString*)aCol3Title
{
    [col3Title autorelease];
    col3Title = [aCol3Title copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol3TitleChanged object:self];
}

- (NSString*) col2Title
{
    return col2Title;
}

- (void) setCol2Title:(NSString*)aCol2Title
{
    [col2Title autorelease];
    col2Title = [aCol2Title copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol2TitleChanged object:self];
}

- (NSString*) col1Title
{
    return col1Title;
}

- (void) setCol1Title:(NSString*)aCol1Title
{
    [col1Title autorelease];
    col1Title = [aCol1Title copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol1TitleChanged object:self];
}

- (NSString*) col0Title
{
    return col0Title;
}

- (void) setCol0Title:(NSString*)aCol0Title
{
    [col0Title autorelease];
    col0Title = [aCol0Title copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol0TitleChanged object:self];
}
- (int) col3Key;
{
    return col3Key;
}

- (void) setCol3Key:(int)aCol3Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol3Key:col3Key];
    col3Key = aCol3Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKey3Changed object:self];
}
- (int) col2Key;
{
    return col2Key;
}

- (void) setCol2Key:(int)aCol2Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol2Key:col2Key];
    col2Key = aCol2Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKey2Changed object:self];
}

- (int) col1Key;
{
    return col1Key;
}

- (void) setCol1Key:(int)aCol1Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol1Key:col1Key];
    col1Key = aCol1Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKey1Changed object:self];
}

- (int) col0Key
{
    return col0Key;
}

- (void) setCol0Key:(int)aCol0Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol0Key:col0Key];
    col0Key = aCol0Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKey0Changed object:self];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"ManualPlot"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORManualPlotController"];
}

- (NSString*) helpURL
{
	return @"Subsystems/Manual_Plotter.html";
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setComment:[decoder decodeObjectForKey:@"comment"]];
    [self setCol3Key:[decoder decodeIntForKey:@"ORManualPlotModelCol3Key"]];
    [self setCol2Key:[decoder decodeIntForKey:@"ORManualPlotModelCol2Key"]];
    [self setCol1Key:[decoder decodeIntForKey:@"ORManualPlotModelCol1Key"]];
    [self setCol0Key:[decoder decodeIntForKey:@"ORManualPlotModelCol0Key"]];
	[self setCalibration:[decoder decodeObjectForKey:@"calibration"]];
	roiSet			  = [[decoder decodeObjectForKey:@"roiSet"] retain];
	if(col0Key==0)[self setCol0Key:0]; 
	if(col1Key==0)[self setCol1Key:1]; 
	if(col2Key==0)[self setCol2Key:2]; 
	if(col3Key==0)[self setCol3Key:3]; 
    [[self undoManager] enableUndoRegistration];

	dataSetLock = [[NSLock alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:comment forKey:@"comment"];
    [encoder encodeInteger:col3Key forKey:@"ORManualPlotModelCol3Key"];
    [encoder encodeInteger:col2Key forKey:@"ORManualPlotModelCol2Key"];
    [encoder encodeInteger:col1Key forKey:@"ORManualPlotModelCol1Key"];
    [encoder encodeInteger:col0Key forKey:@"ORManualPlotModelCol0Key"];
    [encoder encodeObject:calibration forKey:@"calibration"];
    [encoder encodeObject:roiSet		forKey:@"roiSet"];
}

-(void)clearData
{
	[dataSetLock lock];
	[data release];
	data = nil;
	[dataSetLock unlock];
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

#pragma mark •••Writing Data
- (void) writeDataToFile:(NSString*)aFileName
{
	[dataSetLock lock];
	
	NSString* fullFileName = [aFileName stringByExpandingTildeInPath];
	FILE* aFile = fopen([fullFileName cStringUsingEncoding:NSASCIIStringEncoding],"w"); 
	if(aFile){
		NSLog(@"Writing Manual Plot File: %@\n",fullFileName);
		NSEnumerator* e = [data objectEnumerator];
		NSArray* row;
		while(row=[e nextObject]){
			fprintf(aFile, "%f\t%f\t%f\t%f\n",[[row objectAtIndex:0] floatValue],[[row objectAtIndex:1] floatValue],[[row objectAtIndex:2] floatValue],[[row objectAtIndex:3] floatValue]);
		}
		fclose(aFile);
	}
	
	[dataSetLock unlock];
}

- (void) processResponse:(NSDictionary*)aResponse
{
	NSString* title = [aResponse objectForKey:ORCARootServiceTitleKey];
	NSMutableArray* keyArray = [NSMutableArray arrayWithArray:[title componentsSeparatedByString:@","]];
	[keyArray insertObject:@"FFT" atIndex:0];
	NSArray* complex = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTComplex",nil];
	NSArray* real    = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTReal",nil];
	if(!fftDataSet)fftDataSet = [[ORDataSet alloc] initWithKey:@"fftSet" guardian:nil];
	[fftDataSet loadFFTReal:real imaginary:complex withKeyArray:keyArray];
}

#pragma mark *** delegate methods
-(id) dataAtRow:(int)r column:(int)c
{
	if(r<[data count]){
		NSArray* row =  [data objectAtIndex:r];
		if(c<[row count]){
			return [row objectAtIndex:c];
		}
	}
	return nil;
}


- (uint32_t) numPoints
{
    return (uint32_t)[data count];
}

- (BOOL) dataSet:(int)set index:(uint32_t)index x:(double*)xValue y:(double*)yValue
{
	BOOL valid = YES;
	[dataSetLock lock];
	
	if(index<[data count]){
		id d = [data objectAtIndex:index];
		if(col0Key <= 3) *xValue = [[d objectAtIndex:col0Key] floatValue];
		else *xValue = index;
		if(set==0) {
			if(col1Key <= 3) *yValue = [[d objectAtIndex:col1Key] floatValue];
			else *yValue=0;
		}
		else if(set==1) {
			if(col2Key <= 3) *yValue = [[d objectAtIndex:col2Key] floatValue];
			else *yValue=0;
		}
		else {
			if(col3Key <= 3) *yValue = [[d objectAtIndex:col3Key] floatValue];
			else *yValue=0;
		}
	}
	else {
		valid = NO;
		*xValue = 0;
		*yValue = 0;
	}
	[dataSetLock unlock];
    return valid;    
}
- (NSString*) commonScriptMethods
{
	
	NSArray* selectorArray = [NSArray arrayWithObjects:
							  @"comment",
							  @"clearData",
							  @"setHistogramBins:(int) xLow:(float) xHigh:(float)",
							  @"setComment:(NSString*)",
							  @"setCol0Title:(NSString*)",
							  @"setCol1Title:(NSString*)",
							  @"setCol2Title:(NSString*)",
							  @"setCol3Title:(NSString*)",
							  @"addValue1:(float) value2:(float)",
							  @"addValue1:(float) value2:(float) value3:(float)",
							  @"addValue1:(float) value2:(float) value3:(float) value4:(float)",
							  @"fillHistogram:(float)",
							  @"fillHistogram:(float) weight:(float)",
							  nil];
	
	return [selectorArray componentsJoinedByString:@"\n"];
}

#pragma mark •••Data Source
- (NSMutableArray*) rois:(int)index
{
	if(!roiSet)roiSet = [[NSMutableArray alloc] init];
	if(index >= [roiSet count]){
		if(index >0){
			int i;
			for(i=0;i<index;i++){
				NSMutableArray* theRois = [[NSMutableArray alloc] init];
				[theRois addObject:[[[ORXYRoi alloc] initWithMin:20 max:30] autorelease]];
				[roiSet addObject:theRois];
				[theRois release];
			}
		}
		else if([roiSet count] == 0){
			NSMutableArray* theRois = [[NSMutableArray alloc] init];
			[theRois addObject:[[[ORXYRoi alloc] initWithMin:20 max:30] autorelease]];
			[roiSet addObject:theRois];
			[theRois release];		
		};
	}
	
	return [roiSet objectAtIndex:index];
}

@end
