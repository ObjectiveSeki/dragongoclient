#import "GameList.h"

@implementation GameList

@synthesize nextPagePath, games;

- (id)initWithPageLoader:(PageLoaderBlock)aPageLoader;
{
    self = [super init];
    if (self) {
        nextPagePath = nil;
        pageLoader = [aPageLoader copy];
        games = [[NSArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [pageLoader release]; pageLoader = nil;
    self.nextPagePath = nil;
    self.games = nil;
    [super dealloc];
}

- (void)loadNextPage:(void(^)(GameList *gameList))onSuccess {
    if ([self hasMorePages] && pageLoader) {
        pageLoader(self, self.nextPagePath, ^() {
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
    [mutableGames release];
}

@end
