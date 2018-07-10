//
//  NSWindow+Extensions.m
//  Orca
//
//  Created by Mark Howe on Thu Jan 7 2010.
//  Copyright (c) 2010. University of North Carolina. All rights reserved.
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

@implementation NSWindow (NSWindowAdditions)

- (BOOL) endEditing;
{
	bool success;
	id responder = [self firstResponder];
	
	// If we're dealing with the field editor, the real first responder is
	// its delegate.
	
	if ( (responder != nil) && [responder isKindOfClass:[NSTextView class]] && [(NSTextView*)responder isFieldEditor] )
		responder = ( [[responder delegate] isKindOfClass:[NSResponder class]] ) ? [responder delegate] : nil;
	
	success = [self makeFirstResponder:nil];
	
	// Return first responder status.
	
	if ( success && responder != nil )
		[self makeFirstResponder:responder];
	
	return success;
}

- (void) forceEndEditing;
{
	[self endEditingFor:nil];
}

@end