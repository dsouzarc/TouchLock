//
//  ExpandedDefaultView.m
//  TouchLock
//
//  Created by Ryan D'souza on 2/18/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "ExpandedDefaultView.h"

@implementation ExpandedDefaultView

- (IBAction)pressedTakePhotoButtonIcon:(id)sender
{
    [self.delegate pressedTakePhotoButton];
}

- (IBAction)pressedTakePhotoButton:(id)sender
{
    [self.delegate pressedTakePhotoButton];
}

- (IBAction)pressedChoosePhotoButton:(id)sender
{
    [self.delegate pressedChoosePhotoButton];
}

- (IBAction)pressedChoosePhotoButtonIcon:(id)sender
{
    [self.delegate pressedChoosePhotoButton];
}

- (IBAction)pressedSendTextButton:(id)sender
{
    [self.delegate pressedSendTextButton];
}

- (IBAction)pressedSendTextButtonIcon:(id)sender
{
    [self.delegate pressedSendTextButton];
}

@end
