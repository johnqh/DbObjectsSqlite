//
//  MasterViewController.m
//  DbObjectDemo
//
//  Created by Qiang Huang on 6/2/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "SomethingCell.h"

#import "DbSomething.h"
#import "DbCollection.h"
#import "DbDatabases.h"

#import "UIAlertView+Text.h"

@interface MasterViewController ()
{
    DbCollection * _somethingsByName;
    DbCollection * _somethingsByName2;
    DbCollection * _somethingsBySelect;
}

@property (nonatomic, strong) DbCollection * somethingsByName;
@property (nonatomic, strong) DbCollection * somethingsByName2;
@property (nonatomic, strong) DbCollection * somethingsBySelect;
@end

@implementation MasterViewController

- (DbCollection *)somethingsByName
{
    return _somethingsByName;
}

- (void)setSomethingsByName:(DbCollection *)somethingsByName
{
    if (_somethingsByName != somethingsByName)
    {
        if (_somethingsByName)
        {
            [_somethingsByName removeObserver:self forKeyPath:@"entries"];
        }
        _somethingsByName = somethingsByName;
        if (_somethingsByName)
        {
            [_somethingsByName addObserver:self forKeyPath:@"entries" options:0 context:nil];
        }
        [self.tableView reloadData];
    }
}

- (DbCollection *)somethingsByName2
{
    return _somethingsByName2;
}

- (void)setSomethingsByName2:(DbCollection *)somethingsByName2
{
    if (_somethingsByName2 != somethingsByName2)
    {
        if (_somethingsByName2)
        {
            [_somethingsByName2 removeObserver:self forKeyPath:@"entries"];
        }
        _somethingsByName2 = somethingsByName2;
        if (_somethingsByName2)
        {
            [_somethingsByName2 addObserver:self forKeyPath:@"entries" options:0 context:nil];
        }
        [self.tableView reloadData];
    }
}

- (DbCollection *)somethingsBySelect
{
    return _somethingsBySelect;
}

- (void)setSomethingsBySelect:(DbCollection *)somethingsBySelect
{
    if (_somethingsBySelect != somethingsBySelect)
    {
        if (_somethingsBySelect)
        {
            [_somethingsBySelect removeObserver:self forKeyPath:@"entries"];
        }
        _somethingsBySelect = somethingsBySelect;
        if (_somethingsBySelect)
        {
            [_somethingsBySelect addObserver:self forKeyPath:@"entries" options:0 context:nil];
        }
        [self.tableView reloadData];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"entries"])
    {
        NSInteger section = 0;
        if (object == _somethingsByName)
        {
            section = 0;
        }
        else if (object == _somethingsByName2)
        {
            section = 1;
        }
        else if (object == _somethingsBySelect)
        {
            section = 2;
        }
        if ([change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeInsertion)
        {
            NSIndexSet * indice = change[NSKeyValueChangeIndexesKey];
            if (indice && indice.count)
            {
                NSMutableArray * indexPaths = [NSMutableArray array];
                [indice enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
                }];
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                
            }
            
        }
        else if ([change[NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeRemoval)
        {
            NSIndexSet * indice = change[NSKeyValueChangeIndexesKey];
            if (indice && indice.count)
            {
                NSMutableArray * indexPaths = [NSMutableArray array];
                [indice enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
                }];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
        }
        
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    {
        DbSomething * example = [[DbSomething alloc] initWithDb:[DbDatabases singleton]];
        DbCollection * somethings = [DbCollection collectionWithExample:example];
        [somethings addSorting:[DbSortDescriptor sortOnKey:@"name" ascending:true]];
        [somethings loadFromDb];
        self.somethingsByName = somethings;
    }
    {
        DbSomething * example = [[DbSomething alloc] initWithDb:[DbDatabases singleton]];
        DbCollection * somethings = [DbCollection collectionWithExample:example];
        [somethings addSorting:[DbSortDescriptor sortOnKey:@"name2" ascending:true]];
        [somethings loadFromDb];
        self.somethingsByName2 = somethings;
    }
    {
        DbSomething * example = [[DbSomething alloc] initWithDb:[DbDatabases singleton]];
        example.selected = @true;
        DbCollection * somethings = [DbCollection collectionWithExample:example];
        [somethings addSorting:[DbSortDescriptor sortOnKey:@"name" ascending:true]];
        [somethings loadFromDb];
        self.somethingsBySelect = somethings;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    DbSomething * something = [[DbSomething alloc] initWithDb:_somethingsByName.db];
    something.name = [NSUUID UUID].UUIDString;
    something.name2 = [NSUUID UUID].UUIDString;
    something.selected = @false;
    something.update_time = [NSDate date];
    [something saveToDb];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section)
    {
        case 0:
            return _somethingsByName.count;
            
        case 1:
            return _somethingsByName2.count;
            
        case 2:
            return _somethingsBySelect.count;
            
        default:
            return 0;
    }
}

- (DbCollection *)somethings:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return _somethingsByName;
            
        case 1:
            return _somethingsByName2;
            
        case 2:
            return _somethingsBySelect;
            
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SomethingCell * cell = [tableView dequeueReusableCellWithIdentifier:@"something" forIndexPath:indexPath];

    DbSomething * something = (DbSomething *)[[self somethings:indexPath.section] objectAtIndex:indexPath.row];
    cell.entry = something;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    DbSomething * something = (DbSomething *)[[self somethings:indexPath.section] objectAtIndex:indexPath.row];
    something.selected = [NSNumber numberWithBool:!something.selected.boolValue];
    [something saveToDb];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // you need to implement this method too or nothing will work:
    
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES; //tableview must be editable or nothing will work...
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Name";
            
        case 1:
            return @"Name 2";
            
        case 2:
            return @"Selected";
            
        default:
            return nil;
    }
}

@end
