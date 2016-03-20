#import "GameList.h"

@interface GameList ()

@property(nonatomic, copy) NSOrderedSet *games;
@property(nonatomic, copy) NSOrderedSet *invites;
@property(nonatomic, copy) NSString *pathFormat;
@property(nonatomic) BOOL hasMorePages;
@property(nonatomic) int offset;

@end

@implementation GameList

- (id)init
{
    return [self initWithPathFormat:nil];
}

- (id)initWithPathFormat:(NSString *)pathFormat {
    return [self initWithGames:[[NSOrderedSet alloc] init] invites:[[NSOrderedSet alloc] init] pathFormat:pathFormat hasMorePages:YES offset:0];
}

- (id)initWithGames:(NSOrderedSet *)games
            invites:(NSOrderedSet *)invites
         pathFormat:(NSString *)pathFormat
       hasMorePages:(BOOL)hasMorePages
             offset:(int)offset;
{
    self = [super init];
    if (self) {
        _games = [games copy];
        _invites = [invites copy];
        _pathFormat = [pathFormat copy];
        _hasMorePages = hasMorePages;
        _offset = offset;
    }
    return self;
}

- (NSString *)pathForMoreGames:(int)limit {
    return S(self.pathFormat, limit, self.offset);
}

- (NSUInteger)count {
    return [self.games count];
}

- (NSUInteger)inviteCount {
    return [self.invites count];
}

- (NSUInteger)hash {
    return self.games.hash;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    MutableGameList *mutableGameList = [[MutableGameList allocWithZone:zone] init];
    
    mutableGameList.pathFormat = self.pathFormat;
    mutableGameList.games = self.games;
    mutableGameList.offset = self.offset;
    mutableGameList.hasMorePages = self.hasMorePages;
    
    return mutableGameList;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
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
    [encoder encodeObject:self.invites forKey:@"invites"];
    [encoder encodeObject:self.pathFormat forKey:@"pathFormat"];
    [encoder encodeBool:self.hasMorePages forKey:@"hasMorePages"];
    [encoder encodeInt:self.offset forKey:@"offset"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    return [self initWithGames:[decoder decodeObjectForKey:@"games"]
                       invites:[decoder decodeObjectForKey:@"invites"]
                    pathFormat:[decoder decodeObjectForKey:@"pathFormat"]
                  hasMorePages:[decoder decodeBoolForKey:@"hasMorePages"]
                        offset:[decoder decodeIntForKey:@"offset"]];
}

@end

#pragma mark - Mutable Game List

@implementation MutableGameList

@dynamic games, invites, pathFormat, hasMorePages, offset;

- (void)removeGame:(Game *)game {
    NSMutableOrderedSet *mutableGames = [self.games mutableCopy];
    [mutableGames removeObject:game];
    _games = mutableGames;
}

- (void)addGames:(NSOrderedSet *)moreGames {
    NSMutableOrderedSet *mutableGames = [self.games mutableCopy];
    [mutableGames unionOrderedSet:moreGames];
    _games = mutableGames;
}

- (void)removeInvite:(Invite *)invite {
    NSMutableOrderedSet *mutableInvites = [self.invites mutableCopy];
    [mutableInvites removeObject:invite];
    _invites = mutableInvites;
}

- (void)addInvites:(NSOrderedSet *)moreInvites {
    NSMutableOrderedSet *mutableInvites = [self.invites mutableCopy];
    [mutableInvites unionOrderedSet:moreInvites];
    _invites = mutableInvites;
}

// Adding implementations of setters since these properties are synthesized
// in the superclass, where they are declared as readonly. (NOTE: I'm not
// confident these are needed, and when I have tests up and running, I'd like
// to add some tests to see one way or the other. These are an effort to
// correctly respond to the compiler warnings I'm seeing, but they might be
// superfluous.)

- (void)setPathFormat:(NSString *)pathFormat {
    _pathFormat = pathFormat;
}

- (void)setHasMorePages:(BOOL)hasMorePages {
    _hasMorePages = hasMorePages;
}

- (void)setOffset:(int)offset {
    _offset = offset;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[GameList allocWithZone:zone] initWithGames:self.games
                                                invites:self.invites
                                             pathFormat:self.pathFormat
                                           hasMorePages:self.hasMorePages
                                                 offset:self.offset];
}

@end

