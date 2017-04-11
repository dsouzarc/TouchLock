//
//  PrivateTextViewController.m
//  TouchLock
//
//  Created by Ryan D'souza on 4/11/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "PrivateTextViewController.h"

@interface PrivateTextViewController ()

@property (strong, nonatomic) MessageAttachments *messageAttachment;

@property BOOL isOutgoing;

@end

@implementation PrivateTextViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil messageAttachment:(MessageAttachments *)messageAttachment isOutgoing:(BOOL)isOutgoing
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageAttachment = messageAttachment;
        self.isOutgoing = isOutgoing;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self.view.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor] setActive:YES];
     
}


@end
