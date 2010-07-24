//
//  SpinnerView.h
//  DGSPhone
//
//  Created by Justin Weiss on 7/23/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SpinnerView : UIView {
	UIActivityIndicatorView *spinner;
	UILabel *label;
}

@property (nonatomic, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, retain) UILabel *label;

+ (SpinnerView *)showInView:(UIView *)view;
- (void)dismiss;

@end

