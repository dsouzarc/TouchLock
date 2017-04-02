//
//  DefaultViewProtocol.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/2/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DefaultViewProtocol <NSObject>

- (void) pressedTakePhotoButton;
- (void) pressedChoosePhotoButton;
- (void) pressedSendTextButton;

@end
