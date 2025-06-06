//
//  ResistorDBModel.h
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

//#import "ResistorDBViewController.h"

@class ORCouchDB;

@protocol ResistorDbDelegate <NSObject>
@required
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
@end


@interface ResistorDBModel :  OrcaObject<ResistorDbDelegate>{
    NSMutableDictionary *_currentQueryResults;
    NSDictionary* _resistorDocument;
    NSNumber* _startRunNumber;
    NSNumber* _endRunNumber;
}
-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;

@property (nonatomic,copy) NSMutableDictionary *currentQueryResults;
@property (copy) NSDictionary *resistorDocument;
@property (nonatomic,copy) NSNumber* startRunNumber;
@property (nonatomic,copy) NSNumber* endRunNumber;

- (void) queryResistorDb:(int)aCrate withCard:(int)aCard withChannel:(int)aChannel;
- (void) updateResistorDb:(NSMutableDictionary*)aResistorDocDic;
- (void) addNeweResistorDoc:(NSMutableDictionary*)aResistorDocDic;
- (void) checkIfDocumentExists:(int)aCrate withCard:(int)aCard withChannel:(int)aChannel withRunRange:(NSMutableArray*)aRunRange;
- (uint32_t) getCurrentRunNumber;

@end

extern NSString* resistorDBQueryLoaded;
extern NSString* ORResistorDocExists;
extern NSString* ORResistorDocNotExists;
