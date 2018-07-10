//
//  ORFPDSegmentGroup.m
//  Orca
//
//  Created by Mark Howe on 12/15/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORFPDSegmentGroup.h"
#import "ORDetectorSegment.h"

@implementation ORFPDSegmentGroup

#pragma mark •••Map Methods
- (void) readMap:(NSString*)aPath
{
 	[self setMapFile:aPath];
    NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
    BOOL oldFormat = [[[lines objectAtIndex:0] componentsSeparatedByString:@","] count] == 13;
	int index = -1;
	for(ORDetectorSegment* aSegment in segments){
		[aSegment setHwPresent:NO];
		[aSegment setParams:nil];
	}
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			if(oldFormat){
				NSArray* parts = [aLine componentsSeparatedByString:@","];
				aLine =   [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@",
						 [parts objectAtIndex:0],
						 [parts objectAtIndex:1],
						 [parts objectAtIndex:2],
						 [parts objectAtIndex:6],
						 [parts objectAtIndex:7],
						 [parts objectAtIndex:9],
						 [parts objectAtIndex:10]
						 ];
			}
			
			if(![aLine hasPrefix:@"--"]) index = [aLine intValue];
			else index = -1;
			
			if(index>=0 && index < [segments count]){
				ORDetectorSegment* aSegment = [segments objectAtIndex:index];
				[aSegment decodeLine:aLine];
			}
        }
    }
	[self configurationChanged:nil];   
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSegmentGroupMapReadNotification
                      object:self];
    
}
@end
