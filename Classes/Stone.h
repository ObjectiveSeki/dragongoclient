//
//  Stone.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _StonePlayer {
	kStonePlayerBlack,
	kStonePlayerWhite
} StonePlayer;

@interface Stone : NSObject {
	int row;
	int col;
	StonePlayer player;
	int boardSize;
};

@property(nonatomic) int row;
@property(nonatomic) int col;
@property(nonatomic) StonePlayer player;
@property(nonatomic) int boardSize;

@end
