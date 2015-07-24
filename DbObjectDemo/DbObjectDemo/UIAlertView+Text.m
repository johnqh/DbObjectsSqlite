//
//  UIAlertView+Text.m
//  UIUtils
//
//  Created by Qiang Huang on 2/16/15.
//  Copyright (c) 2015 Sudobility. All rights reserved.
//

#import "UIAlertView+Text.h"

@implementation UIAlertView (Text)

+ (instancetype)showWithPrompt:(NSString *)prompt default:(NSString *)defaultText keyboardType:(UIKeyboardType)keyboardType autocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType textOkBlock:(UIAlertViewTextEntryBlock)textOkBlock
{
    UIAlertView * textAlert = [[self alloc] initWithTitle:prompt message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [textAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField * alertTextField = [textAlert textFieldAtIndex:0];
    alertTextField.keyboardType = keyboardType;
    alertTextField.autocapitalizationType = autocapitalizationType;
    alertTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    alertTextField.text = defaultText;
    
    if (textOkBlock)
    {
        textAlert.tapBlock = ^(UIAlertView * alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) // OK
            {
                NSString * text = [alertView textFieldAtIndex:0].text;
                textOkBlock(alertView, text);
            }
        };
    }
    
    [textAlert show];
    return textAlert;
}
@end
