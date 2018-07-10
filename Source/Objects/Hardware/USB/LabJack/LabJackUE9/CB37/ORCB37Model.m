//
//  ORCB37Model.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
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
#import "ORCB37Model.h"
#import "ORLabJackUE9Model.h"

NSString* ORCB37Lock = @"ORCB37Lock";
NSString* ORCB37SlotChangedNotification = @"ORCB37SlotChangedNotification";

@implementation ORCB37Model

- (void) makeMainController
{
    [self linkToController:@"ORCB37Controller"];
}

-(void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"CB37"]];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"CB37"];
}
- (NSString*) cardSlotChangedNotification
{
    return ORCB37SlotChangedNotification;
}

- (short) numberSlotsUsed { return 1; }
- (Class) guardianClass	  { return NSClassFromString(@"ORLabJackUE9Model"); }

- (void) printChannelLocations
{
    char* CB37Name[24] = {"AIN0","AIN1","AIN2" ,"AIN3","AIN4" ,"AIN5","AIN6","AIN7",
                          "AIN8","AIN9","AIN10","AIN11","AIN12","AIN13",
                          "DAC0","DAC1",
                          "FIO0","FIO1","FIO2","FIO3","FIO4","FIO5","FIO6","FIO7"};
    int i;
    NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
    NSLogFont(font, @"LabJackUE9 (%d) Channel Map\n",[self uniqueIdNumber]);

    if([self slot]==0){
        for(i=0;i<4;i++)  NSLogFont(font,@"%2d Terminal Block AIN%d\n",i,i); 
        for(i=0;i<12;i++) NSLogFont(font,@"%2d X2 AIN%d\n",i,i);
        if([[self guardian] CB37Exists:1]){
            for(i=12;i<24;i++) NSLogFont(font,@"%2d X3 %s\n",i,CB37Name[i-12]);
        }
        else for(i=12;i<24;i++)NSLogFont(font,@"%2d UnAvailable\n",i);
    }
    else if([self slot]==1){
        for(i=12;i<36;i++) NSLogFont(font,@"%2d X3 %s\n",i,CB37Name[i-12]);
    }
    else if([self slot]==2){
        for(i=36;i<60;i++) NSLogFont(font,@"%2d X4 %s\n",i,CB37Name[i-36]);
    }
    else if([self slot]==3){
        for(i=60;i<84;i++) NSLogFont(font,@"%2d X5 %s\n",i,CB37Name[i-60]);
    }
}


@end



