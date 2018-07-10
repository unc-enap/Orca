//
//  ORRecordIndexer.m
//  OrcaIntel
//
//  Created by Mark Howe on 11/14/2009.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
//
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

#import "ORRecordIndexer.h"
#import "ORBaseDecoder.h"
#import "ORDataExplorerModel.h"
#import "ORHeaderItem.h"

#define kAmountToRead 5*1024*1024

@implementation ORRecordIndexer
- (id)initWithPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super initWithPath:aPath delegate:aDelegate];
	fileOffset = 0;
	nameCatalog = [[NSMutableDictionary dictionary] retain];
    return self;
}

- (void) dealloc
{
	if([delegate respondsToSelector:@selector(checkStatus)]){
		[delegate performSelectorOnMainThread:@selector(checkStatus)
								   withObject:nil
								waitUntilDone:YES];
	}
	[nameCatalog release];
	[dataToProcess release];
	[fileAsData release];
	[super dealloc];
}


- (void) main 
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	if(currentDecoder){
        @try {
            long long dataSizeLimit = 2.0e9;
            NSLog(@"Data Explorer: Opening %@\n",filePath);
            NSError*      attributesError;
            NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attributesError];
            long long     fileSize       = [[fileAttributes objectForKey:NSFileSize] longLongValue];
            NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
            if(fileSize < dataSizeLimit){
                fileAsData = [[fh readDataToEndOfFile] retain];
            }
            else {
                fileAsData = [[fh readDataOfLength:dataSizeLimit*.5] retain];
                NSLogColor([NSColor redColor],@"Data Explorer: Truncating the parse of %@ to 1GB\n",filePath);
                NSLogColor([NSColor redColor],@"Data Explorer: Parse will probably report corrupt last record\n");
            }
            [fh closeFile];
            [delegate setDataRecords:[self decodeDataIntoArray]];
            [delegate setHeader:[ORHeaderItem headerFromObject:[currentDecoder fileHeader] named:@"Root"]];
        }
        @catch(NSException* e){
            NSLogColor([NSColor redColor],@"Data Explorer: File too big -- out of memory\n");
            [delegate setDataRecords:nil];
            [delegate setHeader:nil];
        }
	}
	
	if([delegate respondsToSelector:@selector(updateProgress:)]){
		[delegate performSelectorOnMainThread:@selector(updateProgress:)
								   withObject:[NSNumber numberWithFloat:100.]
								waitUntilDone:YES];
	}
	
	if([delegate respondsToSelector:@selector(parseEnded)]){
		[delegate performSelectorOnMainThread:@selector(parseEnded)
								   withObject:nil
								waitUntilDone:YES];
	}
    [thePool release];
}

