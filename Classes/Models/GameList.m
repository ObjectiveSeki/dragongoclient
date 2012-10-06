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

- (void)loadNextPage:(void(^)(GameList *gameList))onSuccess {
    if ([self hasMorePages] && self.pageLoader) {
        self.pageLoader(self, self.nextPagePath, ^() {
            onSuccess(self);
        });
    }
}

- (BOOL)hasMorePages {
    return self.nextPagePath != nil;
}

- (void)appendGames:(NSArray *)moreGames {
    NSMutableArray *mutableGames = [self.games mutableCopy];
    [mutableGames addObjectsFromArray:moreGames];
    self.games = mutableGames;
}

@end
