//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

#import "MajoranaModel.h"
#import "MajoranaDetectorView.h"
#import "ORColorScale.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORAxis.h"


@interface MajoranaDetectorView (private)
- (void) makeAllSegments;
- (void) makeDetectors;
- (void) makeVeto;
- (void) drawLabels;
@end

@implementation MajoranaDetectorView

- (void) dealloc
{
    [detectorOutlines release];
    int i;
    for(i=0;i<14;i++){
        [stringLabel[i] release];
    }
    [stringLabelAttributes release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[[detectorColorScale colorAxis] setLabel:@"Detectors"];
	[[vetoColorScale colorAxis] setLabel:@"Veto"];
	[[vetoColorScale colorAxis] setOppositePosition:YES];
	[detectorColorScale setExcludeZero:YES];
	[vetoColorScale setExcludeZero:YES];
}
- (void) setViewType:(int)aViewType
{
	viewType = aViewType;
}
- (void) makeCrateImage
{
    if(!crateImage){
        crateImage = [[NSImage imageNamed:@"Vme64Crate"] copy];
        NSSize imageSize = [crateImage size];
        [crateImage setSize:NSMakeSize(imageSize.width*.7,imageSize.height*.7)];
    }
}

#define kCrateInsideX        85
#define kCrateInsideY        35
#define kCrateSeparation     10
#define kCrateInsideWidth   237
#define kCrateInsideHeight   85


- (void) drawRect:(NSRect)rect
{
    [[NSColor colorWithCalibratedRed:.88 green:.88 blue:.88 alpha:1] set];
    [NSBezierPath fillRect:rect];
    
	if(viewType == kUseCrateView){
        [self makeCrateImage];
 		NSFont* font = [NSFont systemFontOfSize:9.0];
		NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor blackColor],NSForegroundColorAttributeName,nil];
       int crate;
        for(crate=0;crate<3;crate++){
            float yOffset = crate*[crateImage imageRect].size.height+kCrateSeparation;
            NSRect destRect = NSMakeRect(70,yOffset,[crateImage imageRect].size.width,[crateImage imageRect].size.height);
            [crateImage drawInRect:destRect fromRect:[crateImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
            
            [[NSColor blackColor]set];
            NSRect inside = NSMakeRect(kCrateInsideX,yOffset+kCrateInsideY,kCrateInsideWidth,kCrateInsideHeight);
            [NSBezierPath fillRect:inside];
            
            [[NSColor grayColor]set];
            float dx = inside.size.width/21.;
            //float dy = inside.size.height/10.;
            [NSBezierPath setDefaultLineWidth:.5];
            int i;
            for(i=0;i<21;i++){
                 [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y) toPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y + inside.size.height)];
            }
            float xx = 0;
            for(i=0;i<21;i++){
                if(i%2 == 0){
                    NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",i] attributes:attrsDictionary];
                    float sw = [s size].width;
                    [s drawAtPoint:NSMakePoint(kCrateInsideX+5-sw/2 + xx,yOffset+kCrateInsideY-10)];
                    [s release];
                }
                xx += 11.3;
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y) toPoint:NSMakePoint(inside.origin.x+i*dx,inside.origin.y + inside.size.height)];
            }
            NSString* crateLabel = @"";
            if(crate==0)      crateLabel = @"Module 1 Crate";
            else if(crate==1) crateLabel = @"Module 2 Crate";
            else if(crate==2) crateLabel = @"Veto Crate";
            
            NSAttributedString* s = [[NSAttributedString alloc] initWithString:crateLabel attributes:attrsDictionary];
            float sw = [s size].width;
            [s drawAtPoint:NSMakePoint(kCrateInsideX+kCrateInsideWidth/2-sw/2,yOffset+kCrateInsideY+kCrateInsideHeight+1)];
            [s release];
        }
	}
    else if(viewType == kUseDetectorView){
        [[NSColor darkGrayColor]set];
        for(id aDetector in detectorOutlines){
            [aDetector fill];
        }
        [self drawLabels];
    }

    [super drawRect:rect];
    

}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
	if(setIndex==0) return [detectorColorScale getColorForValue:aValue];
	else            return [vetoColorScale getColorForValue:aValue];
}

