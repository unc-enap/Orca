//
//  SNODetectorView.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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

#import "SNODetectorView.h"
#import "ORPSUPTubePosition.h"
#import "ORColorScale.h"
#import "ORAxis.h"

NSString* selectionStringChanged			 = @"selectionStringChanged";
NSString* newValueAvailable                  = @"newValueAvailable";
NSString* plotButtonDisabled                 = @"plotButtonDisabled";

@implementation SNODetectorView

- (id)initWithFrame:(NSRect)frameRect
{	
	self = [super initWithFrame:frameRect];
    
    if (self){
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Papyrus" size:20], 
								NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
    
        detectorTitle=[[NSAttributedString alloc] initWithString:@"Tube type" attributes: attributes];
    
        db = [SNOMonitoredHardware sharedSNOMonitoredHardware];
        crateRectsInCrateView = [[NSMutableArray alloc] init];
        cardRectsInCrateView = [[NSMutableArray alloc] init];
        channelRectsInCrateView = [[NSMutableArray alloc] init];
        channelRectsInPSUPView = [[NSMutableArray alloc] init];
        voltageRectsInCrateView = [[NSMutableArray alloc] init];
        xl3VoltageRectsInCrateView = [[NSMutableArray alloc] init];
        selectionMode = kTubeSelectionMode;
        [self iniAxisChanges];
        [self getRectPositions];
        pickPSUPView=YES;
        pollingInProgress=NO;
        parameterToDisplay = 1;
        colorBarAxisAttributes = [[NSMutableDictionary dictionary] retain];
        [colorBarAxisAttributes setObject:[NSNumber numberWithDouble:0] forKey:ORAxisMinValue];
        [colorBarAxisAttributes setObject:[NSNumber numberWithDouble:10000] forKey:ORAxisMaxValue];
        [colorBarAxisAttributes setObject:[NSNumber numberWithBool:NO] forKey:ORAxisUseLog];
        [self updateSNODetectorView];
    }

	return self;
}

- (void)dealloc
{
    [detectorTitle release];
    [axisChanges release];
    [colorBarAxisAttributes release];
	[crateRectsInCrateView release];
	[cardRectsInCrateView release];
	[channelRectsInCrateView release];
	[channelRectsInPSUPView release];
    [voltageRectsInCrateView release];
    [xl3VoltageRectsInCrateView release];
	[super dealloc];
}

- (NSMutableDictionary*) colorBarAxisAttributes
{
    return colorBarAxisAttributes;
}

- (void) setColorBarAxisAttributes:(NSMutableDictionary*)newColorBarAttributes
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setColorBarAxisAttributes:colorBarAxisAttributes];
    
    [newColorBarAttributes retain];
    [colorBarAxisAttributes release];
    colorBarAxisAttributes=newColorBarAttributes;
}

- (void) setColorAxisChanged:(BOOL)aBOOL
{
    [axisChanges replaceObjectAtIndex:parameterToDisplay withObject:[NSNumber numberWithBool:aBOOL]];
}

- (void) setViewType:(BOOL)aViewType
{
	pickPSUPView = aViewType;
}

- (void) setParameterToDisplay:(int)aParameter
{
	parameterToDisplay = aParameter;
}

- (void) setDetectorTitleString:(NSString *)aString
{
    [aString retain];
    [detectorTitle release];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Papyrus" size:20], 
								NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
    
    detectorTitle=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
    
}

- (void) setSelectionMode:(int)aMode
{
	selectionMode = aMode;
}

- (void) setPollingInProgress:(BOOL)aBOOL
{
    pollingInProgress = aBOOL;
}

- (NSMutableString *) selectionString
{
	return selectionString;
}



- (void) formatGlobalStatsString
{
    if (globalStatsString) [globalStatsString release];

	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:10], 
								NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	if (parameterToDisplay == kTubeTypeDisplay){
        globalStatsString=[[NSMutableAttributedString alloc] initWithString:@"Overall detector statistics:  " attributes: attributes];
        
		NSString *aString =[NSString stringWithFormat:@"Normal tubes:%i, ",numTubesOnline];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
									NSFontAttributeName,[NSColor greenColor], NSForegroundColorAttributeName, nil];
		NSAttributedString *currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Unknown tubes:%i, ",numUnknownTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"OWL tubes:%i, ",numOwlTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor blueColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Low gain tubes:%i, ",numLowGainTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor yellowColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Butt tubes:%i, ",numButtTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor brownColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
		aString = [NSString stringWithFormat:@"Neck tubes:%i",numNeckTubes];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10], 
					  NSFontAttributeName,[NSColor cyanColor], NSForegroundColorAttributeName, nil];
		currentText=[[NSAttributedString alloc] initWithString:aString attributes: attributes];
		[globalStatsString appendAttributedString:currentText];
		[currentText release];
	} else if (parameterToDisplay == kFECVoltagesDisplay) {
        globalStatsString=[[NSMutableAttributedString alloc] initWithString:@"Color scale shows absolute values of voltages " attributes: attributes];
    } else if (parameterToDisplay == kRatesDisplay) {
        globalStatsString=[[NSMutableAttributedString alloc] initWithString:@"Color scale shows XL3 data rates in mHz " attributes: attributes];
    } else {
        globalStatsString=[[NSMutableAttributedString alloc] initWithString:@"" attributes: attributes];
    }
}

