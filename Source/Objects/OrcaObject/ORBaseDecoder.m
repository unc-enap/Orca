//
//  ORBaseDecoder.m
//  Orca
//
//  Created by Mark Howe on 1/21/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORBaseDecoder.h"
#import "ORDataSet.h"
#import "ORGlobal.h"
#import <stdarg.h>

static NSString* kChanKey[32] = {
	//pre-make some keys for speed.
	@"Channel  0", @"Channel  1", @"Channel  2", @"Channel  3",
	@"Channel  4", @"Channel  5", @"Channel  6", @"Channel  7",
	@"Channel  8", @"Channel  9", @"Channel 10", @"Channel 11",
	@"Channel 12", @"Channel 13", @"Channel 14", @"Channel 15",
	@"Channel 16", @"Channel 17", @"Channel 18", @"Channel 19",
	@"Channel 20", @"Channel 21", @"Channel 22", @"Channel 23",
	@"Channel 24", @"Channel 25", @"Channel 26", @"Channel 27",
	@"Channel 28", @"Channel 29", @"Channel 30", @"Channel 31"
};

static NSString* kCardKey[32] = {
	//pre-make some keys for speed.
	@"Card  0", @"Card  1", @"Card  2", @"Card  3",
	@"Card  4", @"Card  5", @"Card  6", @"Card  7",
	@"Card  8", @"Card  9", @"Card 10", @"Card 11",
	@"Card 12", @"Card 13", @"Card 14", @"Card 15",
	@"Card 16", @"Card 17", @"Card 18", @"Card 19",
	@"Card 20", @"Card 21", @"Card 22", @"Card 23",
	@"Card 24", @"Card 25", @"Card 26", @"Card 27",
	@"Card 28", @"Card 29", @"Card 30", @"Card 31"
};

static NSString* kCrateKey[16] = {
	//pre-make some keys for speed.
	@"Crate  0", @"Crate  1", @"Crate  2", @"Crate  3",
	@"Crate  4", @"Crate  5", @"Crate  6", @"Crate  7",
	@"Crate  8", @"Crate  9", @"Crate 10", @"Crate 11",
	@"Crate 12", @"Crate 13", @"Crate 14", @"Crate 15"
};

@implementation ORBaseDecoder
- (id) init
{
	self = [super init];
	[self registerNotifications];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[cachedObjectsLock lock];
	[cachedObjects release];
	[cachedObjectsLock unlock];
	[cachedObjectsLock release];
    [decoderOptions release];
    [super dealloc];
}

- (void) registerNotifications
{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];//just in case
	[nc addObserver:self selector:@selector(runStarted:) name:ORRunStartedNotification object:nil];
	[nc addObserver:self selector:@selector(runStopped:) name:ORRunStoppedNotification object:nil];
}

- (void) setSkipRateCounts:(BOOL)aState
{
    skipRateCounts = aState;
}
- (BOOL) skipRateCounts
{
    return skipRateCounts;
}


- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runStopped:(NSNotification*)aNote
{
}


- (NSString*) getChannelKey:(unsigned short)aChan
{
	if(aChan<32) return kChanKey[aChan];
	else return [NSString stringWithFormat:@"Channel %2d",aChan];	
}

- (NSString*) getCardKey:(unsigned short)aCard
{
	if(aCard<16) return kCardKey[aCard];
	else return [NSString stringWithFormat:@"Card %2d",aCard];		
	
}
- (NSString*) getCrateKey:(unsigned short)aCrate
{
	if(aCrate<16) return kCrateKey[aCrate];
	else return [NSString stringWithFormat:@"Crate %2d",aCrate];		
}

- (void) swapData:(void*)someData
{
	uint32_t* ptr = (uint32_t*)someData;
	*ptr = CFSwapInt32(*ptr);
	uint32_t length = ExtractLength(*ptr);
	uint32_t i;
	for(i=1;i<length;i++){
		ptr[i] = CFSwapInt32(ptr[i]);
	}
}

- (id) objectForNestedKey:(NSString*)firstKey,...
{
	[cachedObjectsLock lock];
	va_list args;
	va_start(args, firstKey);
	id objectToReturn = [[[cachedObjects nestedObjectForKeyList:firstKey withvaList:args] retain] autorelease];
	va_end(args);
	[cachedObjectsLock unlock];
	return objectToReturn;
}

