//
//  TableCellFactory.m
//  BACEstimator
//
//  Created by Justin Weiss on 7/18/08.
//  Copyright 2008 Avvo. All rights reserved.
//

#import "TableCellFactory.h"

@implementation TableCellFactory

- (TextCell *) newTextCell{
    [[NSBundle mainBundle] loadNibNamed:@"TableCells" owner:self options:nil];
    return textCell;
}

+ (TextCell *) textCell
{
    TableCellFactory *tcf = [[TableCellFactory alloc] init];
    TextCell *textCell = [tcf newTextCell];
    [tcf release];
    return textCell;
}

- (SelectCell *) newSelectCell{
    [[NSBundle mainBundle] loadNibNamed:@"TableCells" owner:self options:nil];
    return selectCell;
}

+ (SelectCell *) selectCell
{
    TableCellFactory *tcf = [[TableCellFactory alloc] init];
    SelectCell *selectCell = [tcf newSelectCell];
    [tcf release];
    return selectCell;
}


- (void)dealloc {
    [textCell release];
	[selectCell release];
    [super dealloc];
}


@end
