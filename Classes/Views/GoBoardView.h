//
//  GoBoardView.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Avvo. All rights reserved.
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
	int _margin;
}

@property(nonatomic, retain) FuegoBoard *board;
@property(nonatomic, retain) IBOutlet id delegate;

@property(nonatomic, retain) IBOutlet UILabel *blackName;
@property(nonatomic, retain) IBOutlet UILabel *whiteName;
@property(nonatomic, retain) IBOutlet UILabel *status;
@property(nonatomic, retain) IBOutlet UIView *statusView;
@property(nonatomic, retain) IBOutlet UILabel *blackCaptures;
@property(nonatomic, retain) IBOutlet UILabel *whiteCaptures;
@property(nonatomic, readonly) int pointDistance;

- (bool)playStoneAtPoint:(CGPoint)point;
- (bool)markDeadStonesAtPoint:(CGPoint)point;

@end
