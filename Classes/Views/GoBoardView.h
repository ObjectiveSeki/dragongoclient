//
//  GoBoardView.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FuegoBoard.h"

@interface GoBoardView : UIView {
	FuegoBoard *board;
	IBOutlet id delegate;
	IBOutlet UILabel *blackName;
	IBOutlet UILabel *whiteName;
	IBOutlet UIView  *statusView;
	IBOutlet UILabel *status;
	IBOutlet UILabel *blackCaptures;
	IBOutlet UILabel *whiteCaptures;
	int pointDistance;
	int _marginX;
    int _marginY;
}

@property(nonatomic, strong) FuegoBoard *board;
@property(nonatomic, strong) IBOutlet id delegate;

@property(nonatomic, strong) IBOutlet UILabel *blackName;
@property(nonatomic, strong) IBOutlet UILabel *whiteName;
@property(nonatomic, strong) IBOutlet UILabel *status;
@property(nonatomic, strong) IBOutlet UIView *statusView;
@property(nonatomic, strong) IBOutlet UILabel *blackCaptures;
@property(nonatomic, strong) IBOutlet UILabel *whiteCaptures;
@property(nonatomic, readonly) int pointDistance;

- (bool)playStoneAtPoint:(CGPoint)point;
- (bool)markDeadStonesAtPoint:(CGPoint)point;

@end
