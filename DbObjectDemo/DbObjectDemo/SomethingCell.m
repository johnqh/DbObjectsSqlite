//
//  SomethingCell.m
//  DbObjectDemo
//
//  Created by Qiang Huang on 6/2/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import "SomethingCell.h"
#import "DbDateUtils.h"
#import "DbSomething.h"

@interface SomethingCell()

@property (nonatomic, readonly) DbSomething * something;

@end

@implementation SomethingCell

@synthesize textLabel;
@synthesize detailTextLabel;
@synthesize entry = _entry;

- (void)setEntry:(NSObject<InteractiveObject> *)entry
{
    if (_entry != entry)
    {
        if (_entry)
        {
            [_entry removeObserver:self forKeyPath:@"name"];
            [_entry removeObserver:self forKeyPath:@"name2"];
            [_entry removeObserver:self forKeyPath:@"selected"];
            [_entry removeObserver:self forKeyPath:@"update_time"];
        }
        _entry = entry;
        if (_entry)
        {
            [_entry addObserver:self forKeyPath:@"name" options:0 context:nil];
            [_entry addObserver:self forKeyPath:@"name2" options:0 context:nil];
            [_entry addObserver:self forKeyPath:@"selected" options:0 context:nil];
            [_entry addObserver:self forKeyPath:@"update_time" options:0 context:nil];
        }
        [self update];
    }
}

- (DbSomething *)something
{
    return (DbSomething *)_entry;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"name"])
    {
        [self updateName];
    }
    else if ([keyPath isEqualToString:@"name2"])
    {
        [self updateName2];
    }
    else if ([keyPath isEqualToString:@"selected"])
    {
        [self updateSelected];
    }
    else if ([keyPath isEqualToString:@"update_time"])
    {
        [self updateTime];
    }
}

- (void)update
{
    [self updateName];
    [self updateName2];
    [self updateSelected];
    [self updateTime];
    
    [self layoutIfNeeded];
}

- (void)updateName
{
    self.textLabel.text = self.something ? self.something.name : nil;
}

- (void)updateName2
{
    self.detailTextLabel.text = self.something ? self.something.name2 : nil;
}

- (void)updateSelected
{
    self.accessoryType = self.something.selected.boolValue ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)updateTime
{
//    self.detailTextLabel.text = _something ? [DbDateUtils toDateString:_something.update_time] : nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.entry = nil;
}

- (void)dealloc
{
    self.entry = nil;
}

@end
