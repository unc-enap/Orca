//
//  ORPluginProtocol.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ORPluginProtocol
- (id) 		initWithBundle:(NSBundle*)theBundle; 
- (void) 	dealloc;
- (NSView*) view;
- (NSString*) viewName;

@end
