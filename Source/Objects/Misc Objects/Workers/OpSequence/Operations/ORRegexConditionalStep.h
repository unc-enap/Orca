//
//  RegexConditionalStep.h
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/04.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "ORConditionalStep.h"

@interface ORRegexConditionalStep : ORConditionalStep
{
}

+ (ORRegexConditionalStep *)regexConditionalStepWithStateKey:(NSString *)key
	pattern:(NSString *)pattern
	negate:(BOOL)negate;

@end

@interface NSObject (ORRegexConditionalStep)
- (void) setStateValue:(id)value forKey:(NSString *)key;
- (id) stateValueForKey:(NSString *)key;
@end