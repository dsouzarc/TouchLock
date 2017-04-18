//
//  MessageAttachment.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/17/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Realm/Realm.h>


static NSString *IMAGE_IDENTIFIER = @"image";
static NSString *VIDEO_IDENTIFIER = @"video";
static NSString *PRIVATE_TEXTFILE_IDENTIFIER = @"privateTextFile";


/** Represents an attachment in a message. A message can have multiple MessageAttachment objects */
@interface MessageAttachment : RLMObject

+ (MessageAttachment*) generateMessageAttachmentForMessageID:(NSString*)messageID
                                             messageSendTime:(NSDate*)messageSendTime
                                           isOutgoingMessage:(BOOL)isOutgoingMessage
                                                    fileType:(NSString*)fileType
                                                fileLocation:(NSString*)fileLocation
                                               encryptionKey:(NSString*)encryptionKey;

/** Message ID associated with the message */
@property (strong, nonatomic) NSString *messageID;

/** Time the message was sent */
@property (strong, nonatomic) NSDate *messageSendTime;

/** YES if this device sent the message. NO if this message was received */
@property BOOL isOutgoingMessage;

/** IDENTIFIER type of the file - image, video, privateTextFile */
@property (strong, nonatomic) NSString *fileType;

/** The attachment's local location */
@property (strong, nonatomic) NSString *fileLocation;

/** An encryption key to decrypt the attachment */
@property (strong, nonatomic) NSString *encryptionKey;

@end
