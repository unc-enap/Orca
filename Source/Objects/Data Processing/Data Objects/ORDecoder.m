//
//  ORDecoder.m
//  
//
//  Created by Mark Howe on Sun Nov 15,2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

#import "ORDecoder.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORBaseDecoder.h"
#import "NSFileManager+Extensions.h"

#define kAmountToRead 5*1024*1024

@implementation ORDecoder
+ (NSMutableDictionary*)readHeader:(NSFileHandle*)fp
{
	ORDecoder* aDecoder = [[[ORDecoder alloc] init] autorelease];
	[aDecoder readHeader:fp];
	return [aDecoder fileHeader];
}

+ (NSData*) convertHeaderToData:(NSMutableDictionary*)aHeader
{
	ORDecoder* aDecoder = [[[ORDecoder alloc] initWithHeader:aHeader] autorelease];
	return [aDecoder headerAsData];
}

+ (id) decoderWithFile:(NSFileHandle*)fp
{
	ORDecoder* aWorker =  [[[ORDecoder alloc] init] autorelease];
	[aWorker readHeader:fp];
	ORDecoder* aDecoder = [[[ORDecoder alloc] initWithHeader:[aWorker fileHeader]] autorelease];
	[aDecoder setNeedToSwap:[aWorker needToSwap]];
	return aDecoder;
}

- (id) initWithHeader:(NSMutableDictionary*)aHeader
{
	self = [super init];
    skipRateCounts = NO;
	[self setFileHeader:aHeader];
	return self;
}

- (void) dealloc
{
    [objectLookup release];
	[fileHeader release];
	[super dealloc];
}

- (BOOL) needToSwap
{
	return needToSwap;
}

- (void) setNeedToSwap:(BOOL)aNeedToSwap
{
	needToSwap = aNeedToSwap;
}
	 
- (NSMutableDictionary*) readHeader:(NSFileHandle*)fp
{
	if(fp && [self legalDataFile:fp]){
		NSData* newData = [fp readDataOfLength:kAmountToRead];
		uint32_t* p = (uint32_t*)[newData bytes];
		p++;	 //point to header length
		uint32_t headerLength = *p; //bytes
		if(needToSwap)	headerLength = CFSwapInt32((uint32_t)headerLength);			
		p++;	 //point to header itself
		NSString* theHeaderAsString = [[NSString alloc] initWithBytes:p length:headerLength encoding:NSASCIIStringEncoding];
		[self setFileHeader:[theHeaderAsString propertyList]]; 
		[theHeaderAsString release];
	}
	return fileHeader;
}

- (NSMutableDictionary*)fileHeader
{
	return fileHeader;
}

- (void) setFileHeader:(NSMutableDictionary*) aHeader
{
	[aHeader retain];
	[fileHeader release];
	fileHeader = [aHeader retain];
	[self generateObjectLookup];
	uint32_t headerLength = (uint32_t)[[self headerAsData] length]; 
	[fileHeader setObject:[NSNumber numberWithLong:headerLength] forKey:@"Header Length"];

}

- (void) setSkipRateCounts:(BOOL)aState
{
    skipRateCounts = aState;
}

- (BOOL) skipRateCounts
{
    return skipRateCounts;
    
}


- (NSMutableDictionary*) objectLookup
{
    return objectLookup;
}

- (void) setObjectLookup:(NSMutableDictionary*)aDictionary
{
    [aDictionary retain];
    [objectLookup release];
    objectLookup = aDictionary;
}

- (id) headerObject:(NSString*) firstKey,...
{
    va_list myArgs;
    va_start(myArgs,firstKey);
    
    NSString* s = firstKey;
	id result = [fileHeader objectForKey:s];
	while((s = va_arg(myArgs, NSString *))) {
        if([result isKindOfClass:NSClassFromString(@"NSDictionary")]){
            result = [result objectForKey:s];
        }
        else if([result isKindOfClass:NSClassFromString(@"NSArray")]){
            int index = [s intValue];
            int count = (int)[result count];
            if(index<count) result = [result objectAtIndex:index];
            else result = nil;
        }
    }
    va_end(myArgs);
	return result;
}

