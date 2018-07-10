//
//  OR1DHisto.m
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


#import "OR1DHisto.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "OR1dRoi.h"

@implementation OR1DHisto

- (id) init 
{
    self = [super init];
    numberBins = 4096;
    overFlow = 0;
    return self;    
}

- (void) dealloc
{
    [histogram release];
    [pausedHistogram release];
	[rois release];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors

- (void) setPaused:(BOOL)aPaused
{
	[super setPaused:aPaused];
	[dataSetLock lock];
	if([self paused]){
        [pausedHistogram release];
        pausedHistogram = [[NSData dataWithData:histogram] retain];
	}
	[dataSetLock unlock];
	
}

- (unsigned long) dataId
{
    return dataId;
}
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

-(void)setNumberBins:(int)aNumberBins
{
	[dataSetLock lock];
    [histogram release];
    numberBins = aNumberBins;
    histogram = [[NSMutableData dataWithLength:numberBins*sizeof(unsigned long)] retain];
	[dataSetLock unlock];
}

-(int) numberBins
{
    return numberBins;
}

-(unsigned long) overFlow
{
    return overFlow;
}


-(unsigned long)value:(unsigned long)aChan
{
    unsigned long theValue;
	[dataSetLock lock];
	
	unsigned long* histogramPtr;
	if([self paused])histogramPtr = (unsigned long*)[pausedHistogram bytes];
	else             histogramPtr = (unsigned long*)[histogram bytes];;
	
	if(aChan<numberBins)theValue = histogramPtr[aChan];
	else theValue = 0;

	[dataSetLock unlock];
    return theValue;
}

#pragma mark ¥¥¥Data Management
-(void)clear
{
	[dataSetLock lock];
    [histogram release];
    histogram = [[NSMutableData dataWithLength:numberBins*sizeof(unsigned long)] retain];
    overFlow = 0;
    [self setTotalCounts:0];
	[dataSetLock unlock];
}

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
	[dataSetLock lock];
    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
    unsigned long* histogramPtr = (unsigned long*)[histogram bytes];
    unsigned long n = [histogram length]/sizeof(unsigned long);
    int i;
    for (i=0; i<n; ++i) {
        fprintf(aFile, "%ld\n",histogramPtr[i]);
    }
    fprintf(aFile, "END\n\n");
	[dataSetLock unlock];
}

- (NSString*) fullName
{
	return [super fullName];
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"OR1DHistoDecoder",                        @"decoder",
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
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"1DHisto"];

}

- (void) processResponse:(NSDictionary*)aResponse
{
	[dataSet processResponse:aResponse];
}

#pragma mark ¥¥¥Data Source Methods

- (id)   name
{
    return [NSString stringWithFormat:@"%@ 1D Histogram Events: %lu",[self key], [self totalCounts]];
}


- (void) histogram:(unsigned long)aValue
{
    if(!histogram){
        [self setNumberBins:4096];
    }
	[dataSetLock lock];
    unsigned long* histogramPtr = (unsigned long*)[histogram bytes];
	if(histogramPtr){
		if(aValue>=numberBins){
			++overFlow;
			++histogramPtr[numberBins-1];
		}
		else {
			++histogramPtr[aValue];
		}
	}
	[dataSetLock unlock];
	[self incrementTotalCounts];

}

// ak, 6.8.07
- (void) histogramWW:(unsigned long)aValue weight:(unsigned long)aWeight
{
    if(!histogram){
        [self setNumberBins:4096];
    }
	[dataSetLock lock];
    unsigned long* histogramPtr = (unsigned long*)[histogram bytes];
	if(histogramPtr){
		if(aValue>=numberBins){
			overFlow += aWeight;
			histogramPtr[numberBins-1] += aWeight;
		}
		else {
			histogramPtr[aValue] += aWeight;
		}
	}
	[dataSetLock unlock];
	[self incrementTotalCounts];

}

- (NSString*) getnonZeroDataAsStringWithStart:(unsigned long*)start end:(unsigned long*)end
{
	NSData* pd = [self getNonZeroRawDataWithStart:start end:end];
	unsigned long* plotData = (unsigned long*)[pd bytes];
	int n = [pd length]/4;
	int i;
	NSMutableString* s = [NSMutableString stringWithCapacity:n*64];
	for(i=0;i<n;i++){
		[s appendFormat:@"%lu,",plotData[i]];
	}
	if([s length]>0)[s deleteCharactersInRange:NSMakeRange([s length]-1,1)];
	return s;
}

