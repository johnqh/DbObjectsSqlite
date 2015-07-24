//
//  DetailViewController.h
//  DbObjectDemo
//
//  Created by Qiang Huang on 6/2/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

