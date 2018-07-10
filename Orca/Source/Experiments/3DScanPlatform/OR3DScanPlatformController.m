
//
//  OR3DScanPlatformController.m
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


#pragma mark •••Imported Files
#import "OR3DScanPlatformController.h"
#import "OR3DScanPlatformModel.h"
#import "OR3DScanPlatformView.h"
#import "ORVXMModel.h"
#import "ORVXMMotor.h"
#include "math.h"

@implementation OR3DScanPlatformController
- (id) init
{
    self = [super initWithWindowNibName:@"3DScanPlatform"];
    
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    rotationConversion = 1;
    zConversion = 31500;
    rotatingMotorNum = 1;
    zMotorNum = 0;
    
    currentAngle = 0;
    motorAngle = 0;
    currentZ = 0;
    motorZ = 0;
    rotation = 0;
    trans = 0;
    
    maxZ = 16551;

    [currentAngleText setFloatValue:currentAngle];
    [currentZText setFloatValue:currentZ];
    [rotationSpeedText setIntValue:[[self rotatingMotor] motorSpeed]];
    [zSpeedText setIntValue:[[self zMotor] motorSpeed]];
    [targetAngleText setIntValue:[[self rotatingMotor] targetPosition]];
    [targetZText setIntValue:[[self zMotor] targetPosition]];
	
    [subComponentsView setGroup:model];
	[super awakeFromNib];
}

- (double) getRotation
{
    return rotation;
}

- (double) getTrans
{
    return trans;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   

	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : OR3DScanPlatformLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorTargetChanged:)
                         name : ORVXMMotorTargetChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorPositionChanged:)
                         name : ORVXMMotorPositionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(cmdTypeExecutingChanged:)
                         name : ORVXMModelCmdTypeExecutingChanged
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(motorSpeedChanged:)
                         name : ORVXMMotorSpeedChanged
						object: nil];
}

- (void) updateWindow
{
    [super updateWindow];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:OR3DScanPlatformLock];
    [lockButton setState: locked];
}

- (void) updateButtons
{
    //BOOL locked = [gSecurity isLocked:ORVXMLock];
    BOOL locked = NO;
    int cmdExecuting = [[model findMotorModel] cmdTypeExecuting];

	[stopButton setEnabled:cmdExecuting];
    
    [rotationGoAbsButton setEnabled:!locked && !cmdExecuting];
    [rotationGoRelButton setEnabled:!locked && !cmdExecuting];
    [rotationHomePlusButton setEnabled:!locked && !cmdExecuting];
    [rotationHomeMinusButton setEnabled:!locked && !cmdExecuting];
	[zGoAbsButton setEnabled:!locked && !cmdExecuting];
    [zGoRelButton setEnabled:!locked && !cmdExecuting];
    [zHomePlusButton setEnabled:!locked && !cmdExecuting];
    [zHomeMinusButton setEnabled:!locked && !cmdExecuting];
}

- (void) cmdTypeExecutingChanged:(NSNotification*)aNotification
{
    [self updateButtons];
}

- (void) motorTargetChanged:(NSNotification*)aNotification
{
    if([aNotification object] == [model findMotorModel])
    {
        if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [self rotatingMotor])
        {
            int angle = (ceil([[self rotatingMotor] targetPosition] / rotationConversion));
            [targetAngleText setIntValue:angle];
        }
        
        else if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [self zMotor])
        {
            [targetZText setIntValue:[[self zMotor] targetPosition]];
        }
    }
}

- (void) motorSpeedChanged:(NSNotification*)aNotification
{
    if([aNotification object] == [model findMotorModel])
    {
        if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [self rotatingMotor])
            [rotationSpeedText setIntValue:[[self rotatingMotor] motorSpeed]];
        
        else if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [self zMotor])
            [zSpeedText setIntValue:[[self zMotor] motorSpeed]];
    }
}

- (void) motorPositionChanged:(NSNotification*)aNotification
{
    if([aNotification object] == [model findMotorModel])
    {
        if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [self rotatingMotor])
        {            
            if([[self rotatingMotor] absoluteMotion])
                motorAngle = [[self rotatingMotor] motorPosition] / rotationConversion;
            else
                motorAngle += [[self rotatingMotor] targetPosition] / rotationConversion;
    
            rotationSpeed = 100;
            if(currentAngle >= motorAngle + .5 || currentAngle <= motorAngle - .5)
                [self performSelector:@selector(updateRotation) withObject:nil afterDelay:.01];
        }
        
        else if([[aNotification userInfo] objectForKey:@"VMXMotor"] == [self zMotor])
        {
            if([[self zMotor] absoluteMotion])
                motorZ = [[self zMotor] motorPosition];
            else
                motorZ += [[self zMotor] targetPosition];
            
            translationSpeed = 10000;
            if(currentZ >= motorZ + 100 || currentZ <= motorZ - 100)
                [self performSelector:@selector(updateTranslation) withObject:nil afterDelay:.01];
        }
    }
}

- (void) updateRotation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateRotation) object:nil];

    if(currentAngle < motorAngle)
    {
        rotation += .5;
        currentAngle += .5;
    }
    else
    {
        rotation -= .5;
        currentAngle -= .5;
    }
    
    [currentAngleText setFloatValue:currentAngle];
    [view3D setNeedsDisplay:YES];
    
    if(currentAngle >= motorAngle + .5 || currentAngle <= motorAngle - .5)
        [self performSelector:@selector(updateRotation) withObject:nil afterDelay:.5/rotationSpeed];
}

