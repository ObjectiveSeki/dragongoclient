//
//  GoBoardView.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Board.h"

@interface GoBoardView : UIView {
	Board *board;
}

@property(nonatomic, retain) Board *board;

@end
