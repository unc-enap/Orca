//
//  ORSNOCableDB.m
//  Orca
//
//  Created by Mark Howe on 12/16/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
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

#import "ORSNOCableDB.h"
#import "SynthesizeSingleton.h"


#define TubeInRange(crate,card,channel) ((crate>=0) && (crate<kMaxSNOCrates) && (card>=0) && (card<kNumSNOCards) && (channel>=0) && (channel<kNumSNOPmts))

NSString* ORSNOCableDBReadIn = @"ORSNOCableDBReadIn";


@implementation ORSNOCableDB

SYNTHESIZE_SINGLETON_FOR_ORCLASS(SNOCableDB);

- (NSString*) cableDBFilePath
{
	return cableDBFilePath;
}

- (void) setCableDBFilePath:(NSString*)aPath
{
	if(!aPath)aPath = @"";

    [[[(ORAppDelegate*)[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setCableDBFilePath:cableDBFilePath];
	
	[cableDBFilePath autorelease];
	cableDBFilePath = [aPath copy];
	
	[self readCableDBFile];
	
}

- (void) readCableDBFile
{
	NSError* error;
	NSString* contents = [NSString stringWithContentsOfFile:cableDBFilePath encoding:NSASCIIStringEncoding error:&error];
	if(contents){
		//init to defaults
		int crate,card,channel;
		for(crate=0;crate<kMaxSNOCrates+2;crate++){
			short card;
			for(card=0;card<kNumSNOCards;card++){
				short channel;
				for(channel=0;channel<kNumSNOPmts;channel++){
					SNOCrate[crate].Card[card].Pmt[channel].tubeType = kTubeTypeUnknown;
					SNOCrate[crate].Card[card].Pmt[channel].x			 = 0;
					SNOCrate[crate].Card[card].Pmt[channel].y			 = 0;
					SNOCrate[crate].Card[card].Pmt[channel].z			 = 0;
					SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = @"----";
					SNOCrate[crate].Card[card].Pmt[channel].cableID		 = @"----";
					SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = @"----";
				}
			}
		}
		int32_t lineCount = 0;
		NSArray* lines = [contents componentsSeparatedByString:@"\r"];
		NSString* firstLine = [lines objectAtIndex:lineCount];
		NSScanner* scanner = [NSScanner scannerWithString:firstLine];
		
		int num_panels	= [scanner intAfterString:@"NPAN="]; 
		int num_pmts	= [scanner intAfterString:@"NPMT="]; 
		int num_owl		= [scanner intAfterString:@"NOWL="]; 
		int num_lowgain	= [scanner intAfterString:@"NLG="]; 
		int num_butts	= [scanner intAfterString:@"NBUT="]; 
		int num_neck	= [scanner intAfterString:@"NECK="]; 
		//short total_tubes	= num_panels + num_owl + num_lowgain + num_butts + num_neck;
		lineCount++;
		short panel;
		NSCharacterSet* whiteSpace  = [NSCharacterSet whitespaceCharacterSet];
		NSCharacterSet* letterSet = [whiteSpace invertedSet];
		NSString* cableID   = nil;
		NSString* pmtID     = nil;
		NSString* pcID      = nil;
		NSString* chanInfo  = nil;
		float x,y,z;
		for(panel=0;panel<num_panels;panel++){
			//get the number of pmts in this panel
			NSString* aLine		= [lines objectAtIndex:lineCount++];
			NSScanner* scanner	= [NSScanner scannerWithString:aLine];
			[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
			if([scanner scanInt:&num_pmts]){
				//process all the pmts in this panel
				short pmt;
				for(pmt=0;pmt<num_pmts;pmt++){
					NSString* aLine		= [lines objectAtIndex:lineCount++];
					NSScanner* scanner	= [NSScanner scannerWithString:aLine];
					[scanner scanUpToCharactersFromSet:whiteSpace intoString:&cableID];		//token 1
					[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
					
					[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pmtID];		//token 2
					[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
					
					[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pcID];		//token 3
					[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
					
					[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];			//token 4 skipped
					[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
									
					[scanner scanUpToCharactersFromSet:whiteSpace intoString:&chanInfo];	//token 5
					[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
				
					[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];			//token 6 skipped
					[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
					
					[scanner scanFloat:&x];													//token 7
					[scanner scanFloat:&y];													//token 8
					[scanner scanFloat:&z];													//token 9
					
					if(![chanInfo isEqualToString:@"----"]){
					
						[self decode:chanInfo crate:&crate card:&card channel:&channel];
						if(TubeInRange(crate,card,channel)){
							SNOCrate[crate].Card[card].Pmt[channel].x = x;
							SNOCrate[crate].Card[card].Pmt[channel].y = y;
							SNOCrate[crate].Card[card].Pmt[channel].z = z;
							SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = [pmtID copy];
							SNOCrate[crate].Card[card].Pmt[channel].cableID		 = [cableID copy];
							SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = [pcID copy];
							SNOCrate[crate].Card[card].Pmt[channel].tubeType     = kTubeTypeNormal;	
						}

					}
				}
				
			}
			else {
				[NSException raise:@"Unable to Process Cable DB" format:@"Bad line: %d",lineCount-1];
			}
			
		}
		short owl;
		for(owl=0;owl<num_owl;owl++){
			//process all the owl tubes
			NSString* aLine		= [lines objectAtIndex:lineCount++];
			NSScanner* scanner	= [NSScanner scannerWithString:aLine];
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&cableID];		//token 1
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pmtID];		//token 2
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pcID];		//token 3
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];

			[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];		//token 4 skipped
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];

			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&chanInfo];	//token 5
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
		
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];		//token 6 skipped
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];		//token 7 skipped
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanFloat:&x];													//token 8
			[scanner scanFloat:&y];													//token 9
			[scanner scanFloat:&z];													//token 10
			
			[self decode:chanInfo crate:&crate card:&card channel:&channel];			
		

			SNOCrate[crate].Card[card].Pmt[channel].x = x;
			SNOCrate[crate].Card[card].Pmt[channel].y = y;
			SNOCrate[crate].Card[card].Pmt[channel].z = z;
			SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = [pmtID copy];
			SNOCrate[crate].Card[card].Pmt[channel].cableID		 = [cableID copy];
			SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = [pcID copy];
			SNOCrate[crate].Card[card].Pmt[channel].tubeType     = kTubeTypeOwl;
		}
		short lg;
		for(lg=0;lg<num_lowgain;lg++){
			//process all the owl tubes
			NSString* aLine		= [lines objectAtIndex:lineCount++];
			NSScanner* scanner	= [NSScanner scannerWithString:aLine];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&cableID];		//token 1
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pmtID];		//token 2
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pcID];		//token 3
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];		//token 4 skipped
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&chanInfo];	//token 5
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
						
			[self decode:chanInfo crate:&crate card:&card channel:&channel];			
			
			SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = [pmtID copy];
			SNOCrate[crate].Card[card].Pmt[channel].cableID		 = [cableID copy];
			SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = [pcID copy];
			SNOCrate[crate].Card[card].Pmt[channel].tubeType     = kTubeTypeLowGain;	
		}
		short bt;
		for(bt=0;bt<num_butts+num_neck;bt++){
			//process all the owl tubes
			NSString* aLine		= [lines objectAtIndex:lineCount++];
			NSScanner* scanner	= [NSScanner scannerWithString:aLine];

			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&cableID];		//token 1
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&pmtID];		//token 2
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:&chanInfo];	//token 3
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
	
			[scanner scanUpToCharactersFromSet:whiteSpace intoString:nil];			//token 4 skipped
			[scanner scanUpToCharactersFromSet:letterSet intoString:nil];
			
			
			[scanner scanFloat:&x];													//token 5
			[scanner scanFloat:&y];													//token 6
			[scanner scanFloat:&z];													//token 7
			
			[self decode:chanInfo crate:&crate card:&card channel:&channel];			
			
			SNOCrate[crate].Card[card].Pmt[channel].x = x;
			SNOCrate[crate].Card[card].Pmt[channel].y = y;
			SNOCrate[crate].Card[card].Pmt[channel].z = z;
			SNOCrate[crate].Card[card].Pmt[channel].pmtID		 = [pmtID copy];
			SNOCrate[crate].Card[card].Pmt[channel].cableID		 = [cableID copy];
			SNOCrate[crate].Card[card].Pmt[channel].paddleCardID = [pcID copy];
			
			if(bt<num_butts) SNOCrate[crate].Card[card].Pmt[channel].tubeType     = kTubeTypeButt;
			else			 SNOCrate[crate].Card[card].Pmt[channel].tubeType     = kTubeTypeNeck;
		}
	}
	else {
		NSLog(@"Couldn't open Cable DB: %@\n",error);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCableDBReadIn object:self];

}

