//
//  TextCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "TextCell.h"


@implementation TextCell
@synthesize label, textField, textEditedSelector;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[[self textField] resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (self.textEditedSelector) {
		[[UIApplication sharedApplication] sendAction:self.textEditedSelector to:nil from:self forEvent:nil];
	}
	return YES;
}

- (void)dealloc {
	self.label = nil;
	self.textField = nil;
    [super dealloc];
}


@end
