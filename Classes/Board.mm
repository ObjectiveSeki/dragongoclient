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

- (Stone *)lastMove {
	Stone *lastMove = [[[Stone alloc] init] autorelease];
	SgNode *move = goGame->CurrentNode();
	lastMove.x = SgPointUtil::Col(move->NodeMove());
	lastMove.y = SgPointUtil::Row(move->NodeMove());
	if (move->NodePlayer() == SG_BLACK) {
		lastMove.player = kStonePlayerBlack;
	} else if (move->NodePlayer() == SG_WHITE) {
		lastMove.player = kStonePlayerWhite;
	}
	return lastMove;
}

- (NSArray *)stones {
	NSMutableArray *stones = [NSMutableArray array];
	
	for (GoBoard::Iterator it(goGame->Board()); it; ++it) {
		Stone *stone = [[Stone alloc] init];
		stone.x = SgPointUtil::Col(*it);
		stone.y = SgPointUtil::Row(*it);
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
	SgPoint p = SgPointUtil::Pt(row, col);
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
