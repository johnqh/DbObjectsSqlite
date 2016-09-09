//
//  DemoInteractor.m
//  DbObjectDemo
//
//  Created by Qiang Huang on 9/4/16.
//  Copyright © 2016 John Huang. All rights reserved.
//

#import "DemoInteractor.h"

#import "DbDatabases.h"
#import "DbCollection.h"

#import "DbSomething.h"

@interface DemoInteractor ()

@property (nonatomic, strong) DbCollection * somethingsByName;
@property (nonatomic, strong) DbCollection * somethingsByName2;
@property (nonatomic, strong) DbCollection * somethingsBySelect;

@end

@implementation DemoInteractor

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
    }
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
    }
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
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == _somethingsByName ||
         object == _somethingsByName2 ||
         object == _somethingsBySelect)
        && [keyPath isEqualToString:@"entries"])
    {
        [self refresh];
    }
}

- (NSMutableArray *)entries
{
    if (![super entries])
    {
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
        [super setEntries:self.visible];

    }
    return [super entries];
}

- (instancetype)init
{
    if (self = [super init])
    {

        return self;
    }
    return self;
}

- (NSMutableArray *)visible
{
    NSMutableArray * visible = [NSMutableArray array];
    if (self.somethingsByName.count)
    {
        [visible addObject:self.somethingsByName];
    }
    if (self.somethingsByName2.count)
    {
        [visible addObject:self.somethingsByName2];
    }
    if (self.somethingsBySelect.count)
    {
        [visible addObject:self.somethingsBySelect];
    }
    return visible;
}

- (void)refresh
{
    [self sync:self.visible];
}

@end
