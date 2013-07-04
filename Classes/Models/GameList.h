//
//  Represents a paginated list of games on DGS.
//

#import <Foundation/Foundation.h>
@class Game;

@interface GameList : NSObject <NSCoding, NSCopying, NSMutableCopying>

@property(nonatomic, copy, readonly) NSOrderedSet *games;
@property(nonatomic, copy, readonly) NSString *pathFormat;
@property(nonatomic, readonly) BOOL hasMorePages;
@property(nonatomic, readonly) int offset;

- (id)initWithPathFormat:(NSString *)pathFormat;

- (id)initWithGames:(NSOrderedSet *)games
         pathFormat:(NSString *)pathFormat
       hasMorePages:(BOOL)hasMorePages
             offset:(int)offset;

- (NSString *)pathForMoreGames:(int)limit;
- (NSUInteger)count;

@end

#pragma mark - Mutable Game List

@interface MutableGameList : GameList

@property(nonatomic, copy) NSOrderedSet *games;
@property(nonatomic, copy) NSString *pathFormat;
@property(nonatomic) BOOL hasMorePages;
@property(nonatomic) int offset;

- (void)removeGame:(Game *)game;
- (void)addGames:(NSOrderedSet *)games;

@end