- (void) iniAxisChanges
{
    axisChanges = [[NSMutableArray alloc] initWithCapacity:30];
    int i;
    for(i=0;i<30;++i){
        [axisChanges insertObject:[NSNumber numberWithBool:NO] atIndex:i];
    }
}

- (void) getRectPositions
{
	float scaleFactor = 1.005*([self bounds].size.width-20)/kPSUP_width;
	float tubeSize = 4.*[self bounds].size.width/kPSUP_width;

	int crate, card, pmt;
	float x,y;
	for(crate=0;crate<kMaxSNOCrates-1;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				x = psupTubePosition[tubeIndex].x * scaleFactor;
				y = (psupTubePosition[tubeIndex].y-22) * scaleFactor;
				NSRect tubeRect = NSMakeRect(x-tubeSize/2.,y-tubeSize/2.,tubeSize,tubeSize);
				[channelRectsInPSUPView insertObject:[NSBezierPath bezierPathWithOvalInRect:tubeRect] atIndex:tubeIndex];
			}
		}
	}
		
	float xc = [self bounds].size.width/2.;
	float yc = [self bounds].size.height/2.;
	float segSize = [self bounds].size.height/100.;
		
	//Establish crate areas in the view window
	NSRect crateRect = NSMakeRect(xc,yc,segSize*16,segSize*32);
		
	float xOffset, yOffset;
	for(crate=0;crate<kMaxSNOCrates-1;++crate){
		if (crate<10) {
			xOffset=-5.5*segSize*16+crate*segSize*17.5;
			yOffset=-1.2*segSize*32;
			NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
			[crateRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:crate];
		}else if (crate >=10){
			xOffset=-5.5*segSize*16+(crate-10)*segSize*17.5;
			yOffset=0.2*segSize*32;			
			NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
			[crateRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:crate];
		}
	}
		
	//card areas
	NSRect cardRect = NSMakeRect(xc,yc,segSize,segSize*32);
	for (crate=0;crate<kMaxSNOCrates-1;crate++){
		for(card=0;card<kNumSNOCards;card++){
			int cardIndex = kCardsPerCrate * crate + card;
			if (crate<10){
				xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
				yOffset=-1.2*segSize*32;	
					
				NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
				[cardRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:cardIndex];
			}else if (crate>=10){
				xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
				yOffset=0.2*segSize*32;
					
				NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
				[cardRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:cardIndex];
			}
		}
	}
		
		
	//channel areas
	NSRect tubeRect = NSMakeRect(xc,yc,segSize,segSize);
	for (crate=0;crate<kMaxSNOCrates-1;crate++){
		for(card=0;card<kNumSNOCards;card++){
			for(pmt=0;pmt<kNumSNOPmts;pmt++){
				int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				if (crate<10){
					xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
					yOffset=-1*pmt*segSize-0.2*segSize*32-segSize;	
						
					NSRect theRect = NSOffsetRect(tubeRect,xOffset,yOffset);
					[channelRectsInCrateView insertObject:[NSBezierPath bezierPathWithOvalInRect:theRect] atIndex:tubeIndex];
				}else if (crate>=10){
					xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
					yOffset=-1*pmt*segSize+1.2*segSize*32-segSize;	
						
					NSRect theRect = NSOffsetRect(tubeRect,xOffset,yOffset);
					[channelRectsInCrateView insertObject:[NSBezierPath bezierPathWithOvalInRect:theRect] atIndex:tubeIndex];
				}
			}
		}
	}	
    
    //areas in fec voltages view
    int iVoltage;
    NSRect voltageRect = NSMakeRect(xc,yc,segSize,segSize*32.0/kNumFecMonitorAdcs);
    for (crate=0; crate<kMaxSNOCrates-1; crate++) {
        for (card=0; card<kNumSNOCards; card++) {
            for (iVoltage=0; iVoltage<kNumFecMonitorAdcs; iVoltage++) {
                int voltageIndex = (kNumFecMonitorAdcs*kNumSNOCards) * crate + kNumFecMonitorAdcs * card + iVoltage;

                if (crate<10){
					xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
					yOffset=-1*iVoltage*segSize*32/kNumFecMonitorAdcs-0.2*(segSize*32/kNumFecMonitorAdcs)*kNumFecMonitorAdcs-segSize*32/kNumFecMonitorAdcs;	
                    
					NSRect theRect = NSOffsetRect(voltageRect,xOffset,yOffset);
					[voltageRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:voltageIndex];
				}else if (crate>=10){
					xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
					yOffset=-1*iVoltage*segSize*32/kNumFecMonitorAdcs+1.2*(segSize*32/kNumFecMonitorAdcs)*kNumFecMonitorAdcs-segSize*32/kNumFecMonitorAdcs;	
                    
					NSRect theRect = NSOffsetRect(voltageRect,xOffset,yOffset);
					[voltageRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:voltageIndex];
				}
            }
        }
    }
    
    //areas in xl3 voltages view
    NSRect xl3VoltageRect = NSMakeRect(xc, yc, segSize*kNumSNOCards, segSize*32.0/kNumXL3Voltages);
    for (crate=0; crate<kMaxSNOCrates-1; crate++) {
        for (iVoltage=0; iVoltage<kNumXL3Voltages; iVoltage++) {
            int voltageIndex = kNumXL3Voltages*crate + iVoltage;
            
            if (crate<10){
                xOffset=-5.5*segSize*16+crate*segSize*17.5;
                yOffset=-1*iVoltage*segSize*32/kNumXL3Voltages-0.2*(segSize*32/kNumXL3Voltages)*kNumXL3Voltages-segSize*32/kNumXL3Voltages;	
                
                NSRect theRect = NSOffsetRect(xl3VoltageRect,xOffset,yOffset);
                [xl3VoltageRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:voltageIndex];
            }else if (crate>=10){
                xOffset=-5.5*segSize*16+(crate-10)*segSize*17.5;
                yOffset=-1*iVoltage*segSize*32/kNumXL3Voltages+1.2*(segSize*32/kNumXL3Voltages)*kNumXL3Voltages-segSize*32/kNumXL3Voltages;	
                
                NSRect theRect = NSOffsetRect(xl3VoltageRect,xOffset,yOffset);
                [xl3VoltageRectsInCrateView insertObject:[NSBezierPath bezierPathWithRect:theRect] atIndex:voltageIndex];
            } 
        }
    }
}