- (void) downArrow
{
/*
    int n = [detectorOutlines count]*2;
    if(n==0)return;
	selectedPath++;
	if(selectedSet == 0) selectedPath %= n;
 */
}

- (void) upArrow
{
    /*
    int n = [detectorOutlines count]*2;
    if(n<1)return;
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = n-1;
	}
*/
}

@end
@implementation MajoranaDetectorView (private)
- (void) makeAllSegments
{	
	[super makeAllSegments];
	
	if(viewType == kUseCrateView){
        [self makeCrateImage];

		float dx = kCrateInsideWidth/21.;
        int numSets = [delegate numberOfSegmentGroups];
        int set;
        for(set=0;set<numSets;set++){
            float dy;
            if(set==0)  dy= kCrateInsideHeight/10.;
            else        dy= kCrateInsideHeight/16.;
            NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumDetectors];
            NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumDetectors];

            ORSegmentGroup* aGroup = [delegate segmentGroup:set];
            int i;
            int n = [aGroup numSegments];
            for(i=0;i<n;i++){
                ORDetectorSegment* aSegment = [aGroup segment:i];
                int crate    = [[aSegment objectForKey:[aSegment mapEntry:[aSegment crateIndex] forKey:@"key"]] intValue]-1; //we count from zero here;
                int cardSlot = [aSegment cardSlot];
                int channel  = [aSegment channel];
                BOOL drawOnScreen = YES;
                if(channel < 0 || crate<0)drawOnScreen = NO; //we have to make the segment, but we'll draw off screen when not mapped
                
                float yOffset = -5000;;
                if(drawOnScreen)yOffset = crate*[crateImage imageRect].size.height+kCrateSeparation+kCrateInsideY;
                
                
                NSRect channelRect = NSMakeRect(kCrateInsideX+cardSlot*dx, yOffset + (channel*dy),dx,dy);
                
                [segmentPaths addObject:[NSBezierPath bezierPathWithRect:channelRect]];
                [errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(channelRect, 4, 4)]];
            }
            [segmentPathSet addObject:segmentPaths];
            [errorPathSet addObject:errorPaths];
        }
	}
	
	else if(viewType == kUseDetectorView) {
		[self makeDetectors];
		[self makeVeto];
	}
    [self setNeedsDisplay:YES];
}


- (void) drawLabels
{
    if(!stringLabelAttributes){
        NSFont* theFont = [NSFont fontWithName:@"Geneva" size:8];
        stringLabelAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
                                  theFont,NSFontAttributeName,
                                  [NSColor blueColor],NSForegroundColorAttributeName,
                                  nil] retain];
    }
    int i;
    float x = 70;
    float y = 368;
    for(i=0;i<7;i++){
        [stringLabel[i] drawAtPoint:NSMakePoint(x,y) withAttributes:stringLabelAttributes];
        x += 40;
    }
    x = 70;
    y = 251;
    for(i=7;i<14;i++){
        [stringLabel[i] drawAtPoint:NSMakePoint(x,y) withAttributes:stringLabelAttributes];
        x += 40;
    }
}

