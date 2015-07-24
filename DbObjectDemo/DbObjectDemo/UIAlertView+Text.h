//
//  UIAlertView+Text.h
//  UIUtils
//
//  Created by Qiang Huang on 2/16/15.
//  Copyright (c) 2015 Sudobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIAlertView+Blocks.h"

typedef void (^UIAlertViewTextEntryBlock) (UIAlertView *alertView, NSString * text);

@interface UIAlertView (Text)

+ (instancetype)showWithPrompt:(NSString *)prompt default:(NSString *)defaultText keyboardType:(UIKeyboardType)keyboardType autocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType textOkBlock:(UIAlertViewTextEntryBlock)textOkBlock;

@end
