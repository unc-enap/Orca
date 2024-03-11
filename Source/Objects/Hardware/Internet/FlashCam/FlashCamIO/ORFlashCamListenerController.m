//  Orca
//  ORFlashCamListenerController.m
//
//  Created by Tom Caldwell on Mar 1, 2023
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamListenerController.h"
#import "ORFlashCamListenerModel.h"
#import "ANSIEscapeHelper.h"

@interface ORFlashCamListenerController (private)
- (NSAttributedString*) makeAttributedString:(NSString*)s;
@end

@implementation ORFlashCamListenerController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamListener"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [self listenerConfigChanged:nil];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(fcLogChanged:)
                         name : ORFlashCamListenerModelFCLogChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(fcRunLogChanged:)
                         name : ORFlashCamListenerModelFCRunLogChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(fcRunLogFlushed:)
                         name : ORFlashCamListenerModelFCRunLogFlushed
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(listenerConfigChanged:)
                         name : ORFlashCamListenerModelConfigChanged
                       object : nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self fcLogChanged:nil];
    [self listenerConfigChanged:nil];
}


#pragma mark •••Interface management

- (void) fcLogChanged:(NSNotification*)note
{
    if(note) if([note object] != model) return;
    [nlinesTextField setIntegerValue:(NSInteger)[model fclogLines]];
    [[historyView textStorage] deleteCharactersInRange:NSMakeRange(0, [[historyView textStorage] length])];
    [[errorView   textStorage] deleteCharactersInRange:NSMakeRange(0, [[errorView   textStorage] length])];
    for(NSUInteger i=[model fclogLines]-1; i<[model fclogLines]; i--){
        NSString* line = [model fclog:i];
        if([line isEqualToString:@""]) continue;
        NSAttributedString* s = [self makeAttributedString:line];
        [[historyView textStorage] appendAttributedString:s];
        if([line rangeOfString:@"error"   options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [line rangeOfString:@"warning" options:NSCaseInsensitiveSearch].location != NSNotFound)
            [[errorView textStorage] appendAttributedString:s];
    }
    for(NSUInteger i=[model fcrunlogLines]-1; i<[model fcrunlogLines]; i--){
        NSString* line = [model fcrunlog:i];
        NSAttributedString* s = [self makeAttributedString:line];
        [[historyView textStorage] appendAttributedString:s];
        if([line rangeOfString:@"error"   options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [line rangeOfString:@"warning" options:NSCaseInsensitiveSearch].location != NSNotFound)
            [[errorView textStorage] appendAttributedString:s];
    }
    [historyView scrollRangeToVisible:NSMakeRange([[historyView textStorage] length], 0)];
    [historyView setNeedsDisplay:YES];
    [errorView   scrollRangeToVisible:NSMakeRange([[errorView   textStorage] length], 0)];
    [errorView   setNeedsDisplay:YES];

}

- (void) fcRunLogChanged:(NSNotification*)note
{
    if(note) if([note object] != model) return;
    NSString* line = [model fcrunlog:0];
    NSAttributedString* s = [self makeAttributedString:line];
    [[cycleView   textStorage] appendAttributedString:s];
    [cycleView    scrollRangeToVisible:NSMakeRange([[cycleView  textStorage] length], 0)];
    [cycleView    setNeedsDisplay:YES];
    [[historyView textStorage] appendAttributedString:s];
    [historyView  scrollRangeToVisible:NSMakeRange([[historyView textStorage] length], 0)];
    [historyView  setNeedsDisplay:YES];
    if([line rangeOfString:@"error"   options:NSCaseInsensitiveSearch].location != NSNotFound ||
       [line rangeOfString:@"warning" options:NSCaseInsensitiveSearch].location != NSNotFound){
        [[errorView textStorage] appendAttributedString:s];
        [errorView  scrollRangeToVisible:NSMakeRange([[errorView textStorage] length], 0)];
        [errorView  setNeedsDisplay:YES];
    }
}

- (void) fcRunLogFlushed:(NSNotification*)note
{
    if(note) if([note object] != model) return;
    [[cycleView textStorage] deleteCharactersInRange:NSMakeRange(0, [[cycleView textStorage] length])];
    [cycleView setNeedsDisplay:YES];
    [self fcLogChanged:note];
}

- (void) listenerConfigChanged:(NSNotification*)note
{
    if(!model) return;
    if(note) if([note object] != model) return;
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Listener %lu, on %@ at %@:%d",
                             (unsigned long)[model tag], [model interface], [model ip],
                             (int)[(ORFlashCamListenerModel*)model port]]];
}


#pragma mark •••Actions

- (IBAction) saveHistoryAction:(id)sender
{
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save log as:"];
    NSString* startDir = NSHomeDirectory();
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if(result == NSFileHandlingPanelOKButton){
            NSString* newPath = [[savePanel URL] path];
            if(![[newPath pathExtension] isEqualToString:@"rtfd"])
                newPath = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"rtfd"];
            @synchronized(self){ [historyView writeRTFDToFile:newPath atomically:YES]; }
        }
    }];
}

- (IBAction) clearHistoryAction:(id)sender
{
    [model clearFCLog];
}

- (IBAction) nlinesAction:(id)sender
{
    [model setFCLogLines:[sender integerValue]];
}

@end

@implementation ORFlashCamListenerController (private)

- (NSAttributedString *)makeAttributedString:(NSString*)str
{
    NSString* s = [[str copy]autorelease];
    NSMutableAttributedString* attstr = [[[NSMutableAttributedString alloc] init] autorelease];
    if([s length] >= 18){
        NSString* date = [s substringWithRange:NSMakeRange(0, 18)];
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10],
                              NSFontAttributeName, [NSColor grayColor], NSForegroundColorAttributeName, nil];
        [attstr appendAttributedString:[[[NSAttributedString alloc] initWithString:date
                                                                         attributes:dict] autorelease]];
        s = [s substringWithRange:NSMakeRange(18, [s length]-18)];
    }
    NSColor* color = [NSColor blackColor];
    if([s rangeOfString:@"error"   options:NSCaseInsensitiveSearch].location != NSNotFound ||
       [s rangeOfString:@"warning" options:NSCaseInsensitiveSearch].location != NSNotFound){
        color = [NSColor redColor];
    }
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Courier New" size:10],
                          NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
    [attstr appendAttributedString:[[[NSAttributedString alloc] initWithString:s attributes:dict] autorelease]];
    return attstr;
}

@end