- (void) drawRect:(NSRect)aRect
{	
	int crate, card, pmt, tubeIndex;
	NSBezierPath *aPath;
	
	[detectorTitle drawAtPoint:NSMakePoint([self bounds].size.width*0.42,5)];
	
    //black background
    float x1 = [self bounds].size.width/60.;
    float y1 = [self bounds].size.height/13.;

    NSRect backRect = NSMakeRect(x1,y1,[self bounds].size.width*0.99,[self bounds].size.height*0.89);
    [[NSColor blackColor] set];
    [NSBezierPath fillRect:backRect];
    
	if (pickPSUPView){
		
		//draw psup in grey
		float scaleFactor = 1.005*([self bounds].size.width-20)/kPSUP_width;
		
		int i;
		float xoffset = 25;
		float yoffset = 17;
		for(i=0;i<kCMPSUPSTRUT;i++){
			float x1 = (PSUPstrut[i].x1+xoffset) * scaleFactor;
			float y1 = (PSUPstrut[i].y1+yoffset) * scaleFactor;
			float x2 = (PSUPstrut[i].x2+xoffset) * scaleFactor;
			float y2 = (PSUPstrut[i].y2+yoffset) * scaleFactor;
			[[NSColor grayColor] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		}

		//draw pmts as filled circles with given colour
		for (crate=0;crate<kMaxSNOCrates-1;crate++){
			for(card=0;card<kNumSNOCards;card++){
				for(pmt=0;pmt<kNumSNOPmts;pmt++){
					tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
					[[self getPMTColor:crate card:card pmt:pmt] set];
					[[channelRectsInPSUPView objectAtIndex:tubeIndex] fill];
					aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
					[aPath setLineWidth:highlightLineWidth-2.5];
					[[NSColor grayColor] set];
					[aPath stroke];								
				}
			}
		}
		
		//highlight selected pmt at mousedown
		if(selectedCrate>=0 && selectedCard>=0 && selectedChannel >=0){	
			if (selectionMode == kTubeSelectionMode){
				tubeIndex = kChannelsPerCrate * selectedCrate + kChannelsPerBoard* selectedCard + selectedChannel;
				aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
				[aPath setLineWidth:highlightLineWidth-1];
				//[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
				[[NSColor whiteColor] set];
				[aPath stroke];
			
				selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i Channel %i\n",selectedCrate,selectedCard,selectedChannel];
				[selectionString appendString:[NSString stringWithFormat:@"PMT ID: %@\n",[db pmtID:selectedCrate card:selectedCard channel:selectedChannel]]];
				float x,y,z;
				x=[db xpos:selectedCrate card:selectedCard channel:selectedChannel];
				y=[db ypos:selectedCrate card:selectedCard channel:selectedChannel];
				z=[db zpos:selectedCrate card:selectedCard channel:selectedChannel];
				if ([db tubeTypeCrate:selectedCrate card:selectedCard channel:selectedChannel]==kTubeTypeNormal){
					[selectionString appendString:[NSString stringWithFormat:@"x=%3.2f, y=%3.2f, z=%3.2f\n",x,y,z]];
				} else {
					[selectionString appendString:[NSString stringWithFormat:@"x=N/A, y=N/A, z=N/A\n"]];
				}
			} else if (selectionMode == kCardSelectionMode) {
				for (pmt=0;pmt<kNumSNOPmts;pmt++){
					tubeIndex = kChannelsPerCrate * selectedCrate + kChannelsPerBoard* selectedCard + pmt;
					aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
					[aPath setLineWidth:highlightLineWidth-2];
					[[NSColor whiteColor] set];
					[aPath stroke];					
				}
				selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i\n",selectedCrate,selectedCard];
			} else if (selectionMode == kCrateSelectionMode){
				for(card=0;card<kNumSNOCards;card++){
					for (pmt=0;pmt<kNumSNOPmts;pmt++){
						tubeIndex = kChannelsPerCrate * selectedCrate+ kChannelsPerBoard* card + pmt;
						aPath  = [channelRectsInPSUPView objectAtIndex:tubeIndex];
						[aPath setLineWidth:highlightLineWidth-2];
						[[NSColor whiteColor] set];
						[aPath stroke];			
					}
				}
				selectionString = [NSMutableString stringWithFormat:@"Crate %i\n",selectedCrate];				
			}
            
            [selectionString appendString:[self getCurrentDisplayValue]];
            [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
		}else{
			selectionString = [NSMutableString stringWithFormat:@"No hardware selected\n"];
			[[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
		}

        [self formatGlobalStatsString];
		[globalStatsString drawAtPoint:NSMakePoint(30,[self bounds].size.height*0.97)];
		
	}else if (!pickPSUPView){
		
		float xc = [self bounds].size.width/2.;
		float yc = [self bounds].size.height/2.;
		float segSize = [self bounds].size.height/100.;
		
		//Establish crate areas
		NSRect crateRect = NSMakeRect(xc,yc,segSize*16,segSize*32);
		
		float xOffset = 0.0, yOffset = 0.0;
		for(crate=0;crate<kMaxSNOCrates-1;++crate){
			if (crate<10) {
				xOffset=-5.5*segSize*16+crate*segSize*17.5;
				yOffset=-1.2*segSize*32;
				NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
				[NSBezierPath strokeRect:theRect];
				[[NSColor blackColor] set];
				[NSBezierPath fillRect:theRect];
				
			}else if (crate >=10){
				xOffset=-5.5*segSize*16+(crate-10)*segSize*17.5;
				yOffset=0.2*segSize*32;			
				NSRect theRect = NSOffsetRect(crateRect, xOffset, yOffset);
				[NSBezierPath strokeRect:theRect];
				[[NSColor blackColor] set];
				[NSBezierPath fillRect:theRect];
				
			}
			
			NSString *crateName=[NSString stringWithFormat:@"Crate %i",crate];
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:12], 
										NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
			NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:crateName attributes: attributes];
			[currentText drawAtPoint:NSMakePoint(xc+xOffset+20,yc+yOffset+180)];
			[currentText release];
			
            if (parameterToDisplay != kXL3VoltagesDisplay && parameterToDisplay != kRatesDisplay){
                [[NSColor grayColor] set];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset,yc+yOffset+segSize*8) 
									  toPoint:NSMakePoint(xc+xOffset+segSize*16,yc+yOffset+segSize*8)];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset,yc+yOffset+segSize*16) 
									  toPoint:NSMakePoint(xc+xOffset+segSize*16,yc+yOffset+segSize*16)];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset,yc+yOffset+segSize*24) 
									  toPoint:NSMakePoint(xc+xOffset+segSize*16,yc+yOffset+segSize*24)];
            }
		}
		
		//draw Cards
        if (parameterToDisplay != kXL3VoltagesDisplay && parameterToDisplay != kRatesDisplay){
            NSRect cardRect = NSMakeRect(xc,yc,segSize,segSize*32);
            for (crate=0;crate<kMaxSNOCrates-1;crate++){
                for(card=0;card<16;card++){
                    if (crate<10){
                        xOffset=card*segSize-5.5*segSize*16+crate*segSize*17.5;
                        yOffset=-1.2*segSize*32;	
					
                        NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
                        [[NSColor grayColor] set];
                        [NSBezierPath strokeRect:theRect];
                    }else if (crate>=10){
                        xOffset=card*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
                        yOffset=0.2*segSize*32;
                        
                        NSRect theRect = NSOffsetRect(cardRect,xOffset,yOffset);
                        [[NSColor grayColor] set];
                        [NSBezierPath strokeRect:theRect];	
                    }
				
                    if (card%4==0){
                        NSString *cardNum=[NSString stringWithFormat:@"%i",card];
                        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:9], 
												NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
                        NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:cardNum attributes: attributes];
                        [currentText drawAtPoint:NSMakePoint(xc+xOffset,yc+yOffset+172)];
                        [currentText release];
					
                        [[NSColor whiteColor] set];
                        [NSBezierPath strokeLineFromPoint:NSMakePoint(xc+xOffset+segSize*0.5,yc+yOffset+174) 
                                                toPoint:NSMakePoint(xc+xOffset+segSize*0.5,yc+yOffset+168)];
                    }
                }
            }
        }
		
		if (parameterToDisplay != kFECVoltagesDisplay && parameterToDisplay != kXL3VoltagesDisplay 
            && parameterToDisplay!=kRatesDisplay && parameterToDisplay != kFifoDisplay){
            //draw Channels as filled circles with pre-determined colour
            for (crate=0;crate<kMaxSNOCrates-1;crate++){
                for(card=0;card<kNumSNOCards;card++){
                    for(pmt=0;pmt<kNumSNOPmts;pmt++){
                        tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
                        [[self getPMTColor:crate card:card pmt:pmt] set];
                        [[channelRectsInCrateView objectAtIndex:tubeIndex] fill];
                    }
                }
            }
		
            //highlight selected pmt at mousedown
            if(selectedCrate>=0 && selectedCard>=0 && selectedChannel >=0){	
                if (selectionMode == kTubeSelectionMode) {
                    tubeIndex = kChannelsPerCrate * selectedCrate + kChannelsPerBoard* selectedCard + selectedChannel;
                    aPath  = [channelRectsInCrateView objectAtIndex:tubeIndex];
                    [aPath setLineWidth:highlightLineWidth-1];
                    [[NSColor whiteColor] set];
                    [aPath stroke];
				
                    selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i Channel %i\n",selectedCrate,selectedCard,selectedChannel];
                }else if (selectionMode == kCardSelectionMode) {
                    int cardIndex = kCardsPerCrate * selectedCrate + selectedCard;
                    aPath  = [cardRectsInCrateView objectAtIndex:cardIndex];
                    [aPath setLineWidth:highlightLineWidth-1];
                    [[NSColor whiteColor] set];
                    [aPath stroke];
				
                    selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i\n",selectedCrate,selectedCard];
                }else if (selectionMode == kCrateSelectionMode) {
                    aPath  = [crateRectsInCrateView objectAtIndex:selectedCrate];
                    [aPath setLineWidth:highlightLineWidth-1];
                    //[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
                    [[NSColor whiteColor] set];
                    [aPath stroke];
				
                    selectionString = [NSMutableString stringWithFormat:@"Crate %i\n",selectedCrate];
                }
            
                [selectionString appendString:[self getCurrentDisplayValue]];
                [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
            }else{
                selectionString = [NSMutableString stringWithFormat:@"No hardware selected\n"];
                [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
            }
		
            [self formatGlobalStatsString];
            [globalStatsString drawAtPoint:NSMakePoint(10,[self bounds].size.height*0.97)];
     
        }else if (parameterToDisplay == kFECVoltagesDisplay){
            int iVoltage, voltageIndex;
            for (crate=0;crate<kMaxSNOCrates-1;crate++){
                for(card=0;card<kNumSNOCards;card++){
                    for(iVoltage=0;iVoltage<kNumFecMonitorAdcs;iVoltage++){
                        voltageIndex = (kNumFecMonitorAdcs*kNumSNOCards) * crate + kNumFecMonitorAdcs* card + iVoltage;

                        [[self getFECVoltageColor:crate card:card voltage:iVoltage] set];
                        [[voltageRectsInCrateView objectAtIndex:voltageIndex] fill];
                        
                        aPath = [voltageRectsInCrateView objectAtIndex:voltageIndex];
                        [aPath setLineWidth:highlightLineWidth-2.5];
                        [[NSColor grayColor] set];
                        [aPath stroke];		
                    }
                }
            }
            
            crate = 18;
            
            for (iVoltage=0;iVoltage<kNumFecMonitorAdcs+1;iVoltage++){
              float xOffset=17*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
              float yOffset=-1*iVoltage*segSize*32/kNumFecMonitorAdcs+1.2*(segSize*32/kNumFecMonitorAdcs)*kNumFecMonitorAdcs-segSize*32/kNumFecMonitorAdcs;	
            
                NSString *voltageName;
                if (iVoltage < kNumFecMonitorAdcs) {
                    voltageName=[NSString stringWithString:[NSString stringWithCString:fecVoltageAdc[iVoltage].label encoding:NSASCIIStringEncoding]];
                }else{
                    voltageName=[NSString stringWithFormat:@"INDEX"];
                }
                
                NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:7], 
                                        NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
                NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:voltageName attributes: attributes];
                    [currentText drawAtPoint:NSMakePoint(xc+xOffset,yc+yOffset)];
                    [currentText release];
            }
            
            if (selectedCrate>=0 && selectedCard>=0 && selectedVoltage>=0){
                voltageIndex = (kNumFecMonitorAdcs*kNumSNOCards) * selectedCrate+ kNumFecMonitorAdcs*selectedCard + selectedVoltage;
                aPath  = [voltageRectsInCrateView objectAtIndex:voltageIndex];
                [aPath setLineWidth:highlightLineWidth-1];
                [[NSColor whiteColor] set];
                [aPath stroke];
				
                selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i\nVoltage %@\n",selectedCrate,selectedCard,[NSString stringWithString:[NSString stringWithCString:fecVoltageAdc[selectedVoltage].label encoding:NSASCIIStringEncoding]]];
                
                [selectionString appendString:[self getCurrentDisplayValue]];
                [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
            }
            
            [self formatGlobalStatsString];
            [globalStatsString drawAtPoint:NSMakePoint(10,[self bounds].size.height*0.97)];
            
        }else if (parameterToDisplay == kXL3VoltagesDisplay){
            int iVoltage, voltageIndex;
            for (crate=0;crate<kMaxSNOCrates-1;crate++){
                for(iVoltage=0;iVoltage<kNumXL3Voltages;iVoltage++){
                    voltageIndex = kNumXL3Voltages*crate + iVoltage;
                    
                    [[self getXL3VoltageColor:crate voltage:iVoltage] set];
                    [[xl3VoltageRectsInCrateView objectAtIndex:voltageIndex] fill];
                        
                    aPath = [xl3VoltageRectsInCrateView objectAtIndex:voltageIndex];
                    [aPath setLineWidth:highlightLineWidth-2.5];
                    [[NSColor grayColor] set];
                    [aPath stroke];		
                }
                
            }
            
            crate = 18;
            for (iVoltage=0;iVoltage<kNumXL3Voltages+1;iVoltage++){
                float xOffset=17*segSize-5.5*segSize*16+(crate-10)*segSize*17.5;
                float yOffset=-1*iVoltage*segSize*32/kNumXL3Voltages+1.2*(segSize*32/kNumXL3Voltages)*kNumXL3Voltages-segSize*32/kNumXL3Voltages;
                
                NSString *voltageName = nil;
                if (iVoltage == 0) {
                    voltageName=@"VCC";
                }else if (iVoltage == 1){
                    voltageName=@"VEE";
                }else if (iVoltage == 2){
                    voltageName=@"VP24";
                }else if (iVoltage == 3){
                    voltageName=@"VM24";
                }else if (iVoltage == 4){
                    voltageName=@"TMP0";
                }else if (iVoltage == 5){
                    voltageName=@"TMP1";
                }else if (iVoltage == 6){
                    voltageName=@"TMP2";
                }else if (iVoltage == kNumXL3Voltages) {
                    voltageName=@"INDEX";
                }
                
                NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Lucida Grande" size:10], 
                                            NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
                NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:voltageName attributes: attributes];
                [currentText drawAtPoint:NSMakePoint(xc+xOffset,yc+yOffset)];
                [currentText release];
            }
            
            if (selectedCrate>=0 && selectedXL3Voltage>=0){
                voltageIndex = (kNumXL3Voltages) * selectedCrate+ selectedXL3Voltage;
                aPath  = [xl3VoltageRectsInCrateView objectAtIndex:voltageIndex];
                [aPath setLineWidth:highlightLineWidth-1];
                [[NSColor whiteColor] set];
                [aPath stroke];
				
                selectionString = [NSMutableString stringWithFormat:@"Crate %i \nVoltage VoltageName\n",selectedCrate];
                
                [selectionString appendString:[self getCurrentDisplayValue]];
                [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
            }
            
            [self formatGlobalStatsString];
            [globalStatsString drawAtPoint:NSMakePoint(10,[self bounds].size.height*0.97)];
            
        }else if (parameterToDisplay == kRatesDisplay){
            for (crate=0; crate<kMaxSNOCrates-1; crate++) {
                [[self getCrateColor:crate] set];
                [[crateRectsInCrateView objectAtIndex:crate] fill];
                
                aPath  = [crateRectsInCrateView objectAtIndex:crate];
                [aPath stroke];	
            }
            
            if (selectedCrate>=0){
                aPath  = [crateRectsInCrateView objectAtIndex:selectedCrate];
                [aPath setLineWidth:highlightLineWidth-1];
                //[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
                [[NSColor whiteColor] set];
                [aPath stroke];
				
                selectionString = [NSMutableString stringWithFormat:@"Crate %i\n",selectedCrate];
                [selectionString appendString:[self getCurrentDisplayValue]];
                [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
            }
            
            [self formatGlobalStatsString];
            [globalStatsString drawAtPoint:NSMakePoint(10,[self bounds].size.height*0.97)];

        }else if (parameterToDisplay == kFifoDisplay){
            for (crate = 0; crate<kMaxSNOCrates-1; crate++){
                for (card = 0; card<kNumSNOCards; card++){
                    int iCard = kCardsPerCrate * crate + card;
                    [[self getCardColor:crate card:card] set];
                    [[cardRectsInCrateView objectAtIndex:iCard] fill];
                    aPath = [cardRectsInCrateView objectAtIndex:iCard];
                    [aPath stroke];
                }
            }
            
            if (selectedCrate>=0 && selectedCard>=0){
                int iCard = kCardsPerCrate *selectedCrate + selectedCard;
                aPath = [cardRectsInCrateView objectAtIndex:iCard];
                [aPath setLineWidth:highlightLineWidth-1];
                //[[NSColor colorWithCalibratedRed:.7 green:.2 blue:.2 alpha:1] set];
                [[NSColor whiteColor] set];
                [aPath stroke];
				
                selectionString = [NSMutableString stringWithFormat:@"Crate %i Card %i\n",selectedCrate,selectedCard];
                [selectionString appendString:[self getCurrentDisplayValue]];
                [[NSNotificationCenter defaultCenter] postNotificationName:selectionStringChanged object:self userInfo:nil];
            }
        }
	}
}

