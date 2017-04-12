//
//  PrivateTextViewController.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/11/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIFloatLabelTextView.h"

@protocol PrivateTextViewControllerDelegate <NSObject>

- (void) privateTextViewController:(id)privateTextViewController
   exitedEditorWithMessageTextData:(NSData*)messageTextData;

- (void) privateTextViewController:(id)privateTextViewController
                           didExit:(BOOL)didExit;

@end


@interface PrivateTextViewController : UIViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil
                          bundle:(NSBundle *)nibBundleOrNil
                      isOutgoing:(BOOL)isOutgoing
                 messageTextData:(NSData*)messageTextData;

@property (weak, nonatomic) id<PrivateTextViewControllerDelegate> delegate;

@end