- (NSArray*) decodeDataIntoArray
{
	NSAutoreleasePool *pool = nil;
	@try {
		array = [NSMutableArray arrayWithCapacity:1024*1000];
		NSNumber* aKey;
		long length = [fileAsData length]/sizeof(long);
		unsigned long decodedLength;
		unsigned long* dPtr = (unsigned long*)[fileAsData bytes];
		unsigned long* start = dPtr;
		unsigned long* end = start + [fileAsData length]/4;
		if([delegate respondsToSelector:@selector(setTotalLength:)]){
			[delegate setTotalLength:length];
		}
		nameCatalog = [[NSMutableDictionary dictionary] retain];
		NSNumber* decodedFlag = [NSNumber numberWithBool:NO];
		do {
			if(!dPtr)break;
			NSAutoreleasePool *innerPool = [[NSAutoreleasePool allocWithZone:nil] init];
			
			id anObj = nil;
			//get length from the first word.
			unsigned long val = *dPtr;
			if(needToSwap)val = CFSwapInt32(val); //if data is from old PPC file, must swap.
			aKey		  = [NSNumber  numberWithLong:ExtractDataId(val)];
			decodedLength = ExtractLength(val);
			anObj		  = [[currentDecoder objectLookup] objectForKey:aKey];
			
				NSString* shortName = [nameCatalog objectForKey:aKey];
				if(!shortName){
					NSString* sname = [[NSStringFromClass([anObj class]) componentsSeparatedByString:@"DecoderFor"] componentsJoinedByString:@" "];
					if([aKey intValue]==0 && [sname rangeOfString:@"Record"].location!=NSNotFound){
						sname = @"Header";
					}
					else if([sname hasPrefix:@"OR"]){
						sname = [sname substringFromIndex:2];
					}
					else if([sname hasSuffix:@"Run"]){
						sname = [sname substringToIndex:[sname length]-3];
						sname = [sname stringByAppendingString:@"Control"];
					}
                    else {
                        sname = [NSString stringWithFormat:@"unKnown(0x%x %lu)",[aKey intValue],decodedLength];
                    }
					[nameCatalog setObject:sname forKey:aKey]; 
					shortName = sname;
				}
				
				if(decodedLength){
					if((dPtr+decodedLength) > end){
						NSLog(@"Parser stepped past end of file...\n");
						NSLog(@"Last Record in file appears corrupted:\n");
						NSLog(@"Object Name: %@\n",shortName);
						NSLog(@"Decoded Len: %d\n",decodedLength);
						NSLog(@"Length extends %d bytes past end of file\n",dPtr+decodedLength - end);
						[innerPool release];
						break;
					}
					else {
						unsigned long offset = dPtr - start;
						[array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
										  [NSNumber numberWithLong:decodedLength],@"Length",
										  shortName,@"Name",
										  aKey,@"Key",
										  decodedFlag,@"DecodedOnce",
										  [NSNumber numberWithLong:offset],@"StartingOffset",
										  nil]];
						dPtr+=decodedLength;
					}
				}
				else {
					[innerPool release];
					break; //can not continue with this record.. size was zero
				}
				length-=decodedLength;
				
				if([delegate respondsToSelector:@selector(setLengthDecoded:)]){
					[delegate setLengthDecoded:length];
				}
			
			[innerPool release];
		} while( length>0 );
	}
	@catch(NSException* localException) {
		[array release];
		array = nil;
	}
	
	[pool release];
	pool = nil;
	
	return array;
}

- (void) decodeOneRecordAtOffset:(unsigned long)anOffset intoDataSet:(ORDataSet*)aDataSet forKey:(NSNumber*)aKey
{
    unsigned long* dPtr = ((unsigned long*)[fileAsData bytes]) + anOffset;
    if(!dPtr)return;
	[currentDecoder decode:dPtr length:ExtractLength(*dPtr) intoDataSet:aDataSet];
}

- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset forKey:(NSNumber*)aKey
{
	if(needToSwap){
		unsigned long* dPtr = ((unsigned long*)[fileAsData bytes]) + anOffset;
		if(!dPtr)return;
		[[[currentDecoder objectLookup] objectForKey:aKey] swapData:dPtr];	
	}
}

- (NSString*) dataRecordDescription:(unsigned long)anOffset forKey:(NSNumber*)aKey
{	
    unsigned long* dataPtr = ((unsigned long*)[fileAsData bytes]) + anOffset;
	id anObj = [[currentDecoder objectLookup] objectForKey:aKey];
	if(anObj)return [anObj dataRecordDescription:dataPtr];
    else if([aKey intValue]==0)return @"Header";
	else return @"Not In DataDescription";
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    return @"?"; //place holder for compiler warning
}

- (NSString*) nameForDataID:(long)anID
{	
	NSNumber* aKey	= [NSNumber  numberWithLong:anID];
	NSString* shortName		= [nameCatalog objectForKey:aKey];
	if(!shortName) {
		id anObj = [currentDecoder objectForKey:aKey];
		NSString* sname = [[NSStringFromClass([anObj class]) componentsSeparatedByString:@"DecoderFor"] componentsJoinedByString:@" "];
		if(anID == 0){
			sname = @"Header";
		}
		else if([sname hasPrefix:@"OR"])     sname = [sname substringFromIndex:2];
		else if([sname hasSuffix:@"Run"]){
			sname = [sname substringToIndex:[sname length]-3];
			sname = [sname stringByAppendingString:@"Control"];
		}
		
		[nameCatalog setObject:sname forKey:aKey]; 
		shortName = sname;
	}
	return shortName;
		
}
@end
