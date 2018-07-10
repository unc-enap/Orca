//
//  OR3DScanPlatformController.h
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Forward Declarations
@class OR3DScanPlatformView;
@class ORVXMMotor;

@interface OR3DScanPlatformController : OrcaObjectController
{
	IBOutlet ORGroupView*           subComponentsView;
    IBOutlet NSButton*              lockButton;
    IBOutlet OR3DScanPlatformView*  view3D;
    
    IBOutlet NSTextField*           rotationSpeedText;
    IBOutlet NSTextField*           currentAngleText;
    IBOutlet NSTextField*           targetAngleText;
    IBOutlet NSButton*              rotationGoAbsButton;
    IBOutlet NSButton*              rotationGoRelButton;
    IBOutlet NSButton*              rotationHomePlusButton;
    IBOutlet NSButton*              rotationHomeMinusButton;
    
    IBOutlet NSTextField*           zSpeedText;
    IBOutlet NSTextField*           currentZText;
    IBOutlet NSTextField*           targetZText;
    IBOutlet NSButton*              zGoAbsButton;
    IBOutlet NSButton*              zGoRelButton;
    IBOutlet NSButton*              zHomePlusButton;
    IBOutlet NSButton*              zHomeMinusButton;
    
    IBOutlet NSButton*              stopButton;
    
    double rotationConversion; //steps per angle
    double zConversion; //steps per block of OpenGL space
    int rotatingMotorNum;
    int zMotorNum;
    
    double currentAngle;
    int motorAngle;
    double currentZ, motorZ;
    
    double rotation; //how much model should rotate when displayed
    double trans; //how much model moves in z direction
    int maxZ;
    
    double rotationSpeed, translationSpeed;
}

- (id) init;
- (void) awakeFromNib;
- (double) getRotation;
- (double) getTrans;
- (void) updateButtons;
- (ORVXMMotor*) rotatingMotor;
- (ORVXMMotor*) zMotor;
- (void) updateTranslation;
- (void) updateRotation;

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) lockChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)aNote;
- (void) cmdTypeExecutingChanged:(NSNotification*)aNotification;
- (void) motorSpeedChanged:(NSNotification*)aNotification;
- (void) motorTargetChanged:(NSNotification*)aNotification;
- (void) motorPositionChanged:(NSNotification*)aNotification;

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender;
- (IBAction) stopAction:(id) sender;

- (IBAction) angleAction:(id) sender;
- (IBAction) rotationSpeedAction:(id)sender;
- (IBAction) rotationGoAbsAction:(id) sender;
- (IBAction) rotationGoRelAction:(id) sender;
- (IBAction) rotationHomePlusAction:(id) sender;
- (IBAction) rotationHomeMinusAction:(id) sender;

- (IBAction) zAction:(id)sender;
- (IBAction) zSpeedAction:(id)sender;
- (IBAction) zGoAbsAction:(id) sender;
- (IBAction) zGoRelAction:(id) sender;
- (IBAction) zHomePlusAction:(id) sender;
- (IBAction) zHomeMinusAction:(id) sender;

@end