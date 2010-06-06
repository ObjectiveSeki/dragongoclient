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
	int x;
	int y;
	StonePlayer player;
};

@property(nonatomic) int x;
@property(nonatomic) int y;
@property(nonatomic) StonePlayer player;

@end