- (NSData*) getNonZeroRawDataWithStart:(unsigned long*)start end:(unsigned long*)end
{
	[dataSetLock lock];
	NSData* theData = nil;
    NSData* tempHistoryRef = [histogram retain];
    unsigned long* histogramPtr = (unsigned long*)[tempHistoryRef bytes];
	if(histogramPtr){
		BOOL atLeastOne = NO;
		unsigned long n = [self numberBins];
		unsigned long theFirstOne = 0;
		unsigned long theLastOne = n-1;
		if(n>0){
			unsigned long i;
			for(i=0;i<n;i++){
				if(histogramPtr[i]!=0){
					theFirstOne = i;
					atLeastOne = YES;
					break;
				}
			}
			for(i=n-1;i>0;i--){
				if(histogramPtr[i]!=0){
					theLastOne = i;
					break;
				}
			}
		}
		if(atLeastOne){
			*start = theFirstOne;
			*end = theLastOne;
			theData =  [NSData dataWithBytes:&histogramPtr[theFirstOne] length:(theLastOne-theFirstOne+1)*sizeof(long)];
		}
		else {
			*start = 0;
			*end = 1;
			unsigned long zero = 0;
			theData =  [NSData dataWithBytes:&zero length:1*sizeof(long)];

		}
	}
    [tempHistoryRef release];
	[dataSetLock unlock];
	return theData;
}

- (void) loadData:(NSData*)someData;
{
		
	[dataSetLock lock];
    [histogram release];
    histogram = [[NSMutableData dataWithData:someData] retain];
    numberBins = [histogram length]/sizeof(unsigned long);
	[dataSetLock unlock];
	[self incrementTotalCounts];	
}

- (void) mergeHistogram:(unsigned long*)ptr numValues:(unsigned long)numBins
{
    if(!histogram || numberBins != numBins){
        [self setNumberBins:numBins];
    }
	[dataSetLock lock];
    int i;
    unsigned long* histogramPtr = (unsigned long*)[histogram bytes];
	if(histogramPtr){
		for(i=0;i<numBins;i++){
			histogramPtr[i] += ptr[i];
		}
	}
	[dataSetLock unlock];
    [self incrementTotalCounts];
}


//!For merging energy histograms -tb-
- (void) mergeEnergyHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins maxBins:(unsigned long)maxBins
                                                 firstBin:(unsigned long)firstBin   stepSize:(unsigned long)stepSize 
                                                   counts:(unsigned long)counts

{
    if(!histogram || numberBins != maxBins){
        [self setNumberBins:maxBins];
    }
	[dataSetLock lock];
	if(histogram){
        unsigned long* histogramPtr = (unsigned long*)[histogram bytes];
		int i,index;
		for( (index=firstBin,i=0); i<numBins; (index+=stepSize,i++) ){
			if(index>=numberBins){
				overFlow += ptr[i];
				histogramPtr[numberBins-1] += ptr[i];
			}
            else {
				histogramPtr[index] += ptr[i];
			}
		}
	}
	[dataSetLock unlock];
    [self setTotalCounts: totalCounts+counts];
}


- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo keys:(NSMutableArray*)aKeyArray
{
    NSMutableData* dataToShip = [NSMutableData data];
    unsigned long dataWord;
    
    //first the id
    dataWord = dataId; //note we don't know the length yet--we'll fill it in later
    [dataToShip appendBytes:&dataWord length:4];

    //append the keys
    NSString* allKeys = [aKeyArray componentsJoinedByString:@"/"];
	if(allKeys && ![allKeys hasPrefix:@"Final"]){
		allKeys = [@"Final/" stringByAppendingString:allKeys];
		const char* p = [allKeys UTF8String];
		unsigned long allKeysLengthWithTerminator = strlen(p)+1;
		unsigned long paddedKeyLength = 4*((unsigned long)(allKeysLengthWithTerminator+4)/4);
		unsigned long paddedKeyLengthLong = paddedKeyLength/4;
		[dataToShip appendBytes:&paddedKeyLengthLong length:4];
		[dataToShip appendBytes:p length:allKeysLengthWithTerminator];

		//pad to the long word boundary
		int i;
		for(i=0;i< paddedKeyLength-allKeysLengthWithTerminator;i++){
			char null = '\0';
			[dataToShip appendBytes:&null length:1];
		}
		
		[dataToShip appendBytes:&numberBins length:4];            //length of the histogram
        [dataToShip appendData:histogram];
		
		//go back and fill in the total length
		unsigned long *ptr = (unsigned long*)[dataToShip bytes];
		unsigned long totalLength = [dataToShip length]/4; //num of longs
		*ptr |= (kLongFormLengthMask & totalLength);
		[aDataPacket addData:dataToShip];
	}
}

- (BOOL) canJoinMultiPlot
{
    return YES;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"OR1DHistoController"];
}

#pragma mark ¥¥¥Archival
static NSString *OR1DHistoNumberBins	= @"1D Histogram Number Bins";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setNumberBins:[decoder decodeIntForKey:OR1DHistoNumberBins]];
	rois = [[decoder decodeObjectForKey:@"rois"] retain];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:numberBins forKey:OR1DHistoNumberBins];
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
	return [self numberBins];
}

- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue
{
	*yValue =  [self value:i];
	*xValue = i;
}

@end