- (void) makeDetectors
{
    [delegate setDetectorStringPositions];
    
    NSMutableArray* segmentPaths     = [NSMutableArray arrayWithCapacity:kNumDetectors];
    NSMutableArray* errorPaths       = [NSMutableArray arrayWithCapacity:kNumDetectors];
    [detectorOutlines release];
    detectorOutlines = [[NSMutableArray arrayWithCapacity:kNumDetectors] retain];
    
    float height = [self bounds].size.height;
    float detWidth = 30;
    float dh = detWidth/2.;
    float detHeight = dh;
    float detSpacing = 5;
    
    ORSegmentGroup* aGroup = [delegate segmentGroup:0];
    int numDetectors = [aGroup numSegments];
    
    float x;
    float y;
    float yOffset[14][5];
    int i;
    for(i=0;i<14;i++){
        int j;
        for(j=0;j<5;j++){
            if(i>=7)yOffset[i][j] = height-182-(j*(dh+detSpacing));
            else    yOffset[i][j] = height-65-(j*(dh+detSpacing));
        }
        
        [stringLabel[i] autorelease];
        stringLabel[i] = [@"" copy];
    }
    
    for(i=0;i<numDetectors/2;i++){
        int detectorIndex = i*2;
        ORDetectorSegment* aSegment = [aGroup segment:detectorIndex];
        
        int position         = [[aSegment objectForKey:@"kPosition"]intValue];
        int stringNum        = [[aSegment objectForKey:@"kStringNum"]intValue];
        NSString* stringName = [aSegment objectForKey:@"kStringName"];
        
        if(position> numDetectors/2|| stringNum>numDetectors/2){
            //this detector is not part of a string so draw offscreen
            x = -100;
            y = -100;
        }
        else {
            if([delegate validateDetector:detectorIndex]){
                ORDetectorSegment* aSegment = [aGroup segment:detectorIndex];
                int type = [[aSegment objectForKey:@"kDetectorType"] intValue];
                if(type>0)  detHeight = dh * 1.3;
                else        detHeight = dh;
                
                if(type>0){
                    int j;
                    for(j=position+1;j<5;j++){
                        yOffset[stringNum][j]-=((dh*1.3 - dh));
                    }
                }
                
                x = 67 + stringNum%7 * 40;
                y = yOffset[stringNum][position];

                [stringLabel[stringNum] autorelease];
                if([stringName length]==0 || [stringName hasPrefix:@"-"]){
                    stringLabel[stringNum] = [[NSString stringWithFormat:@"Str%d,%d",stringNum/7+1,stringNum%7 + 1] retain];
                }
                else {
                    stringLabel[stringNum] = [[NSString stringWithString:stringName] retain];
                }
            }
            else {
                x = -100;
                y = -100;
            }
        }
        
        //low gain part
        NSRect r = NSMakeRect(x,y-detHeight/2,detWidth,detHeight/2.);
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -5, -5)]];
        
        //high gain part
        r = NSMakeRect(x,y-detHeight,detWidth,detHeight/2.);
        [segmentPaths   addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths     addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -5, -5)]];
        
        //draw an outline also
        r = NSMakeRect(x-2,y-detHeight-2,detWidth+4,detHeight+4);
        [detectorOutlines   addObject:[NSBezierPath bezierPathWithRect:r]];
        
        //if(stringNum>=0)yOffset[stringNum] -= (detHeight+detSpacing);
        
    }
    //store into the whole set
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
         
    [self setNeedsDisplay:YES];
}

- (void) makeVeto
{
    NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:kNumVetoSegments];
    NSMutableArray* errorPaths   = [NSMutableArray arrayWithCapacity:kNumVetoSegments];

    float height = [self bounds].size.height;
    float width = [self bounds].size.width;
    int i;
    
    //Overfloor panel #1
    float y = 10;
    float w = 12;
    float x = 10;
    for(i=0;i<6;i++){
        NSRect r = NSMakeRect(x,y,w*6,w);
        y+=w;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    //Overfloor panel #2
    x = w*6+30;
    y = 10;
    for(i=0;i<6;i++){
        NSRect r = NSMakeRect(x,y,w,w*6);
        x+=w;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }

    //Top panels
    w = 18;
    x = width - 10 - w * 4;
    y = 10;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,w*4,w);
        y+=w;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }

    //Outer Panel1 (left side)
    //Inner Panel1
    x = 10;
    float h = 235;
    w = 10;
    y = 145;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,w,h);
        x += w;
        if(i==1)x+=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    
    
    //Outer Panel2
    //Inner Panel2
    x = 10 + 40 + 15;
    w = 10;
    y = 140 - 40 - 5;
    h = 275;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,h,w);
        y += w;
        if(i==1)y+=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
   
    //Outer Panel3
    //Inner Panel3
    w = 10;
    y = 145;
    x = width-5-w;
    h = 235;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,w,h);
        x -= w;
        if(i==1)x-=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    
    //Outer Panel4 (top in view)
    //Inner Panel4
    x = 10 + 40 + 15;
    w = 10;
    y = height - 11;
    h = 275;
    for(i=0;i<4;i++){
        NSRect r = NSMakeRect(x,y,h,w);
        y -= w;
        if(i==1)y-=5;
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
        [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -2, -2)]];
    }
    //store into the whole set
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
}

- (NSColor*) outlineColor:(int)aSet
{
    if(aSet==0) return [NSColor grayColor];
    else return[NSColor lightGrayColor];
}


@end
