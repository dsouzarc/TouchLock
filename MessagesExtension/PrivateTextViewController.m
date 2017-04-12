//
//  PrivateTextViewController.m
//  TouchLock
//
//  Created by Ryan D'souza on 4/11/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "PrivateTextViewController.h"

@interface PrivateTextViewController ()
@property (strong, nonatomic) IBOutlet UINavigationItem *titleNavigationItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (strong, nonatomic) IBOutlet UIFloatLabelTextView *privateMessageTextView;

@property (strong, nonatomic) NSData *messageTextData;
@property BOOL isOutgoing;

@end


@implementation PrivateTextViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil
                          bundle:(NSBundle *)nibBundleOrNil
                      isOutgoing:(BOOL)isOutgoing
                 messageTextData:(NSData *)messageTextData
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.isOutgoing = isOutgoing;
        self.messageTextData = messageTextData;
    }
    
    return self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if(![touch.view isKindOfClass:[UITextView class]]) {
        [touch.view endEditing:YES];
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if(!self.isOutgoing) {
        
        [self.sendButton setEnabled:NO];
        [self.cancelButton setTitle:@"Done"];
        
        [self.titleNavigationItem setTitle:@"Received Message"];
        self.privateMessageTextView.placeholder = @"Received message";
        
        if(self.messageTextData && [self.messageTextData length] > 0) {
            NSAttributedString *messageText = [NSKeyedUnarchiver unarchiveObjectWithData:self.messageTextData];
            [self.privateMessageTextView setAttributedText:messageText];
        }
        
        else {
            
            NSDictionary *italicsAttribute = @{NSFontAttributeName: [UIFont italicSystemFontOfSize:[UIFont systemFontSize]]};
            NSAttributedString *noTextFound = [[NSAttributedString alloc] initWithString:@"Received a blank or invalid textfile" attributes:italicsAttribute];
            
            [self.privateMessageTextView setAttributedText:noTextFound];
        }
        
        [self.privateMessageTextView setEditable:FALSE];
        [self.privateMessageTextView setSelectEnabled:[NSNumber numberWithBool:YES]];
        [self.privateMessageTextView setCopyingEnabled:[NSNumber numberWithBool:YES]];
    }
    
    else {
        
        [self.titleNavigationItem setTitle:@"Send Message"];
        self.privateMessageTextView.placeholder = @"Text to send";
        
        if(self.messageTextData && [self.messageTextData length] > 0) {
            NSAttributedString *messageText = [NSKeyedUnarchiver unarchiveObjectWithData:self.messageTextData];
            [self.privateMessageTextView setAttributedText:messageText];
        }
        
        else {
            [self.privateMessageTextView setText:@" "];
        }
    }
}

- (IBAction) pressedCancelButton:(id)sender
{
    if(self.isOutgoing) {
        [self.delegate privateTextViewController:self didExit:YES];
        /*NSAttributedString *privateText = [self.privateMessageTextView attributedText];
        NSData *privateTextData = [NSKeyedArchiver archivedDataWithRootObject:privateText];
        
        [self.delegate privateTextViewController:self exitedEditorWithMessageTextData:privateTextData];*/
    }
    
    else {
        [self.delegate privateTextViewController:self didExit:YES];
    }
}

- (IBAction) pressedSendButton:(id)sender
{
    NSAttributedString *privateText = [self.privateMessageTextView attributedText];
    NSData *privateTextData = [NSKeyedArchiver archivedDataWithRootObject:privateText];
    
    [self.delegate privateTextViewController:self exitedEditorWithMessageTextData:privateTextData];
}

@end
