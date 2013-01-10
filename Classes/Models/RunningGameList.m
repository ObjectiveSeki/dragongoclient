//
//  RunningGameList.m
//  DGSPhone
//
//  Created by Justin Weiss on 1/8/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "RunningGameList.h"

@implementation RunningGameList

- (void)addGames:(NSOrderedSet *)games {
    NSMutableOrderedSet *mutableGames = [games mutableCopy];
    [mutableGames removeObjectsAtIndexes:[games indexesOfObjectsPassingTest:^BOOL(Game *game, NSUInteger idx, BOOL *stop) {
        return game.myTurn;
    }]];
    [super addGames:mutableGames];
}

@end
