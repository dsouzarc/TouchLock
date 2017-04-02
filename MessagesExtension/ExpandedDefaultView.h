//
//  ExpandedDefaultView.h
//  TouchLock
//
//  Created by Ryan D'souza on 2/18/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DefaultViewProtocol.h"

@interface ExpandedDefaultView : UIView

@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (strong, nonatomic) IBOutlet UIButton *takePhotoButtonImage;

@property (strong, nonatomic) IBOutlet UIButton *choosePhotoButton;
@property (strong, nonatomic) IBOutlet UIButton *choosePhotoButtonImage;

@property (weak, nonatomic) id<DefaultViewProtocol> delegate;

@end
