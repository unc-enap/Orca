//
//  FilterScriptEx.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 25 2008.
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
#import "FilterScript.h"
#import "ORFilterSymbolTable.h"

@interface FilterScriptEx : NSObject
{
    unsigned short  switchLevel;
    int32_t			switchValue[512];
    ORFilterSymbolTable* symbolTable;
}
- (id) init;
- (void) setSymbolTable:(ORFilterSymbolTable*)aTable;
- (void) startFilterScript: (nodeType**)someNodes nodeCount:(int32_t)nodeCount delegate:(id) delegate;
- (void) finishFilterScript:(nodeType**)someNodes nodeCount:(int32_t)nodeCount delegate:(id) delegate;
- (void) runFilterNodes:    (nodeType**)someNodes nodeCount:(int32_t)nodeCount delegate:(id) delegate;
- (void) doSwitch:(nodeType*)p      delegate:(id)delegate;
- (void) doCase:(nodeType*)p        delegate:(id)delegate;
- (void) doDefault:(nodeType*)p     delegate:(id)delegate;
- (void) doLoop:(nodeType*)p        delegate:(id)delegate;
- (void) whileLoop:(nodeType*)p     delegate:(id)delegate;
- (void) forLoop:(nodeType*)p       delegate:(id)delegate;
- (void) defineArray:(nodeType*)p   delegate:(id)delegate;
- (void) freeArray:(nodeType*)p     delegate:(id)delegate;
- (uint32_t*) loadArray:(uint32_t*)ptr nodeType:(nodeType*)p;
- (void) arrayList:(nodeType*)p delegate:(id) delegate;
- (filterData) ex:(nodeType*)p delegate:(id) delegate;
- (id) finalPass:(id) string;
- (int) filterGraph:(nodeType*)p;
- (id) exNode:(nodeType*)p level:(int)aLevel lastChild:(BOOL) lastChild;

@end



