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
{
    DbSomething * _something;
}

@end

@implementation SomethingCell

@synthesize textLabel;
@synthesize detailTextLabel;

- (DbSomething *)something
{
    return _something;
}

- (void)setSomething:(DbSomething *)something
{
    if (_something != something)
    {
        if (_something)
        {
            [_something removeObserver:self forKeyPath:@"name"];
            [_something removeObserver:self forKeyPath:@"name2"];
            [_something removeObserver:self forKeyPath:@"selected"];
            [_something removeObserver:self forKeyPath:@"update_time"];
        }
        _something = something;
        if (_something)
        {
            [_something addObserver:self forKeyPath:@"name" options:0 context:nil];
            [_something addObserver:self forKeyPath:@"name2" options:0 context:nil];
            [_something addObserver:self forKeyPath:@"selected" options:0 context:nil];
            [_something addObserver:self forKeyPath:@"update_time" options:0 context:nil];
        }
        [self update];
    }
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
    self.textLabel.text = _something ? _something.name : nil;
}

- (void)updateName2
{
    self.detailTextLabel.text = _something ? _something.name2 : nil;
}

- (void)updateSelected
{
    self.accessoryType = _something.selected.boolValue ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)updateTime
{
//    self.detailTextLabel.text = _something ? [DbDateUtils toDateString:_something.update_time] : nil;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.something = nil;
}

- (void)dealloc
{
    self.something = nil;
}

@end
