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
	int _marginX;
    int _marginY;
}

@property(nonatomic, strong) FuegoBoard *board;

@property(nonatomic, strong) IBOutlet UILabel *blackName;
@property(nonatomic, strong) IBOutlet UILabel *whiteName;
@property(nonatomic, strong) IBOutlet UILabel *status;
@property(nonatomic, strong) IBOutlet UIView *statusView;
@property(nonatomic, strong) IBOutlet UILabel *blackCaptures;
@property(nonatomic, strong) IBOutlet UILabel *whiteCaptures;

- (bool)playStoneAtPoint:(CGPoint)point;
- (bool)markDeadStonesAtPoint:(CGPoint)point;

@end
