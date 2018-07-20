//
//  ORFilterPluginBaseClass.h
//  Orca
//
//  Created by Mark Howe on 3/27/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import <time.h>
#import	"ORFilterSymbolTable.h"

#define display(A,B) [delegate setOutput:(A) withValue:(B)]
#define extractRecordID(A) [delegate extractRecordID:(A)]
#define extractRecordLen(A) [delegate extractRecordLen:(A)]
#define extractValue(A,B,C) [delegate extractValue:(A) mask:(B) thenShift:(C)]
#define shipRecord(A) [delegate shipRecord:(A) length:extractRecordLen(*A)]
#define push(A,B) [delegate pushOntoStack:(A) record:(B)]
#define pop(A) [delegate popFromStack:(A)]
#define bottomPop(A) [delegate popFromStackBottom:(A)]
#define shipStack(A) [delegate shipStack:(A)]
#define stackCount(A) [delegate stackCount:(A)]
#define dumpStack(A) [delegate dumpStack:(A)]
#define histo1D(A,B) [delegate histo1D:(A) value:(B)]
#define histo2D(A,B,C) [delegate histo2D:(A) x:(B) y:(C)]
#define stripChart(A,B,C) [delegate stripChart:(A) time:(B) value:(C)]
#define resetDisplays() [delegate resetDisplays]

@interface ORFilterPluginBaseClass : NSObject {
	@protected
		id delegate;
		ORFilterSymbolTable* symTable;
}
- (id)   initWithDelegate:(id)aDelegate;
- (void) setSymbolTable:(ORFilterSymbolTable*)aTable;
- (uint32_t*) ptr:(const char*)aKey;
- (uint32_t) value:(const char*)aKey;

- (void) start;
- (void) filter:(uint32_t*) currentRecordPtr length:(uint32_t)aLen;
- (void) finish;

@end

@interface NSObject (FilterBaseClass)
- (BOOL) record:(uint32_t*)aRecordPtr isEqualTo:(uint32_t)aValue;
- (uint32_t) extractRecordID:(uint32_t)aValue;
- (uint32_t) extractRecordLen:(uint32_t)aValue;
- (uint32_t) extractValue:(uint32_t)aValue mask:(uint32_t)aMask thenShift:(uint32_t)shift;
- (void) shipRecord:(uint32_t*)p length:(int32_t)length;
- (void) pushOntoStack:(int)i record:(uint32_t*)p;
- (uint32_t*) popFromStack:(int)i;
- (uint32_t*) popFromStackBottom:(int)i;
- (void) shipStack:(int)i;
- (int32_t) stackCount:(int)i;
- (void) dumpStack:(int)i;
- (void) histo1D:(int)i value:(uint32_t)aValue;
- (void) histo2D:(int)i x:(uint32_t)x y:(uint32_t)y;
- (void) stripChart:(int)i time:(uint32_t)aTimeIndex value:(uint32_t)aValue;
- (void) setOutput:(int)index withValue:(uint32_t)aValue;
- (void) resetDisplays;
@end