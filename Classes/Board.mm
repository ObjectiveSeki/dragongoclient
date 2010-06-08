//
//  Board.mm
//  DGSPhone
//
//  Created by Justin Weiss on 6/4/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "Board.h"
#import "SgInit.h"
#import "GoInit.h"
#import "SgGameReader.h"
#import "SgNode.h"
#import "Stone.h"
#import "DGS.h"
#include <sstream>

@implementation Board

+ (void)initFuego {
	SgInit();
	GoInit();
}

+ (void)finishFuego {
	GoFini();
	SgFini();
}

- (id)initWithSGFString:(NSString *)sgfString boardSize:(int)boardSize {
	if ([super init]) {
		std::string sgfStr([sgfString UTF8String]);
		std::istringstream input(sgfStr);
		SgGameReader gameReader(input, boardSize);
		SgNode *rootNode = gameReader.ReadGame();
		goBoard = new GoBoard();
		goGame = new GoGameRecord(*goBoard);
		goGame->InitFromRoot(rootNode, true);
		
		// Fast-forward to the end of the game
		while (goGame->CanGoInDirection(SgNode::NEXT)) {
			goGame->GoInDirection(SgNode::NEXT);
		}
	}
	return self;
}

- (int)size {
	return goGame->Board().Size();
}

- (void)undoLastMove {
	goGame->GoInDirection(SgNode::PREVIOUS);
	goGame->CurrentNode()->DeleteSubtree();
}

- (Stone *)stoneFromNode:(SgNode *)node {
	Stone *currentMove = [[[Stone alloc] init] autorelease];
	currentMove.col = SgPointUtil::Col(node->NodeMove());
	currentMove.row = SgPointUtil::Row(node->NodeMove());
	currentMove.boardSize = [self size];
	if (node->NodePlayer() == SG_BLACK) {
		currentMove.player = kStonePlayerBlack;
	} else if (node->NodePlayer() == SG_WHITE) {
		currentMove.player = kStonePlayerWhite;
	}
	return currentMove;
}

- (Stone *)lastMove {
	SgNode *currentNode = goGame->CurrentNode();
	goGame->GoInDirection(SgNode::PREVIOUS);
	Stone *lastMove = [self stoneFromNode:goGame->CurrentNode()];
	goGame->GoToNode(currentNode);
	return lastMove;
}

- (Stone *)currentMove {
	return [self stoneFromNode:goGame->CurrentNode()];
}

- (NSArray *)stones {
	NSMutableArray *stones = [NSMutableArray array];
	
	for (GoBoard::Iterator it(goGame->Board()); it; ++it) {
		Stone *stone = [[Stone alloc] init];
		stone.col = SgPointUtil::Col(*it);
		stone.row = SgPointUtil::Row(*it);
		stone.boardSize = [self size];
		if (goGame->Board().IsColor(*it, SG_BLACK)) {
			stone.player = kStonePlayerBlack;
			[stones addObject:stone];
		} else if (goGame->Board().IsColor(*it, SG_WHITE)) {
			stone.player = kStonePlayerWhite;
			[stones addObject:stone];
		}
		[stone release];
	}
	
	return stones;
}

- (bool)playStoneAtRow:(int)row column:(int)col {
	SgPoint p = SgPointUtil::Pt(col, row);
	NSLog(@"%d %d", row, col);
	NSLog(@"%@", [DGS sgfCoordsWithRow:row column:col boardSize:[self size]]);
	if (goGame->Board().IsLegal(p)) {
		goGame->AddMove(p, goGame->Board().ToPlay());
		goGame->GoInDirection(SgNode::NEXT);
		return YES;
	} else {
		return NO;
	}
	return NO;
}

- (void)dealloc {
	delete goBoard;
	delete goGame;
	[super dealloc];
}

@end
