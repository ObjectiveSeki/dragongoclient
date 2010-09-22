//
//  TextCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TextCell : UITableViewCell <UITextFieldDelegate> {
	IBOutlet UILabel *label;
	IBOutlet UITextField *textField;
	SEL textEditedSelector;
}

@property(nonatomic, retain) IBOutlet UILabel *label;
@property(nonatomic, retain) IBOutlet UITextField *textField;
@property(nonatomic) SEL textEditedSelector;
@end
