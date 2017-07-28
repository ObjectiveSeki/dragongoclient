//
//  TextCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell

- (void)awakeFromNib {
	[super awakeFromNib];
    [self setupTextField];
}

- (void)setupTextField {
    [self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textField.delegate = self;

    _maxTextLength = -1;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

	if (selected) {
        self.textField.userInteractionEnabled = YES;
		[self.textField becomeFirstResponder];
	} else {
        self.textField.userInteractionEnabled = NO;
		[self.textField resignFirstResponder];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[[self textField] resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString {
    if (self.maxTextLength > -1 && (textField.text.length + replacementString.length) > self.maxTextLength) {
        return NO;
    }
    return YES;
}

- (IBAction)textFieldChanged:(id)sender {
	if (self.onChanged) {
		self.onChanged(self);
	}
}



@end
