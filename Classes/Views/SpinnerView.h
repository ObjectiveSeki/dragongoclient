//
//  SpinnerView.h
//  DGSPhone
//
//  Created by Justin Weiss on 7/23/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SpinnerView : UIView {
	UIActivityIndicatorView *spinner;
	UILabel *label;
}

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *label;

+ (SpinnerView *)showInView:(UIView *)view;
- (void)dismiss:(BOOL)animate;

@end

