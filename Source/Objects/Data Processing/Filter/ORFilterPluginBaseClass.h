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
- (unsigned long*) ptr:(const char*)aKey;
- (unsigned long) value:(const char*)aKey;

- (void) start;
- (void) filter:(unsigned long*) currentRecordPtr length:(unsigned long)aLen;
- (void) finish;

@end

@interface NSObject (FilterBaseClass)
- (BOOL) record:(unsigned long*)aRecordPtr isEqualTo:(unsigned long)aValue;
- (unsigned long) extractRecordID:(unsigned long)aValue;
- (unsigned long) extractRecordLen:(unsigned long)aValue;
- (unsigned long) extractValue:(unsigned long)aValue mask:(unsigned long)aMask thenShift:(unsigned long)shift;
- (void) shipRecord:(unsigned long*)p length:(long)length;
- (void) pushOntoStack:(int)i record:(unsigned long*)p;
- (unsigned long*) popFromStack:(int)i;
- (unsigned long*) popFromStackBottom:(int)i;
- (void) shipStack:(int)i;
- (long) stackCount:(int)i;
- (void) dumpStack:(int)i;
- (void) histo1D:(int)i value:(unsigned long)aValue;
- (void) histo2D:(int)i x:(unsigned long)x y:(unsigned long)y;
- (void) stripChart:(int)i time:(unsigned long)aTimeIndex value:(unsigned long)aValue;
- (void) setOutput:(int)index withValue:(unsigned long)aValue;
- (void) resetDisplays;
@end