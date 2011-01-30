//
//  TextCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell
@synthesize label, textField, textEditedSelector, content, onChanged;


- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain reuseIdentifier:NSStringFromClass([self class])])) {
        [[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:self options:nil];
		[self.contentView addSubview:self.content];
		[self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
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
	
    // Configure the view for the selected state
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

- (IBAction)textFieldChanged:(id)sender {
	if (self.textEditedSelector) {
		[[UIApplication sharedApplication] sendAction:self.textEditedSelector to:nil from:self forEvent:nil];
	} else if (self.onChanged) {
		self.onChanged();
	}
}

- (void)dealloc {
	self.label = nil;
	self.textField = nil;
	self.content = nil;
	self.onChanged = nil;
    [super dealloc];
}


@end
