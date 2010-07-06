//
//  SelectCell.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/30/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "SelectCell.h"


@implementation SelectCell

@synthesize label;
@synthesize value;
@synthesize picker;
@synthesize options;
@synthesize selectedOptions;
@synthesize changedSelector;
@synthesize sizes;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	UITableView *tableView = (UITableView *)self.superview;
	
	int pickerViewHeight = 215;
	
	if (selected && !self.picker) {
		NSLog(@"selected %@", self.label.text);
		tableView.contentSize = CGSizeMake(tableView.frame.size.width, tableView.frame.size.height - pickerViewHeight);
		self.picker = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, 480.0 - pickerViewHeight, 320.0, pickerViewHeight)] autorelease];

		self.picker.showsSelectionIndicator = YES;
		[[[UIApplication sharedApplication] keyWindow] addSubview:self.picker];
		self.picker.dataSource = self;
		self.picker.delegate = self;
		for(int i = 0; i < [self.selectedOptions count]; i++) {
			int row = [[self.options objectAtIndex:i] indexOfObject:[self.selectedOptions objectAtIndex:i]];
			[self.picker selectRow:row inComponent:i animated:NO];
		}
		// move the cell to the middle
		// if we're below the picker
		float bottomOfCell = self.frame.origin.y + self.frame.size.height + 5;
		float topOfPicker = tableView.frame.size.height - pickerViewHeight;
		if (bottomOfCell > topOfPicker) {
			CGPoint contentOffset = tableView.contentOffset;
			contentOffset.y += bottomOfCell - topOfPicker;
			[tableView setContentOffset:contentOffset animated:YES];
		}
		[super setSelected:YES animated:animated];
	} else {
		NSLog(@"deselected %@", self.label.text);
		
		if (self.picker) {
			tableView.contentSize = CGSizeMake(tableView.frame.size.width, tableView.frame.size.height - pickerViewHeight);
			[self.picker removeFromSuperview];
			self.picker = nil;		
		}
		[super setSelected:NO animated:animated];
	}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	if (self.changedSelector) {
		[[UIApplication sharedApplication] sendAction:self.changedSelector to:nil from:self forEvent:nil];
	}
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	CGFloat size;
	if (self.sizes) {
		size = [[self.sizes objectAtIndex:component] floatValue];
	} else {
		size = self.picker.frame.size.width / [self.options count];
	}
	return size;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
	return 40.0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return [self.options count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] count];
}

- (NSString *)selectedValueInComponent:(NSInteger)component {
	return [[self.options objectAtIndex:component] objectAtIndex:[self.picker selectedRowInComponent:component]];
}


- (void)dealloc {
	self.label = nil;
	self.value = nil;
	[self.picker removeFromSuperview];
	self.picker = nil;
	self.sizes = nil;
	self.selectedOptions = nil;
    [super dealloc];
}


@end
