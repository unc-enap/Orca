//
//  ORDataTypeAssigner.h
//  Orca
//
//  Created by Mark Howe on 9/22/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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




#define kShortForm  YES
#define kLongForm   NO

#define kShortFormDataIdMask 0xfc000000
#define kLongFormDataIdMask 0xfffc0000
#define kLongFormLengthMask (~kLongFormDataIdMask)

#define IsShortForm(x) (((x)&0x80000000) >> 31)
#define IsLongForm(x) !IsShortForm(x)

#define ExtractDataId(x) (IsShortForm(x) ? ((x)&kShortFormDataIdMask) : ((x)&kLongFormDataIdMask))
#define ExtractLength(x) (IsShortForm(x) ? 1 : ((x) & ~kLongFormDataIdMask))

@interface ORDataTypeAssigner : NSObject {
    unsigned long shortDeviceType;
    unsigned long longDeviceType;  
}
- (void) reset;
- (void) assignDataIds;
- (unsigned long) assignDataIds:(BOOL)wantsShort;
- (unsigned long) reservedDataId:(NSString*)aClassName;
@end

@interface NSObject (ORDataTypeAssigner)
- (void) setDataIds:(id)obj;
- (void) syncDataIdsWith:(id)obj;
@end