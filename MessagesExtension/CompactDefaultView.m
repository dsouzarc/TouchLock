//
//  CompactDefaultView.m
//  TouchLock
//
//  Created by Ryan D'souza on 2/18/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "CompactDefaultView.h"

@implementation CompactDefaultView

- (IBAction)pressedTakePhotoButton:(id)sender
{
    [self.delegate pressedTakePhotoButton];
}

- (IBAction)pressedTakePhotoButtonIcon:(id)sender
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