- (NSString *) getCurrentDisplayValue
{
    float aValue=0;
    
    NSString *str = @"";
    if (parameterToDisplay == kOnlineTubeDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kTubeTypeDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kPedestalsDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kThresholdsDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kVBalsLoDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kVBalsHiDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kCmosRatesDisplay){
        if (selectionMode == kTubeSelectionMode){
            aValue=[db cmosRate:selectedCrate card:selectedCard channel:selectedChannel];
            [db setCurrentValueForSelectedHardware:aValue];
            str =[NSString stringWithFormat:@"CMOS rate: %f\n",aValue];
            
            if (pollingInProgress) {
                [[NSNotificationCenter defaultCenter] postNotificationName:newValueAvailable object:self userInfo:nil];
            }else if (!pollingInProgress){
                [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
            }
        } else if (selectionMode != kTubeSelectionMode) {
            [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
        }
        
    }else if (parameterToDisplay == kHvOnDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kRelaysDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kThreshMaxDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kSequencerDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == k20nsTriggerDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == k100nsTriggerDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kCmosReadDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kQllDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kTempDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kFifoDisplay){
        if (selectionMode == kCardSelectionMode) {
            aValue=[db fifo:selectedCrate card:selectedCard];
            [db setCurrentValueForSelectedHardware:aValue];
            str =[NSString stringWithFormat:@"FIFO: %f\n",aValue];
            if (pollingInProgress) {
                [[NSNotificationCenter defaultCenter] postNotificationName:newValueAvailable object:self userInfo:nil];
            } else if (!pollingInProgress){
                [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
            }
        } else if (selectionMode != kCardSelectionMode){
            [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
        }
    }else if (parameterToDisplay == kBaseCurrentDisplay){
        if (selectionMode == kTubeSelectionMode){
            aValue=[db baseCurrent:selectedCrate card:selectedCard channel:selectedChannel];
            [db setCurrentValueForSelectedHardware:aValue];
             str =[NSString stringWithFormat:@"Base current: %f\n",aValue];
            
            if (pollingInProgress) {
                [[NSNotificationCenter defaultCenter] postNotificationName:newValueAvailable object:self userInfo:nil];
            }else if (!pollingInProgress){
                [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
            }
        } else if (selectionMode != kTubeSelectionMode) {
            [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
        }
    }else if (parameterToDisplay == kCheckerMismatchesDisplay && selectionMode == kTubeSelectionMode){
    }else if (parameterToDisplay == kRatesDisplay){
        if (selectionMode == kCrateSelectionMode){
            aValue=[db xl3Rate:selectedCrate];
            [db setCurrentValueForSelectedHardware:aValue];
            str =[NSString stringWithFormat:@"XL3 rate: %f\n",aValue];
            
            if (pollingInProgress) {
                [[NSNotificationCenter defaultCenter] postNotificationName:newValueAvailable object:self userInfo:nil];
            }else if (!pollingInProgress){
                [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
            }
        } else if (selectionMode != kCrateSelectionMode) {
            [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
        }
    }else if (parameterToDisplay == kFECVoltagesDisplay){
        aValue = [db fecVoltageValue:selectedCrate card:selectedCard voltage:selectedVoltage];
        [db setCurrentValueForSelectedHardware:aValue];
        str = [NSString stringWithFormat:@"Value: %f\n",aValue];
        
        if (pollingInProgress) {
            [[NSNotificationCenter defaultCenter] postNotificationName:newValueAvailable object:self userInfo:nil];
        }else if (!pollingInProgress){
            [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
        }
    }else if (parameterToDisplay == kXL3VoltagesDisplay){
        aValue = [db xl3VoltageValue:selectedCrate voltage:selectedXL3Voltage];
        [db setCurrentValueForSelectedHardware:aValue];
        str = [NSString stringWithFormat:@"Value: %f\n",aValue];
        
        if (pollingInProgress) {
            [[NSNotificationCenter defaultCenter] postNotificationName:newValueAvailable object:self userInfo:nil];
        }else if (!pollingInProgress){
            [[NSNotificationCenter defaultCenter] postNotificationName:plotButtonDisabled object:self userInfo:nil];
        }
    }
    return str;
}

- (NSColor *) getPMTColor:(int)aCrate card:(int)aCard pmt:(int)aPMT
{
    NSColor *tubeColor = nil;
    if (parameterToDisplay == kTubeTypeDisplay){
        tubeColor = [db pmtColor:aCrate card:aCard channel:aPMT];
        if ([NSColor greenColor]==tubeColor){
            numTubesOnline++;
        }else if ([NSColor blackColor]==tubeColor) {
            numUnknownTubes++;
        }else if ([NSColor blueColor]==tubeColor) {
            numOwlTubes++;
        }else if ([NSColor yellowColor]==tubeColor) {
            numLowGainTubes++;
        }else if ([NSColor brownColor]==tubeColor) {
            numButtTubes++;
        }else if ([NSColor cyanColor]==tubeColor) {
            numNeckTubes++;
        }
    } else if (parameterToDisplay == kCmosRatesDisplay){

        tubeColor = [detectorColorBar getColorForValue:[db cmosRate:aCrate card:aCard channel:aPMT]];
        
    } else if (parameterToDisplay == kBaseCurrentDisplay){

        tubeColor = [detectorColorBar getColorForValue:[db baseCurrent:aCrate card:aCard channel:aPMT]];
        
    }  else if (parameterToDisplay == kFifoDisplay){

        float fecfifo = [db fifo:aCrate card:aCard];
        tubeColor = [detectorColorBar getColorForValue:fecfifo];
        
    }  else if (parameterToDisplay == kRatesDisplay){

        float xl3rate = [db xl3Rate:aCrate]*1000.0;
        tubeColor = [detectorColorBar getColorForValue:xl3rate];
        
    }
    
    return tubeColor;
}

- (NSColor *) getFECVoltageColor:(int)aCrate card:(int)aCard voltage:(int)aVoltage
{
    float fecVoltage = [db fecVoltageValue:aCrate card:aCard voltage:aVoltage];
    NSColor *fecVoltageColor = [detectorColorBar getColorForValue:fabs(fecVoltage)];
    return fecVoltageColor;
}

- (NSColor *) getXL3VoltageColor:(int)aCrate voltage:(int)aVoltage
{
    float xl3Voltage = [db xl3VoltageValue:aCrate voltage:aVoltage];
    NSColor *xl3VoltageColor = [detectorColorBar getColorForValue:fabs(xl3Voltage)];
    return xl3VoltageColor;
}

- (NSColor *) getCrateColor:(int)aCrate
{
    float xl3rate = [db xl3Rate:aCrate]*1000.0;
    return [detectorColorBar getColorForValue:xl3rate];
}

- (NSColor *) getCardColor:(int)aCrate card:(int)aCard
{
    float fiforate = [db fifo:aCrate card:aCard];
    return [detectorColorBar getColorForValue:fiforate];
}

//update display with respect to selected view (crate or PSUP), variable type, mousedown etc
- (void)updateSNODetectorView
{	
    previousParameterDisplayed = parameterToDisplay;
    [self updateAxes];
    [self resetStats];
	[self setNeedsDisplay:YES];
}

- (void) resetStats
{
    numTubesOnline=0;
    numUnknownTubes=0;
    numOwlTubes=0;
    numLowGainTubes=0;
    numButtTubes=0;
    numNeckTubes=0;
}

- (void) updateAxes
{
    [[detectorColorBar colorAxis] setAttributes:colorBarAxisAttributes];
	
    if (parameterToDisplay == kTubeTypeDisplay){

    } else if (parameterToDisplay == kCmosRatesDisplay){
        if(![[axisChanges objectAtIndex:parameterToDisplay] boolValue] ||
           previousParameterDisplayed != parameterToDisplay){
            [[detectorColorBar colorAxis] setMinValue:0];
            [[detectorColorBar colorAxis] setMaxValue:5000];
            [[detectorColorBar colorAxis] setAxisMinLimit:0];
            [[detectorColorBar colorAxis] setAxisMaxLimit:10000000];
        }
                
    } else if (parameterToDisplay == kBaseCurrentDisplay){
        if(![[axisChanges objectAtIndex:parameterToDisplay] boolValue] ||
           previousParameterDisplayed != parameterToDisplay){
            [[detectorColorBar colorAxis] setMinValue:0];
            [[detectorColorBar colorAxis] setMaxValue:50];
            [[detectorColorBar colorAxis] setAxisMinLimit:0];
            [[detectorColorBar colorAxis] setAxisMaxLimit:10000000];
        }
        
    }  else if (parameterToDisplay == kFifoDisplay){
        if(![[axisChanges objectAtIndex:parameterToDisplay] boolValue] ||
           previousParameterDisplayed != parameterToDisplay){
            [[detectorColorBar colorAxis] setMinValue:0];
            [[detectorColorBar colorAxis] setMaxValue:1000000];
            [[detectorColorBar colorAxis] setAxisMinLimit:0];
            [[detectorColorBar colorAxis] setAxisMaxLimit:10000000];
        }
        
    }  else if (parameterToDisplay == kRatesDisplay){
        if(![[axisChanges objectAtIndex:parameterToDisplay] boolValue] ||
           previousParameterDisplayed != parameterToDisplay){
            [[detectorColorBar colorAxis] setMinValue:0];
            [[detectorColorBar colorAxis] setMaxValue:10000];
            [[detectorColorBar colorAxis] setAxisMinLimit:0];
            [[detectorColorBar colorAxis] setAxisMaxLimit:10000000];
        }
        
    }  else if (parameterToDisplay == kFECVoltagesDisplay){
        if(![[axisChanges objectAtIndex:parameterToDisplay] boolValue] ||
           previousParameterDisplayed != parameterToDisplay){
            [[detectorColorBar colorAxis] setMinValue:0];
            [[detectorColorBar colorAxis] setMaxValue:30];
            [[detectorColorBar colorAxis] setAxisMinLimit:0];
            [[detectorColorBar colorAxis] setAxisMaxLimit:10000000];
        } 
        
    } else if (parameterToDisplay == kXL3VoltagesDisplay){
        if(![[axisChanges objectAtIndex:parameterToDisplay] boolValue] ||
           previousParameterDisplayed != parameterToDisplay){
            [[detectorColorBar colorAxis] setMinValue:0];
            [[detectorColorBar colorAxis] setMaxValue:10];
            [[detectorColorBar colorAxis] setAxisMinLimit:0];
            [[detectorColorBar colorAxis] setAxisMaxLimit:1000];
        } 

    }
}

- (BOOL)isFlipped
{
	return YES;
}

- (void) mouseDown:(NSEvent*)anEvent
{
	selectedCrate = -1;
	selectedCard = -1;
	selectedChannel = -1;	
    selectedVoltage = -1;
	
    NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	NSBezierPath *aPath = nil;
	
    int crate,card,pmt,iVoltage;
    if (parameterToDisplay != kFECVoltagesDisplay && parameterToDisplay != kXL3VoltagesDisplay){
        for(crate=0;crate<kMaxSNOCrates-1;crate++){
            for(card=0;card<kCardsPerCrate;card++){
                for(pmt=0;pmt<kNumSNOPmts;pmt++){
                    int tubeIndex = kChannelsPerCrate * crate + kChannelsPerBoard* card + pmt;
				
                    if (pickPSUPView) {
                        aPath = [channelRectsInPSUPView objectAtIndex:tubeIndex];
                    }else if (!pickPSUPView) {
                        aPath = [channelRectsInCrateView objectAtIndex:tubeIndex];
                    }

                    if([aPath containsPoint:localPoint]){
                        selectedCrate = crate;
                        selectedCard = card;
                        selectedChannel = pmt;
                        break;
                    }				
                }
            }
        }
    } else if (parameterToDisplay == kFECVoltagesDisplay) {
        for (crate=0; crate<kMaxSNOCrates-1; crate++) {
            for (card=0; card<kNumSNOCards; card++) {
                for (iVoltage=0; iVoltage<kNumFecMonitorAdcs; iVoltage++) {
                    int voltageIndex = kNumSNOCards*kNumFecMonitorAdcs*crate + kNumFecMonitorAdcs*card + iVoltage;
                    
                    aPath = [voltageRectsInCrateView objectAtIndex:voltageIndex];
                    
                    if ([aPath containsPoint:localPoint]) {
                        selectedCrate = crate;
                        selectedCard = card;
                        selectedVoltage = iVoltage;
                        break;
                    }
                }
            }
        }
    } else if (parameterToDisplay == kXL3VoltagesDisplay){
        for (crate=0; crate<kMaxSNOCrates-1; crate++){
            for (iVoltage=0;iVoltage<kNumXL3Voltages;iVoltage++){
                int voltageIndex = kNumXL3Voltages*crate + iVoltage;
                
                aPath = [xl3VoltageRectsInCrateView objectAtIndex:voltageIndex];
                
                if ([aPath containsPoint:localPoint]){
                    selectedCrate = crate;
                    selectedXL3Voltage = iVoltage;
                    break;
                }
            }
        }
    }

    if (selectedCrate!=-1){
        [self resetStats];
        [self setNeedsDisplay:YES];
    }
}

@end