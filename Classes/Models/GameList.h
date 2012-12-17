//
//  Represents a paginated list of games on DGS. 
//

#import <Foundation/Foundation.h>
@class GameList;
@class Game;

typedef void (^PageLoaderBlock)(GameList *gameList, NSString *nextPagePath, void (^onSuccess)(), void (^onError)(NSError *error));

@interface GameList : NSObject {
}

@property(nonatomic, strong) NSArray *games;
@property(nonatomic, copy) NSString *nextPagePath;
@property(nonatomic, readonly) PageLoaderBlock pageLoader;

- (id)initWithPageLoader:(PageLoaderBlock)aPageLoader;

- (void)loadNextPage:(void(^)(GameList *gameList))onSuccess onError:(void(^)(NSError *error))onError;
- (BOOL)hasMorePages;

- (void)updateGame:(Game *)game atIndex:(NSInteger)index;
- (void)appendGames:(NSArray *)games;

@end
