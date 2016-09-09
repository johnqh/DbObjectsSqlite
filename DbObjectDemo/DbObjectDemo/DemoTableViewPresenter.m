//
//  DemoTableViewPresenter.m
//  DbObjectDemo
//
//  Created by Qiang Huang on 9/8/16.
//  Copyright © 2016 John Huang. All rights reserved.
//

#import "DemoTableViewPresenter.h"

#import "DbSomething.h"
#import "UIAlertView+Text.h"

@implementation DemoTableViewPresenter

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DbSomething * something = (DbSomething *)[self entryAtIndexPath:indexPath];

    UITableViewRowAction * name1Button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Change\nName1" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [UIAlertView showWithPrompt:@"Change Name1" default:something.name keyboardType:UIKeyboardTypeDefault autocapitalizationType:UITextAutocapitalizationTypeWords textOkBlock:^(UIAlertView *alertView, NSString *text) {
            something.name = text;
            [something saveToDb];
        }];
    }];
    name1Button.backgroundColor = [UIColor grayColor]; //arbitrary color

    UITableViewRowAction * name2Button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Change\nName2" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [UIAlertView showWithPrompt:@"Change Name2" default:something.name2 keyboardType:UIKeyboardTypeDefault autocapitalizationType:UITextAutocapitalizationTypeWords textOkBlock:^(UIAlertView *alertView, NSString *text) {
            something.name2 = text;
            [something saveToDb];
        }];
    }];
    name2Button.backgroundColor = [UIColor grayColor]; //arbitrary color

    UITableViewRowAction * deleteButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [something removeFromDb];
    }];
    deleteButton.backgroundColor = [UIColor redColor]; //arbitrary color

    return @[deleteButton, name2Button, name1Button]; //array with all the buttons you want. 1,2,3, etc...
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    DbSomething * something = (DbSomething *)[self entryAtIndexPath:indexPath];
    something.selected = [NSNumber numberWithBool:!something.selected.boolValue];
    [something saveToDb];
}

@end
