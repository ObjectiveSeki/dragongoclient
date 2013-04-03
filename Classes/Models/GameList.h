//
//  Represents a paginated list of games on DGS.
//

#import <Foundation/Foundation.h>
@class Game;

@interface GameList : NSObject <NSCoding>

@property(nonatomic, strong) NSOrderedSet *games;
@property(nonatomic, copy) NSString *pathFormat;
@property(nonatomic) BOOL hasMorePages;
@property(nonatomic) int offset;

- (NSString *)pathForMoreGames:(int)limit;
- (void)removeGame:(Game *)game;
- (void)addGames:(NSOrderedSet *)games;
- (NSUInteger)count;

@end
