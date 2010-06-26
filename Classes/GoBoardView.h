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
	IBOutlet id delegate;
	IBOutlet UILabel *blackName;
	IBOutlet UILabel *whiteName;
	IBOutlet UILabel *blackStatus;
	IBOutlet UILabel *whiteStatus;
	
}

@property(nonatomic, retain) Board *board;
@property(nonatomic, retain) IBOutlet id delegate;

@property(nonatomic, retain) IBOutlet UILabel *blackName;
@property(nonatomic, retain) IBOutlet UILabel *whiteName;
@property(nonatomic, retain) IBOutlet UILabel *blackStatus;
@property(nonatomic, retain) IBOutlet UILabel *whiteStatus;

- (bool)playStoneAtPoint:(CGPoint)point;

@end
