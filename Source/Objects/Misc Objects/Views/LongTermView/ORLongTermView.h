//
//  ORLongTermView.h
//  Orca
//
//  Created by Mark Howe on 5/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@interface ORLongTermView : NSView {
	IBOutlet id dataSource;
}
@end

@interface NSObject (ORLongTermView)
- (int) startingLineInLongTermView:(id)aLongTermView;
- (int) maxLinesInLongTermView:(id)aLongTermView;
- (int) numLinesInLongTermView:(id)aLongTermView;
- (int) numPointsPerLineInLongTermView:(id)aLongTermView;
- (float) longTermView:(id)aLongTermView line:(int)m point:(int)i;
@end		
