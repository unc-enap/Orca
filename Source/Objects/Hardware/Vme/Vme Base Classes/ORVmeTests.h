//
//  ORVmeTests.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 25 2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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
#import "ORAutoTestUnit.h"

@interface ORVmeReadWriteTest : ORAutoTestUnit {
	int type;
	unsigned long theOffset;
	unsigned long length;
	unsigned long validMask;
	short wordSize;
}
+ (id) test:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName;
+ (id) test:(unsigned long) anOffset  wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName;
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName;
- (void) runTest:(id)anObj;
@end

@interface ORVmeReadOnlyTest : ORVmeReadWriteTest {
}
+ (id) test:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName;
+ (id) test:(unsigned long) anOffset wordSize:(short)aWordSize name:(NSString*)aName;
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName;
@end

@interface ORVmeWriteOnlyTest : ORVmeReadWriteTest {
}
+ (id) test:(unsigned long) anOffset  wordSize:(short)aWordSize name:(NSString*)aName;
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName;
@end