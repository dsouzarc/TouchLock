//
//  MessagesViewController.h
//  MessagesExtension
//
//  Created by Ryan D'souza on 2/18/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Messages/Messages.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

#import "QBImagePickerController.h"

#import "CompactDefaultView.h"
#import "ExpandedDefaultView.h"

#import "DefaultViewProtocol.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SSZipArchive.h"

@interface MessagesViewController : MSMessagesAppViewController<QBImagePickerControllerDelegate, DefaultViewProtocol, UINavigationControllerDelegate>

@end
