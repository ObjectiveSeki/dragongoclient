//
//  TextCell.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TextCell : UITableViewCell {
	IBOutlet UILabel *label;
	IBOutlet UITextField *textField;
}

@property(nonatomic, retain) IBOutlet UILabel *label;
@property(nonatomic, retain) IBOutlet UITextField *textField;

@end