- (void) generateObjectLookup
{
	int i;
	for(i=0;i<kFastLoopupCacheSize;i++){
		fastLookupCache[i] = 0;
	}
    [self setObjectLookup:[NSMutableDictionary dictionary]];

	NSDictionary* descriptionDict = [fileHeader objectForKey:@"dataDescription"];
	NSString* objKey;
	NSEnumerator*  descriptionDictEnum = [descriptionDict keyEnumerator];
	while(objKey = [descriptionDictEnum nextObject]){
		NSDictionary* objDictionary = [descriptionDict objectForKey:objKey];
		NSEnumerator* dataObjEnum = [objDictionary keyEnumerator];
		NSString* dataObjKey;
		while(dataObjKey = [dataObjEnum nextObject]){
			NSDictionary* lowestLevel = [objDictionary objectForKey:dataObjKey];
			id decoderName = [lowestLevel objectForKey:@"decoder"];
			id decoderObj =  [[NSClassFromString(decoderName) alloc] init];
			if(decoderObj){
				if([lowestLevel objectForKey:@"dataId"]){
					[objectLookup setObject:decoderObj forKey:[lowestLevel objectForKey:@"dataId"]];
				}
				[decoderObj release];
			}
			else {
				if(![dataObjKey isEqual:@"ResponsePacket"]){ //don't complain for this special case
					NSLogError(@"Programming Error (no Object)",decoderName,@"Data Description Item",nil);
				}
			}
		}
	}   
}

- (id) objectForKey:(id)key
{
	return [objectLookup objectForKey:key];
}


- (void) decode:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t length = (uint32_t)[someData length]/sizeof(int32_t);
    if(length){
        uint32_t* dPtr = (uint32_t*)[someData bytes];
        if(dPtr!=0)[self decode:dPtr length:length intoDataSet:aDataSet];
    }
}

- (void) decode:(uint32_t*)dPtr length:(int32_t)length intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t keyMaskValue;
    do {
        if(!dPtr)break;
		
		keyMaskValue = ExtractDataId(*dPtr);
 		
        id anObj = fastLookupCache[keyMaskValue>>18]; //optimization, but dangerous. keyMask must be < kFastLoopupCacheSize
		if(!anObj){
			if(keyMaskValue == 0x0 || keyMaskValue == 0x3C3C){
				//this is the header, maybe the old form, but worry about that in the decoder
				anObj = self;
			}
			else {
				anObj = [objectLookup objectForKey:[NSNumber  numberWithLong:keyMaskValue]];
				if(!anObj)anObj = self; //must be header
			}
			fastLookupCache[keyMaskValue>>18] = anObj;
		}
        uint32_t numLong;
        if(!anObj){
			//no decoder defined for this object
			numLong = ExtractLength(*dPtr); //new form--just skip it by getting the length from the header.
			if(numLong == 0){
				NSLogError(@" ",@"Data Decoder",@"Zero Packet Length",nil);
				break;
			}
			
        }
        else {
            [anObj setSkipRateCounts:skipRateCounts];
            numLong = [anObj decodeData:dPtr  fromDecoder:self intoDataSet:aDataSet];
		}
        if(numLong)dPtr+=numLong;
        else break; //can not continue with this record.. size was zero
		
		if(numLong > length){
			//really bad... the length or the nuLongs processed was incorrect for some reason. We can not continue.
			NSLogError(@" ",@"Data Decoder",@"Bad Record:Incorrect Length",nil);
			break;
		}
		
        length-=numLong;
		
    } while( length>0 );
}

- (void) byteSwapData:(uint32_t*)dPtr forKey:(NSNumber*)aKey
{
	if(!dPtr)return;
	[[objectLookup objectForKey:aKey] swapData:dPtr];	
}

-(uint32_t)decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	//only get here if the data is a data header
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t val = *ptr;
	
	uint32_t theDataId = ExtractDataId(val);
	
	if(theDataId == 0x0) {		//great, this is easy... it's the new form
		uint32_t theLength = ExtractLength(val);
		[aDataSet loadGenericData:@" " sender:self withKeys:@"Header",nil];
		
		return theLength;
	}
	else {	//crap -- old form.... eventually we'll depreciate this form	
		//shouldn't get here using the old form but just in case...
		return 0; //just to show we couldn't process.
	}
}

