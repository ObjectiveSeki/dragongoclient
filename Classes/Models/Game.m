//
//  Game.m
//
//	Represents a game, as DGS sees it. This is pretty much a struct, 
//  all of the complicated logic is inside FuegoBoard.
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "Game.h"
#import "DGS.h"

@implementation Game

- (NSUInteger)hash {
    return self.gameId * 1000 + self.moveId;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToGame:other];
}

- (BOOL)isEqualToGame:(Game *)game {
    if (self == game) {
        return YES;
    }
    if (self.gameId == game.gameId && self.moveId == game.moveId) {
        return YES;
    }
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.sgfPath forKey:@"sgfPath"];
    [encoder encodeObject:self.detailPath forKey:@"detailPath"];
    [encoder encodeObject:self.sgfString forKey:@"sgfString"];
    [encoder encodeObject:self.opponent forKey:@"opponent"];
    [encoder encodeObject:self.time forKey:@"time"];
    [encoder encodeObject:self.lastMove forKey:@"lastMove"];
    [encoder encodeObject:self.opponentRating forKey:@"opponentRating"];
    [encoder encodeInt:self.gameId forKey:@"gameId"];
    [encoder encodeInt:self.moveId forKey:@"moveId"];
    [encoder encodeInt:self.color forKey:@"color"];
    [encoder encodeInt:self.handicap forKey:@"handicap"];
    [encoder encodeFloat:self.komi forKey:@"komi"];
    [encoder encodeBool:self.myTurn forKey:@"myTurn"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.sgfPath = [decoder decodeObjectForKey:@"sgfPath"];
        self.detailPath = [decoder decodeObjectForKey:@"detailPath"];
        self.sgfString = [decoder decodeObjectForKey:@"sgfString"];
        self.opponent = [decoder decodeObjectForKey:@"opponent"];
        self.time = [decoder decodeObjectForKey:@"time"];
        self.lastMove = [decoder decodeObjectForKey:@"lastMove"];
        self.opponentRating = [decoder decodeObjectForKey:@"opponentRating"];
        self.gameId = [decoder decodeIntForKey:@"gameId"];
        self.moveId = [decoder decodeIntForKey:@"moveId"];
        self.color = [decoder decodeIntForKey:@"color"];
        self.handicap = [decoder decodeIntForKey:@"handicap"];
        self.komi = [decoder decodeFloatForKey:@"komi"];
        self.myTurn = [decoder decodeBoolForKey:@"myTurn"];
    }
    return self;
}

@end
