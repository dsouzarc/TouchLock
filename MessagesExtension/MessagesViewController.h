//
//  MessagesViewController.h
//  MessagesExtension
//
//  Created by Ryan D'souza on 2/18/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Messages/Messages.h>
#import <Photos/Photos.h>

#import "YMSPhotoPickerViewController.h"

#import "CompactDefaultView.h"
#import "ExpandedDefaultView.h"

@interface MessagesViewController : MSMessagesAppViewController<YMSPhotoPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end