- (void) byteSwapOneRecord:(uint32_t*)dPtr forKey:(NSNumber*)aKey
{
		if(!dPtr)return;
		[[objectLookup objectForKey:aKey] swapData:dPtr];	
}

- (BOOL) legalDataFile: (NSFileHandle*)fp
{
	NSData* someData = [fp readDataOfLength:100];
	[fp seekToFileOffset:0];
	return [self legalData:someData];
}

- (BOOL) legalData:(NSData*)someData
{
	uint32_t* p = (uint32_t*)[someData bytes];
    if(!p)return NO;
	needToSwap = NO;
	uint32_t theDataId;
	if((*p & 0xffff0000) == 0x3C3F0000){
		//old style header with no orca header info, just starts "<?xm" which is 0x3c3f
		//ascii does need to be swapped so it's not clear if this was written on a big endian mac or a little endian mac
		//however, this style was ONLY produced on a big endian mac so that is what we will assume...
		return YES;
	}
	if((*p & 0x0000ffff) == 0x00003f3c){
		//old style header with no orca header info, just starts "<?xm" which is 0x3c3f (but swapped here)
		//ascii does need to be swapped so it's not clear if this was written on a big endian mac or a little endian mac
		//however, this style was ONLY produced on a big endian mac so that is what we will assume...
		needToSwap = YES;
		return YES;
	}
	if((*p & 0xffff0000) != 0x0000){
		//the dataID for the header is always zero the length of the record is always non-zero -- this
		//gives us a way to determine endian-ness 
		needToSwap = YES;
		theDataId = ExtractDataId(CFSwapInt32((uint32_t)*p));
	}
	else theDataId = ExtractDataId(*p);	
	
	if(theDataId == 0x00000000){
		p++;	//in valid file the second word is the length
		p++;	//third word should be start of xml header
		NSString* headerString = [[[NSString alloc] initWithBytes:p length:50 encoding:NSASCIIStringEncoding] autorelease];
		if([headerString rangeOfString:@"xml"].location != NSNotFound){
			return YES;
		}
		else return NO;
	}
	else return NO;
}


- (void) loadHeader:(uint32_t*)p
{
	p++;	 //point to header length
	uint32_t headerLength = *p; //bytes
	if(needToSwap)	headerLength = CFSwapInt32((uint32_t)headerLength);
	p++;	 //point to header itself
	NSString* theHeader = [[NSString alloc] initWithBytes:p length:headerLength encoding:NSASCIIStringEncoding];
    id plist = nil;
    @try  {
        plist = [theHeader propertyList];
    }
    @catch (NSException* e){
        
    }
	[self setFileHeader:plist];
	[theHeader release];
}

- (NSData*) headerAsData
{
    //write header to temp file because we want the form you get from a disk file...the string to property list isn't right.
    NSString* tempName = [NSFileManager tempPathInAppSupportFolderUsingTemplate:@"OrcaHeaderXXX"];
    BOOL result = [fileHeader writeToFile:tempName atomically:YES];
    if(!result){
        NSLog(@"ORDecoder:: Could not create header. This is most likely caused by non-complient object(s) in the header.\n");
        return nil;
    }
    NSData* dataBlock = [NSData dataWithContentsOfFile:tempName];
	uint32_t headerLength        = (uint32_t)[dataBlock length];											//in bytes
	uint32_t lengthWhenPadded    = sizeof(int32_t)*(round(.5 + headerLength/(float)sizeof(int32_t)));					//in bytes
	uint32_t padSize             = lengthWhenPadded - headerLength;							//in bytes
	uint32_t totalLength		  = 2 + (lengthWhenPadded/4);									//in longs
	uint32_t theHeaderWord = 0 | (0x1ffff & totalLength);										//compose the header word
	NSMutableData* data = [NSMutableData dataWithBytes:&theHeaderWord length:sizeof(int32_t)];			//add the header word
	[data appendBytes:&headerLength length:sizeof(int32_t)];											//add the header len in bytes
	
	[data appendData:dataBlock];
	
	//pad to nearest int32_t word
	unsigned char padByte = 0;
	int i;
	for(i=0;i<padSize;i++){
		[data appendBytes:&padByte length:1];
	}
	
    [[NSFileManager defaultManager] removeItemAtPath:tempName error:nil];
    
    return data;
}

@end
