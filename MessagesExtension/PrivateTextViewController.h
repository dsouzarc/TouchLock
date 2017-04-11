//
//  PrivateTextViewController.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/11/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIFloatLabelTextView.h"

#import "MessageAttachments.h"


@interface PrivateTextViewController : UIViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil messageAttachment:(MessageAttachments*)messageAttachment isOutgoing:(BOOL)isOutgoing;


@end
