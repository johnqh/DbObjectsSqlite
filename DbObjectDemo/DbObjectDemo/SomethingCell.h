//
//  SomethingCell.h
//  DbObjectDemo
//
//  Created by Qiang Huang on 6/2/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DbSomething;

@interface SomethingCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel * textLabel;
@property (nonatomic, strong) IBOutlet UILabel * detailTextLabel;

@property (nonatomic, strong) DbSomething * something;

@end
