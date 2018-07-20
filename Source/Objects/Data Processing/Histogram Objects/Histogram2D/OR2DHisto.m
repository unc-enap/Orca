//
//  OR2DHisto.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 23 2004.
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


#import "OR2DHisto.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "OR2dRoi.h"

#import <math.h>
@implementation OR2DHisto

- (id) init 
{
    self = [super init];
    numberBinsPerSide = 512;
    histogram = nil;
    return self;    
}



- (void) dealloc
{
    [histogram release];
	[rois release];
    [super dealloc];
}



#pragma mark ¥¥¥Accessors

- (void) setKey:(NSString*)aKey
{
    [key autorelease];
    key = [aKey copy];
}

- (NSString*)key
{
    return key;
}


-(unsigned short) numberBinsPerSide
{
    return numberBinsPerSide;
}

- (void) setNumberBinsPerSide:(unsigned short)bins
{
	[dataSetLock lock];
    numberBinsPerSide = bins;
    [histogram release];
    histogram = [[NSMutableData dataWithLength:numberBinsPerSide*numberBinsPerSide*sizeof(uint32_t)]retain];
	[dataSetLock unlock];
    [self clear];
}

- (uint32_t)valueX:(unsigned short)aXBin y:(unsigned short)aYBin
{
	uint32_t theResult = 0;
	[dataSetLock lock];
    aXBin = aXBin % numberBinsPerSide;   // Error Check Our x Value
    aYBin = aYBin % numberBinsPerSide;   // Error Check Our y Value
    uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
    if(histogramPtr) theResult =  histogramPtr[aXBin + aYBin*numberBinsPerSide];
	[dataSetLock unlock];
	return theResult;
}
- (uint32_t) dataId
{
    return dataId;
}
- (void) setDataId: (uint32_t) aDataId
{
    dataId = aDataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

#pragma mark ¥¥¥Data Management
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"OR2DHistoDecoder",                        @"decoder",
        [NSNumber numberWithLong:dataId],           @"dataId",
        [NSNumber numberWithBool:YES],              @"variable",
        [NSNumber numberWithLong:-1],               @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Histograms"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"2DHisto"];

}

- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray
{
    NSMutableData* dataToShip = [NSMutableData data];
    uint32_t dataWord;
    
    //first the id
    dataWord = dataId; //note we don't know the length yet--we'll fill it in later
    [dataToShip appendBytes:&dataWord length:4];

    //append the keys
    NSString* allKeys = [aKeyArray componentsJoinedByString:@"/"];
	if(allKeys && ![allKeys hasPrefix:@"Final"]){
		allKeys = [@"Final/" stringByAppendingString:allKeys];
		const char* p = [allKeys UTF8String];
		uint32_t allKeysLengthWithTerminator = (uint32_t)strlen(p)+1;
		uint32_t paddedKeyLength = 4*((uint32_t)(allKeysLengthWithTerminator+4)/4);
		uint32_t paddedKeyLengthLong = paddedKeyLength/4;
		[dataToShip appendBytes:&paddedKeyLengthLong length:4];
		[dataToShip appendBytes:p length:allKeysLengthWithTerminator];

		//pad to the int32_t word boundary
		int i;
		for(i=0;i< paddedKeyLength-allKeysLengthWithTerminator;i++){
			char null = '\0';
			[dataToShip appendBytes:&null length:1];
		}
		
		[dataSetLock lock];
		uint32_t theSize = numberBinsPerSide*numberBinsPerSide;
		[dataToShip appendBytes:&theSize length:4];            //length of the histogram
        [dataToShip appendData:histogram];
		[dataSetLock unlock];
		
		//go back and fill in the total length
		uint32_t *ptr = (uint32_t*)[dataToShip bytes];
		uint32_t totalLength = (uint32_t)[dataToShip length]/4; //num of longs
		*ptr |= (kLongFormLengthMask & totalLength);
		[aDataPacket addData:dataToShip];
	}
}

-(void)clear
{
	[dataSetLock lock];
    [histogram release];
    histogram = [[NSMutableData dataWithLength:numberBinsPerSide*numberBinsPerSide*sizeof(uint32_t)]retain];
    
    minX = numberBinsPerSide;
    maxX = 0;
    minY = numberBinsPerSide;
    maxY = 0;
	[dataSetLock unlock];
    
    [self setTotalCounts:0];
}

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
    //not implemented yet....
/*    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
    int i;
    for (i=0; i<numberBins; ++i) {
        fprintf(aFile, "%d\n",histogram[i]);
    }
    fprintf(aFile, "END\n\n");
*/
}


#pragma mark ¥¥¥Data Source Methods
- (NSData*) getDataSetAndNumBinsPerSize:(unsigned short*)value
{
    *value = numberBinsPerSide;
    return [[histogram retain] autorelease];
    
}

- (void) getXMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    *aMinX = minX;
    *aMaxX = maxX;
    *aMinY = minY;
    *aMaxY = maxY;
}

- (id)   name
{
    return [NSString stringWithFormat:@"%@ 2D Histogram Events: %u",key, [self totalCounts]];
}

