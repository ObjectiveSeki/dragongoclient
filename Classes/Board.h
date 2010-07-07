//
//  Board.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SgSystem.h"
#import "SgNode.h"
#import "GoGame.h"
#import "Move.h"

@interface Board : NSObject {
	GoGameRecord *goGame;
	GoBoard *goBoard;
	Move *resignMove;
}

+ (void)initFuego;
+ (void)finishFuego;

- initWithSGFString:(NSString *)sgfString boardSize:(int)boardSize;

- (int)size;
- (NSArray *)moves;
- (int)moveNumber;
- (Move *)currentMove;
- (Move *)lastMove;
- (void)undoLastMove;
- (bool)playStoneAtRow:(int)row column:(int)col;
- (void)pass;
- (void)resign;
- (int)handicap;

// NO if the game has a handicap and the handicap stones have just been placed
- (bool)beginningOfHandicapGame;

// YES if the game has a hadicap and handicap stones still need to be placed
- (bool)needsHandicapStones;

// If handicap stones have just been placed, return the handicap stones. Otherwise, return nil.
- (NSArray *)handicapStones;

@property(nonatomic, retain) Move *resignMove;

@end
