//
//  Represents a paginated list of games on DGS. 
//

#import <Foundation/Foundation.h>
@class GameList;

typedef void (^PageLoaderBlock)(GameList *gameList, NSString *nextPagePath, void (^onSuccess)());

@interface GameList : NSObject {
}

@property(nonatomic, strong) NSArray *games;
@property(nonatomic, copy) NSString *nextPagePath;
@property(nonatomic, readonly) PageLoaderBlock pageLoader;

- (id)initWithPageLoader:(PageLoaderBlock)aPageLoader;

- (void)loadNextPage:(void(^)(GameList *gameList))onSuccess;
- (BOOL)hasMorePages;

- (void)appendGames:(NSArray *)games;

@end
