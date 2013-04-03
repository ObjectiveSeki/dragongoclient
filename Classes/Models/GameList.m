#import "GameList.h"

@interface GameList ()
@end

@implementation GameList

- (id)init
{
    self = [super init];
    if (self) {
        _games = [[NSOrderedSet alloc] init];
        _offset = 0;
        _hasMorePages = YES;
    }
    return self;
}

- (NSString *)pathForMoreGames:(int)limit {
    return S(self.pathFormat, limit, self.offset);
}

- (void)removeGame:(Game *)game {
    NSMutableOrderedSet *mutableGames = [self.games mutableCopy];
    [mutableGames removeObject:game];
    self.games = mutableGames;
}

- (void)addGames:(NSOrderedSet *)moreGames {
    NSMutableOrderedSet *mutableGames = [self.games mutableCopy];
    [mutableGames unionOrderedSet:moreGames];
    self.games = mutableGames;
}

- (NSUInteger)count {
    return [self.games count];
}

- (NSUInteger)hash {
    return self.games.hash;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self.games isEqualToOrderedSet:((GameList *)other).games];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.games forKey:@"games"];
    [encoder encodeObject:self.pathFormat forKey:@"pathFormat"];
    [encoder encodeBool:self.hasMorePages forKey:@"hasMorePages"];
    [encoder encodeInt:self.offset forKey:@"offset"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.games = [decoder decodeObjectForKey:@"games"];
        self.pathFormat = [decoder decodeObjectForKey:@"pathFormat"];
        self.hasMorePages = [decoder decodeBoolForKey:@"hasMorePages"];
        self.offset = [decoder decodeIntForKey:@"offset"];
    }
    return self;
}

@end
