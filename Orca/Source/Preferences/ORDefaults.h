/*
 *  ORDefaults.h
 *  Orca
 *
 //  Created by Mark Howe on Sat Dec 28 2002.
 //  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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



#pragma mark •••StringDefinitions
//If you add to the list of defaults, don't forget to set up and register the default values
//in ORAppDelegate's Initialize method.
#define  ORBackgroundColor          @"OR Document Background Color"
#define  ORLineColor                @"OR Connection Line Color"
#define  ORLineType                 @"OR Connection Line Type"
#define  OROpeningDocPreferences    @"OR Opening Document Preferences"
#define  OROpeningDialogPreferences @"OR Opening Dialog Preferences"
#define  OROrcaSecurityEnabled      @"Orca Security Enabled"
#define  OROrcaPassword             @"Orca Password"
#define  ORGlobalSecurityStateChanged  @"ORGlobalSecurityStateChanged"
#define  ORNormalShutDownFlag       @"ORNormalShutDownFlag"
#define  ORWasInDebuggerFlag        @"ORWasInDebuggerFlag"
#define  ORMailBugReportFlag	    @"ORMailBugReportFlag"
#define  ORMailBugReportEMail       @"ORMailBugReportEMail"

#define  ORScriptBackgroundColor    @"ORScriptBackgroundColor"
#define  ORScriptCommentColor       @"ORScriptCommentColor"
#define  ORScriptStringColor        @"ORScriptStringColor"
#define  ORScriptIdentifier1Color   @"ORScriptIdentifier1Color"
#define  ORScriptIdentifier2Color   @"ORScriptIdentifier2Color"
#define  ORScriptConstantsColor		@"ORScriptConstantsColor"

#define  ORPrefHeartBeatEnabled		@"ORPrefHeartBeatEnabled"
#define  ORPrefHeartBeatPath		@"ORPrefHeartBeatPath"
#define  ORPrefPostLogEnabled		@"ORPrefPostLogEnabled"

#define ORMailSelectionPreference   @"ORMailSelectionPreference"
#define ORMailServer                @"ORMailServer"
#define ORMailAddress               @"ORMailAddress"
#define ORMailPassword              @"ORMailPassword"

enum {
    straightLines,
    squareLines,
    curvedLines
};


#pragma mark •••Notification Strings
#define  ORBackgroundColorChangedNotification 	@"ORBackgroundColorChangedNotification"
#define  ORLineColorChangedNotification         @"ORLineColorChangedNotification"
#define  ORLineTypeChangedNotification          @"ORLineTypeChangedNotification"
#define  ORSyntaxColorChangedNotification		@"ORSyntaxColorChangedNotification"
#define  ORPrefHeartBeatEnabledChanged			@"ORPrefHeartBeatEnabledChanged"
#define  ORPrefHeartBeatEnabledChanged			@"ORPrefHeartBeatEnabledChanged"
#define  ORPrefHeartBeatPathChanged				@"ORPrefHeartBeatPathChanged"
#define  ORPrefPostLogEnabledChanged			@"ORPrefPostLogEnabledChanged"

#pragma mark •••Other Definiations
#define  ORLastDocumentName                     @"OR Last Document Name"
#define  ORHelpFilesUseDefault					@"ORHelpFilesUseDefault"
#define  ORHelpFilesPath						@"ORHelpFilesPath"
#define  ORHelpFilesPathChanged					@"ORHelpFilesPathChanged"


#pragma mark •••Helpers
NSData* dataForColor(NSColor* aColor);
NSColor* colorForData(NSData* data);