-(void) decode:(NSString*)s crate:(int*)crate card:(int*)card channel:(int*) channel
{
	const char* chan_info = [s cStringUsingEncoding:NSASCIIStringEncoding];
	int aCrate, aCard, aChannel;
	//decode the chanInfo into crate,card,channel numbers
	aCrate 	= chan_info[0] - 'A'; 
	aCard  	= chan_info[1] - 'A';
	aCard    = 15-aCard; 		//channel A-P --> card 15-0
	//special case for the owl tubes...wrap the cards one slot to the right
	if(aCrate == 3 || aCrate == 13 || aCrate == 17 || aCrate == 18){
		aCard--;
		if(aCard<0)aCard=15;
	}
	
	aChannel = atoi(&chan_info[2]);	
	aChannel	= 32-aChannel;  	//channel 1-32 --> channel 31-0
	*crate = aCrate;
	*card = aCard;
	*channel = aChannel;
}

- (BOOL) getCrate:(int)aCrate card:(int)aCard channel:(int)aChannel x:(float*)x y:(float*)y
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		*x = SNOCrate[aCrate].Card[aCard].Pmt[aChannel].x;
		*y = SNOCrate[aCrate].Card[aCard].Pmt[aChannel].y;
		return YES;
	}
	else return NO;
	
}

- (int)  tubeTypeCrate:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].tubeType;
	}
	else return kTubeTypeUnknown;
}

- (NSString*)  pmtID:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		return SNOCrate[aCrate].Card[aCard].Pmt[aChannel].pmtID;
	}
	else return @"----";
}

- (NSColor*)  pmtColor:(int)aCrate card:(int)aCard channel:(int)aChannel
{
	if(TubeInRange(aCrate,aCard,aChannel)){
		int type = SNOCrate[aCrate].Card[aCard].Pmt[aChannel].tubeType;
		switch(type){
			case kTubeTypeUnknown:	return [NSColor blackColor];	break;
			case kTubeTypeNormal:	return [NSColor greenColor];	break;
			case kTubeTypeOwl:		return [NSColor blueColor];		break;
			case kTubeTypeLowGain:	return [NSColor yellowColor];	break;
			case kTubeTypeButt:		return [NSColor brownColor];	break;
			case kTubeTypeNeck:		return [NSColor cyanColor];		break;
			default:				return [NSColor blackColor];	break;
		}
	}
	else return [NSColor blackColor];
}

@end
