//
//  ORQueueView.h
//  Orca
//
//  Created by Mark Howe on Mon Mar 31 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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



@interface ORQueueView : NSView {
	IBOutlet id dataSource;
	NSColor* backgroundColor;
	NSColor* barColor;
    BOOL useSignedValues;
}

#pragma mark ¥¥¥Accessors
- (BOOL)useSignedValues;
- (void)setUseSignedValues:(BOOL)flag;
- (void) setBackgroundColor:(NSColor*)aColor;
- (NSColor*) backgroundColor;
- (void) setBarColor:(NSColor*)aColor;
- (NSColor*) barColor;


@end

@interface NSObject (ORQueueDataSource)
- (void) getQueMinValue:(unsigned long*)aMinValue maxValue:(unsigned long*)aMaxValue head:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue;
@end
