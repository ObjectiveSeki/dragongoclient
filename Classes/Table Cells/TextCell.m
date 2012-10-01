//
//  TextCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell
@synthesize label = _label, textField = _textField, textEditedSelector = _textEditedSelector, content = _content, onChanged = _onChanged, maxTextLength = _maxTextLength;

- (id)init {
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])])) {
        [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
		[self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
        _maxTextLength = -1;
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
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
	if (self.textEditedSelector) {
		[[UIApplication sharedApplication] sendAction:self.textEditedSelector to:nil from:self forEvent:nil];
	} else if (self.onChanged) {
		self.onChanged(self);
	}
}



@end