- (void) mergeHistogram:(uint32_t*)ptr numValues:(uint32_t)num
{
    if(!histogram || (numberBinsPerSide*numberBinsPerSide) != num){
        [self setNumberBinsPerSide:(unsigned short)pow((double)num,.5)];
    }
	[dataSetLock lock];
    uint32_t* hitogramPtr = (uint32_t*)[histogram bytes];
	if(hitogramPtr){
		int i;
		for(i=0;i<num;i++){
			hitogramPtr[i] += ptr[i];
			if(hitogramPtr[i]){
				unsigned short y = i/numberBinsPerSide;
				unsigned short x = i%numberBinsPerSide;
				
				if(x<minX)minX = x;
				if(x>maxX)maxX = x;
				if(y<minY)minY = y;
				if(y>maxY)maxY = y;
			}
		}
	}
	[dataSetLock unlock];
    [self incrementTotalCounts];
}

- (void) load:(uint32_t*)ptr numValues:(uint32_t)num
{
    if(!histogram || (numberBinsPerSide*numberBinsPerSide) != num){
        [self setNumberBinsPerSide:(unsigned short)pow((double)num,.5)];
    }
	if(histogram){
		[dataSetLock lock];
        uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
		int i;
		for(i=0;i<num;i++){
			histogramPtr[i] = ptr[i];
			if(histogramPtr[i]){
				unsigned short y = i/numberBinsPerSide;
				unsigned short x = i%numberBinsPerSide;
				
				if(x<minX)minX = x;
				if(x>maxX)maxX = x;
				if(y<minY)minY = y;
				if(y>maxY)maxY = y;
			}
		}
		[dataSetLock unlock];
	}
    [self incrementTotalCounts];
}


- (void) histogramX:(unsigned short)aXValue y:(unsigned short)aYValue;
{
    if(!histogram){
        [self setNumberBinsPerSide:512]; //default
    }
	[dataSetLock lock];
    if(aXValue >= numberBinsPerSide) aXValue = numberBinsPerSide-1;
    if(aYValue >= numberBinsPerSide) aYValue = numberBinsPerSide-1;
    //aXValue = aXValue % numberBinsPerSide;   // Error Check Our x Value
    //aYValue = aYValue % numberBinsPerSide;   // Error Check Our y Value
    uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
	if(histogramPtr){
		++histogramPtr[aXValue+aYValue*numberBinsPerSide];
	}
    [self incrementTotalCounts];
    if(aXValue<minX)minX = aXValue;
    if(aXValue>maxX)maxX = aXValue;
    if(aYValue<minY)minY = aYValue;
    if(aYValue>maxY)maxY = aYValue;
	[dataSetLock unlock];
    
}
- (void) loadX:(unsigned short)aXValue y:(unsigned short)aYValue z:(unsigned short)aZValue
{
    if(!histogram){
        [self setNumberBinsPerSide:512]; //default
    }
	[dataSetLock lock];
    if(aXValue >= numberBinsPerSide) aXValue = numberBinsPerSide-1;
    if(aYValue >= numberBinsPerSide) aYValue = numberBinsPerSide-1;
    //aXValue = aXValue % numberBinsPerSide;   // Error Check Our x Value
    //aYValue = aYValue % numberBinsPerSide;   // Error Check Our y Value
    uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
    if(histogramPtr){
		histogramPtr[aXValue+aYValue*numberBinsPerSide] = aZValue;
	}
    [self incrementTotalCounts];
    if(aXValue<minX)minX = aXValue;
    if(aXValue>maxX)maxX = aXValue;
    if(aYValue<minY)minY = aYValue;
    if(aYValue>maxY)maxY = aYValue;
	[dataSetLock unlock];
    
}


- (void) sumX:(unsigned short)aXValue y:(unsigned short)aYValue z:(unsigned short)aZValue
{
    uint32_t* histogramPtr = (uint32_t*)[histogram bytes];
    if(!histogramPtr){
        [self setNumberBinsPerSide:512]; //default
    }
	[dataSetLock lock];
    if(aXValue >= numberBinsPerSide) aXValue = numberBinsPerSide-1;
    if(aYValue >= numberBinsPerSide) aYValue = numberBinsPerSide-1;
    //aXValue = aXValue % numberBinsPerSide;   // Error Check Our x Value
    //aYValue = aYValue % numberBinsPerSide;   // Error Check Our y Value
    if(histogramPtr){
		histogramPtr[aXValue+aYValue*numberBinsPerSide] += aZValue;
	}
    [self incrementTotalCounts];
    if(aXValue<minX)minX = aXValue;
    if(aXValue>maxX)maxX = aXValue;
    if(aYValue<minY)minY = aYValue;
    if(aYValue>maxY)maxY = aYValue;
	[dataSetLock unlock];
    
}

//don't allow calibration
- (id) calibration
{
    return nil;
}

- (void) setCalibration:(id)aCalibration
{
}

- (NSData*) rawData
{
	NSData* theRawData;
	[dataSetLock lock];
    theRawData = [NSData dataWithData:histogram];
	[dataSetLock unlock];
	return theRawData;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"OR2DHistoController"];
}

#pragma mark ¥¥¥Archival
static NSString *OR2DHistoNumberXBins	= @"OR2DHistoNumberXBins";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setNumberBinsPerSide:[decoder decodeIntegerForKey:OR2DHistoNumberXBins]];
 	rois = [[decoder decodeObjectForKey:@"rois"] retain];
   
    [[self undoManager] enableUndoRegistration];
    return self;
}

#pragma mark ¥¥¥Data Source
- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:numberBinsPerSide forKey:OR2DHistoNumberXBins];
    [encoder encodeObject:rois forKey:@"rois"];
}

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
    *xValue = numberBinsPerSide;
    return [[histogram retain] autorelease];
}

- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    [self getXMin:aMinX xMax:aMaxX yMin:aMinY yMax:aMaxY];
}

@end