- (void) setUpCacheUsingHeader:(NSDictionary*)aHeader;
{
	//each decoder can initialize it's object cache....
}

- (NSArray*) extractArrayFromHeader:(NSDictionary*)aHeader forKey:(id)aKey
{
	return [aHeader objectForKey:aKey];
}

- (void) setObject:(id)obj forNestedKey:(NSString*)firstKey,...
{
	[cachedObjectsLock lock];
		if(!cachedObjects)cachedObjects = [[NSMutableDictionary dictionary] retain];
    va_list myArgs;

	//count the args
	int count = 0;
	va_start(myArgs,firstKey);
	
	while(va_arg(myArgs, NSString *)) count++;


	//now loop over the args. The last one is special....
	int argIndex = 0;
    va_start(myArgs,firstKey);
	NSString* s = firstKey;
	if(count>1){
		NSMutableDictionary* lastDictionary = [cachedObjects objectForKey:s];
		if(!lastDictionary) {
			lastDictionary = [NSMutableDictionary dictionary];
			[cachedObjects setObject:lastDictionary forKey:s];
		}
		while((s = va_arg(myArgs, NSString *))) {
			argIndex++;
			if(argIndex>=count){
				[lastDictionary setObject: obj forKey:s];
			}
			else {
				NSMutableDictionary* aDictionary = [lastDictionary objectForKey:s];
				if(!aDictionary) {
					aDictionary = [NSMutableDictionary dictionary];
					[lastDictionary setObject:aDictionary forKey:s];
				}
				lastDictionary = aDictionary;
			}
		}
	}
	else [cachedObjects setObject: obj forKey:firstKey];
	
    va_end(myArgs);
	[cachedObjectsLock unlock];
}

- (BOOL) cacheSetUp
{
	[cachedObjectsLock lock];
	BOOL result =  (cachedObjects!=nil);
	[cachedObjectsLock unlock];
	return result;
}

- (void) cacheCardLevelObject:(id)aKey fromHeader:(NSDictionary*)aHeader
{
	[cachedObjectsLock lock];
	if(!cachedObjects)cachedObjects = [[NSMutableDictionary dictionary] retain];
	
	//set up the crate cache
	NSArray* crates = [aHeader nestedObjectForKey:@"ObjectInfo",@"Crates",nil];
	int crateIndex;
	for(crateIndex=0;crateIndex<[crates count];crateIndex++){
	
		NSDictionary* headerCrateDictionary = [crates objectAtIndex:crateIndex];
		id crateKey = [self getCrateKey:[[headerCrateDictionary objectForKey:@"CrateNumber"] intValue]];
		
		NSMutableDictionary* cachedCrateDictionary = [cachedObjects objectForKey:crateKey]; //use existing one if possible
		if(!cachedCrateDictionary) {														//otherwise
			cachedCrateDictionary = [NSMutableDictionary dictionary];						//create one
			[cachedObjects setObject:cachedCrateDictionary forKey:crateKey];
		}
		
		//set up the card cache
		NSArray* cards = [headerCrateDictionary objectForKey:@"Cards"];
		int cardIndex;
		for(cardIndex=0;cardIndex<[cards count];cardIndex++){
			NSDictionary* headerCardDictionary = [cards objectAtIndex:cardIndex];
			id cardKey = [self getCardKey:[[headerCardDictionary objectForKey:@"Card"] intValue]];
			
			NSMutableDictionary* cachedCardDictionary = [cachedCrateDictionary objectForKey:cardKey];	//use existing one if possible
			if(!cachedCardDictionary){															//otherwise
				cachedCardDictionary= [NSMutableDictionary dictionary];							//create one
				[cachedCrateDictionary setObject:cachedCardDictionary forKey:cardKey];
			}
			
			id objectToCache = [headerCardDictionary objectForKey:aKey];
			if(objectToCache)[cachedCardDictionary setObject:objectToCache  forKey:aKey];
		}
	}
	[cachedObjectsLock unlock];
}

@end
