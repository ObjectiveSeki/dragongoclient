//
//  Represents a paginated list of games on DGS. 
//

#import <Foundation/Foundation.h>
@class GameList;

typedef void (^PageLoaderBlock)(GameList *gameList, NSString *nextPagePath, void (^onSuccess)());

@interface GameList : NSObject {
    NSArray *games;
    NSString *nextPagePath;
    PageLoaderBlock pageLoader;
}

@property(nonatomic, retain) NSArray *games;
@property(nonatomic, copy) NSString *nextPagePath;

- (id)initWithPageLoader:(PageLoaderBlock)aPageLoader;

- (void)loadNextPage:(void(^)(GameList *gameList))onSuccess;
- (BOOL)hasMorePages;

- (void)appendGames:(NSArray *)games;

@end
