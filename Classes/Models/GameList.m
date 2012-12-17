#import "GameList.h"

@implementation GameList

- (id)initWithPageLoader:(PageLoaderBlock)aPageLoader;
{
    self = [super init];
    if (self) {
        _nextPagePath = nil;
        _pageLoader = [aPageLoader copy];
        _games = [[NSArray alloc] init];
    }
    
    return self;
}

- (void)loadNextPage:(void(^)(GameList *gameList))onSuccess onError:(void(^)(NSError *error))onError {
    if ([self hasMorePages] && self.pageLoader) {
        self.pageLoader(self, self.nextPagePath, ^() {
            onSuccess(self);
        }, onError);
    }
}

- (BOOL)hasMorePages {
    return self.nextPagePath != nil;
}

- (void)updateGame:(Game *)game atIndex:(NSInteger)index {
    NSMutableArray *mutableGames = [self.games mutableCopy];
    [mutableGames insertObject:game atIndex:index];
    self.games = mutableGames;
}

- (void)appendGames:(NSArray *)moreGames {
    NSMutableArray *mutableGames = [self.games mutableCopy];
    [mutableGames addObjectsFromArray:moreGames];
    self.games = mutableGames;
}

@end