- (void) updateTranslation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTranslation) object:nil];
    
    if(currentZ < motorZ)
    {
        trans += 100 / zConversion;
        currentZ += 100;
    }
    else
    {
        trans -= 100 / zConversion;
        currentZ -= 100;
    }
    
    [currentZText setFloatValue:currentZ];
    [view3D setNeedsDisplay:YES];
    
    if(currentZ >= motorZ + 100 || currentZ <= motorZ - 100)
        [self performSelector:@selector(updateTranslation) withObject:nil afterDelay:100/translationSpeed];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OR3DScanPlatformLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:OR3DScanPlatformLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) angleAction:(id) sender
{
    int steps = floor(rotationConversion * [sender floatValue]);
    [[self rotatingMotor] setTargetPosition:steps];
}

- (IBAction) zAction:(id)sender
{
    [[self zMotor] setTargetPosition:[sender floatValue]];
}

- (IBAction) zSpeedAction:(id)sender
{
    [[self zMotor] setMotorSpeed:[sender intValue]];
}

- (IBAction) rotationSpeedAction:(id) sender
{
    [[self rotatingMotor] setMotorSpeed:[sender intValue]];
}

- (IBAction) rotationGoAbsAction:(id) sender
{
    [self endEditing];
    [[self rotatingMotor] setAbsoluteMotion:YES];
    [[model findMotorModel] move:rotatingMotorNum to:[[self rotatingMotor] targetPosition] speed:[[self rotatingMotor] motorSpeed]];
    
    motorAngle = [[self rotatingMotor] targetPosition] / rotationConversion; //start animating when go is pressed
    rotationSpeed = [[self rotatingMotor] motorSpeed];
    if(currentAngle >= motorAngle + .5 || currentAngle <= motorAngle - .5)
        [self performSelector:@selector(updateRotation) withObject:nil afterDelay:.01];
}

- (IBAction) zGoAbsAction:(id)sender
{
    [self endEditing];
    [[self zMotor] setAbsoluteMotion:YES];
    [[model findMotorModel] move:zMotorNum to:[[self zMotor] targetPosition] speed:[[self zMotor] motorSpeed]];
    
    motorZ = [[self zMotor] targetPosition]; //start animating when go is pressed
    translationSpeed = [[self zMotor] motorSpeed];
    if(currentZ >= motorZ + 100 || currentZ <= motorZ - 100)
        [self performSelector:@selector(updateTranslation) withObject:nil afterDelay:.01];
}

- (IBAction) rotationGoRelAction:(id)sender
{
    [self endEditing];
    [[self rotatingMotor] setAbsoluteMotion:YES];
    [[model findMotorModel] move:rotatingMotorNum dx:[[self rotatingMotor] targetPosition] speed:[[self rotatingMotor] motorSpeed]];
    
    motorAngle += [[self rotatingMotor] targetPosition] / rotationConversion; //start animating when go is pressed
    rotationSpeed = [[self rotatingMotor] motorSpeed];
    if(currentAngle >= motorAngle + .5 || currentAngle <= motorAngle - .5)
        [self performSelector:@selector(updateRotation) withObject:nil afterDelay:.01];
}

- (IBAction) zGoRelAction:(id)sender
{
    [self endEditing];
    [[self zMotor] setAbsoluteMotion:YES];
    [[model findMotorModel] move:zMotorNum dx:[[self zMotor] targetPosition] speed:[[self zMotor] motorSpeed]];
    
    motorZ += [[self zMotor] targetPosition]; //start animating when go is pressed
    translationSpeed = [[self zMotor] motorSpeed];
    if(currentZ >= motorZ + 100 || currentZ <= motorZ - 100)
        [self performSelector:@selector(updateTranslation) withObject:nil afterDelay:.01];
}

- (IBAction) stopAction:(id)sender
{
    [[model findMotorModel] stopAllMotion];
}

- (IBAction) rotationHomePlusAction:(id) sender
{
    [[model findMotorModel] goHome:rotatingMotorNum plusDirection:YES];
    
    //potentially animate when button is pressed
}

- (IBAction) zHomePlusAction:(id) sender
{
    [[model findMotorModel] goHome:zMotorNum plusDirection:YES];
    
    motorZ = maxZ; //start animating when button is pressed
    translationSpeed = [[self zMotor] motorSpeed];
    if(currentZ >= motorZ + 100 || currentZ <= motorZ - 100)
        [self performSelector:@selector(updateTranslation) withObject:nil afterDelay:.01];
}

- (IBAction) rotationHomeMinusAction:(id)sender
{
    [[model findMotorModel] goHome:rotatingMotorNum plusDirection:NO];

    //potentially animate when button is pressed
}

- (IBAction) zHomeMinusAction:(id)sender
{
    [[model findMotorModel] goHome:zMotorNum plusDirection:NO];
    
    motorZ = 0; //start animating when button is pressed
    translationSpeed = [[self zMotor] motorSpeed];
    if(currentZ >= motorZ + 100 || currentZ <= motorZ - 100)
        [self performSelector:@selector(updateTranslation) withObject:nil afterDelay:.01];
}

- (ORVXMMotor*) rotatingMotor
{
    return [[model findMotorModel] motor:rotatingMotorNum];
}

- (ORVXMMotor*) zMotor
{
    return [[model findMotorModel] motor:zMotorNum];
}

@end