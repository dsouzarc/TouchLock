//
//  MessageAttachments.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/10/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Constants.h"

/**
 Represents the attributes of a Message Attachment
 Like the file locations of various media
 */

@interface MessageAttachments : NSObject

- (instancetype) init;
- (instancetype) initWithAttachmentName:(NSString*)attachmentName;

@property (strong, nonatomic) NSString *attachmentName;
@property (strong, nonatomic) NSString *pathToZippedAttachment;
@property (strong, nonatomic) NSString *pathToUnzippedAttachment;

@property (strong, nonatomic) NSString *pathToImagesFolder;
@property (strong, nonatomic) NSString *pathToVideosFolder;
@property (strong, nonatomic) NSString *pathToTextFilesFolder;

@property BOOL isOutgoing;

@end
