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
}

+ (void)initFuego;
+ (void)finishFuego;

- initWithSGFString:(NSString *)sgfString boardSize:(int)boardSize;

- (int)size;
- (NSArray *)moves;
- (Move *)currentMove;
- (Move *)lastMove;
- (void)undoLastMove;
- (bool)playStoneAtRow:(int)row column:(int)col;

@end
