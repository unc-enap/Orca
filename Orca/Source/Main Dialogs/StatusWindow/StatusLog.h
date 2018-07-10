//
//  StatusLog.h
//  Redirects NSLog to logStatus.
//
//  Created by Mark Howe on Sunday, Oct 13,2002.
//  Copyright  � 2001 CENPA. All rights reserved.
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



void NSLogString(NSString* aString,...);
void NSLogColor(NSColor* aColor,NSString* aString,...);
void NSLogFont(NSFont* aFont,NSString* aString,...);
void NSLogMono(NSString* aString,...);
void NSLogStartTable(NSString* aString,int aWidth);
void NSLogDivider(NSString* aString,int aWidth);
void NSLogError(NSString* aString,...);
void NSLogAttr(NSAttributedString* aString);
#define NSLog NSLogString

