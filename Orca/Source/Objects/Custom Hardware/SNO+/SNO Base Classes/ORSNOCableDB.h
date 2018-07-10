//
//  ORSNOCableDB.h
//  Orca
//
//  Created by Mark Howe on 12/16/08.
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

#import "ORSNOConstants.h"

#define kTubeTypeUnknown	0
#define kTubeTypeNormal		1
#define kTubeTypeOwl		2
#define kTubeTypeLowGain	3
#define kTubeTypeDeadTube	4
#define kTubeTypeButt		5
#define kTubeTypeNeck		6
#define kTubeTypeNumofTypes 7

/*static NSString* kTubeTypeNames[kTubeTypeNumofTypes] = {
	@"Unknown Tubes",
	@"Normal Tubes",
	@"OWL Tubes",
	@"Low Gain Tubes",
	@"Problem Tubes",
	@"BUTTS Tubes",
	@"Neck Tubes"
};
*/
@interface ORSNOCableDB : NSObject {
	NSString* cableDBFilePath;
	struct {			//Crate Level
		struct {		//Card Level
			struct {	//Pmt Level
				short tubeType;	//not only the type but tube problems,too.
				float x;
				float y;
				float z;
				NSString* pmtID;	
				NSString* cableID;
				NSString* paddleCardID;
			} Pmt[kNumSNOPmts];
		} Card[kNumSNOCards];			
	} SNOCrate[kMaxSNOCrates+2];	// + two spares
}
+ (ORSNOCableDB*) sharedSNOCableDB;
- (NSString*) cableDBFilePath;
- (void) setCableDBFilePath:(NSString*)aPath;
- (void) readCableDBFile;
- (void) decode:(NSString*)chanInfo crate:(int*)crate card:(int*)card channel:(int*) channel;
- (BOOL) getCrate:(int)aCrate card:(int)aCard channel:(int)aChannel x:(float*)x y:(float*)y;
- (int)  tubeTypeCrate:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (NSString*)  pmtID:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (NSColor*)  pmtColor:(int)aCrate card:(int)aCard channel:(int)aChannel;
@end

extern NSString* ORSNOCableDBReadIn;
