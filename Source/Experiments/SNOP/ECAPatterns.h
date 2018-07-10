//
//  ECAPatterns.h
//  Orca
//
//  Created by Javier Caravaca on 1/12/17.
//
//  ECA Patterns: pedestal masks per each of the ECA steps
//  Included patterns:
//     1. Double-beta running
//     2. Solar running
//     3. Diagnostic (similar to SNO: crate-by-crate)
//     4. Bonus diagnostic (ahem, couldn't resist)
//     5. Channel by channel (i-th channel on all cards and crates; i runs from 0-31)
//     6. SNO patterns (half-crate-by-half-crate)
//

#ifndef Orca_ECAPatterns_h
#define Orca_ECAPatterns_h

#define SNOP_NCRATES 19
#define SNOP_NCARDS 16

int getECAPatternNSteps(int pattern);

NSMutableArray* eca_pattern_bb();
NSMutableArray* eca_pattern_solar();
NSMutableArray* eca_pattern_crates();
NSMutableArray* eca_pattern_bonus();
NSMutableArray* eca_pattern_channels();
NSMutableArray* eca_pattern_hcrates();
NSMutableArray* getECAPattern(int pattern);
NSString* getECAPatternName(int pattern);

#endif
