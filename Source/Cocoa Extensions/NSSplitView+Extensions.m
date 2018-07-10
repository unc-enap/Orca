//
//NSSplitView+Extensions.m
//  Orca
//
//  Created by Mark Howe on Monday Oct 10 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

@implementation NSSplitView (OR_NSSplitViewWithExtensions)
- (NSString*)ccd__keyForLayoutName: (NSString*)name
{
        return [NSString stringWithFormat: @"CCDNSSplitView Layout %@", name];
}

- (void)storeLayoutWithName: (NSString*)name
{
        NSString*               key = [self ccd__keyForLayoutName: name];
        NSMutableArray* viewRects = [NSMutableArray array];
        NSEnumerator*   viewEnum = [[self subviews] objectEnumerator];
        NSView*                 view;
        NSRect                  frame;

        while( (view = [viewEnum nextObject]) != nil )
        {
                if( [self isSubviewCollapsed: view] )
                        frame = NSZeroRect;
                else
                        frame = [view frame];

                [viewRects addObject: NSStringFromRect( frame )];
        }

        [[NSUserDefaults standardUserDefaults] setObject: viewRects forKey: key];
}

- (void)loadLayoutWithName: (NSString*)name
{
        NSString*               key = [self ccd__keyForLayoutName: name];
        NSMutableArray* viewRects = [[NSUserDefaults standardUserDefaults] objectForKey: key];
        NSArray*                views = [self subviews];
        int                             i, count;
        NSRect                  frame;

        count = MIN( [viewRects count], [views count] );

        for( i = 0; i < count; i++ )
        {
                frame = NSRectFromString( [viewRects objectAtIndex: i] );
                if( NSIsEmptyRect( frame ) )
                {
                        frame = [[views objectAtIndex: i] frame];
                        if( [self isVertical] )
                                frame.size.width = 0;
                        else
                                frame.size.height = 0;
                }

                [[views objectAtIndex: i] setFrame: frame];
        }
}
@end
