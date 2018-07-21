//
//  ORValidatePassword.m
//  Orca
//
//  Created by Mark Howe on Tue Feb 17 2004.
//  Copyright (c) 200
//  CENPA, University of Washington. All rights reserved.
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


#import "ORValidatePassword.h"

@interface ORValidatePassword (private)
- (void) _panelDidEnd:(id)sheet returnCode:(NSModalResponse)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _shakeIt;
@end

@implementation ORValidatePassword

+ (id) validateForWindow:(NSWindow *)aDocWindow modalDelegate:(id)aModalDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    ORValidatePassword* validatePassword = [[[ORValidatePassword alloc] init] retain];
    [validatePassword beginSheetForWindow:aDocWindow modalDelegate:aModalDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
    return validatePassword;
}

- (id) init
{
    self = [super initWithWindowNibName:@"ValidatePassword"];
    [self window];
    return self;
}

- (void) beginSheetForWindow:(NSWindow *)aDocWindow modalDelegate:(id)aModalDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(NSDictionary*)aContextInfo
{
    modalWindow = aDocWindow;
    modalDelegate = aModalDelegate; 
    didEndSelector = aDidEndSelector; 
    [aContextInfo retain];
//    [NSApp beginSheet:passWordPanel modalForWindow:aDocWindow modalDelegate:self didEndSelector:@selector(_panelDidEnd:returnCode:contextInfo:) contextInfo:aContextInfo];
    
    [aDocWindow beginSheet:passWordPanel completionHandler:^(NSModalResponse returnCode){
        [self _panelDidEnd:passWordPanel returnCode:returnCode contextInfo:aContextInfo];

    }];

    
}

- (IBAction)closePassWordPanel:(id)sender
{
    [passWordPanel orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [NSApp endSheet:passWordPanel returnCode:([sender tag] == 1) ? NSModalResponseOK : NSModalResponseCancel];
#else
    [NSApp endSheet:passWordPanel returnCode:([sender tag] == 1) ? NSOKButton : NSCancelButton];
#endif
    [self autorelease];
}


@end

@implementation ORValidatePassword (private)
- (void) _panelDidEnd:(id)sheet returnCode:(NSModalResponse)returnCode contextInfo:(NSDictionary*)userInfo
{
    int returnValue = kPasswordCancelled;
    if(returnCode == NSModalResponseOK){
        if([[passWordField stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword]]){
	    returnValue = kGoodPassword;
        }
        else {
	    //[self _shakeIt];
	    returnValue = kBadPassword;
        }
    }
    
    NSInvocation* invocation =  [NSInvocation invocationWithMethodSignature:[modalDelegate methodSignatureForSelector:didEndSelector]];
    [invocation setTarget:modalDelegate];
    [invocation setSelector:didEndSelector];
    [invocation setArgument:&passWordPanel atIndex:2];
    [invocation setArgument:&returnValue atIndex:3];
    [invocation setArgument:&userInfo atIndex:4];
    [invocation invoke];
    
    [self autorelease];
    [userInfo autorelease];
}

- (void) _shakeIt 
{
    NSRect theFrame = [modalWindow frame];
    NSRect startingFrame = theFrame;
    int i;
    float dis = 8;
    for(i=0;i<8;i++){
        if(i%2){
            theFrame.origin.x = startingFrame.origin.x + dis;
            dis = dis - 2.;
        }
        else {
            theFrame.origin.x = startingFrame.origin.x - dis;
       }
       [modalWindow setFrame:theFrame display:YES animate:YES];
  
    }
    [modalWindow setFrame:startingFrame display:YES animate:YES];
}

@end
