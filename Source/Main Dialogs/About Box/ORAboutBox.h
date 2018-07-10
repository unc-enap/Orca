//
//  ORAboutBox.h
//  Orca
//
//  Created by Mark Howe on Tue Jan 08 2002.
//  Copyright  © 2001 CENPA. All rights reserved.
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


#pragma mark ¥¥¥Imported Files


@interface ORAboutBox : NSObject {
	@private
    IBOutlet id appNameField;
    IBOutlet id copyrightField;
    IBOutlet id creditsField;
    IBOutlet id versionField;
    NSArray* topLevelObjects;
    
#pragma mark ¥¥¥Instance Variables
    NSTimer *scrollTimer;
    float currentPosition;
    float maxScrollHeight;
    NSTimeInterval startTime;
    BOOL restartAtTop;
}

#pragma mark ¥¥¥Actions
- (IBAction)showAboutBox:(id)sender;

@end
