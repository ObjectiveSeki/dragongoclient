//
//  FuegoBoard.h
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

@interface FuegoBoard : NSObject {
	GoGameRecord *goGame;
	GoBoard *goBoard;
	SgNode *startNode;
	Move *resignMove;
	NSArray *markedGroups;
	NSArray *changedGroups;
}

@property(nonatomic, retain) Move *resignMove;
@property(nonatomic, retain) NSArray *markedGroups;
@property(nonatomic, retain) NSArray *changedGroups;

+ (void)initFuego;
+ (void)finishFuego;

- initWithSGFString:(NSString *)sgfString;

- (int)size;
- (NSArray *)moves;
- (int)moveNumber;
- (Move *)currentMove;
- (Move *)lastMove;
- (NSArray *)markedStones;
- (NSArray *)changedStones;
- (NSArray *)deadStones;
- (void)undoLastMove;
- (bool)playStoneAtRow:(int)row column:(int)col;
- (bool)markDeadStonesAtRow:(int)row column:(int)col;
- (void)pass;
- (void)resign;
- (int)handicap;

// NO if the game has a handicap and the handicap stones have just been placed
- (bool)beginningOfHandicapGame;

// YES if the game has a hadicap and handicap stones still need to be placed
- (bool)needsHandicapStones;

// If handicap stones have just been placed, return the handicap stones. Otherwise, return nil.
- (NSArray *)handicapStones;

// Captured endgame territory, in an array of moves
- (NSArray *)territory;

- (bool)gameEnded;

- (bool)canUndo;
- (bool)canPlayMove;
- (bool)canPassOrResign;
- (bool)canSubmit;

- (NSString *)name:(MovePlayer)movePlayer;
- (int)captures:(MovePlayer)movePlayer;
- (float)score;

@end
