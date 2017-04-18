//
//  MessageAttachment.m
//  TouchLock
//
//  Created by Ryan D'souza on 4/17/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "MessageAttachment.h"

@implementation MessageAttachment

+ (MessageAttachment*) generateMessageAttachmentForMessageID:(NSString *)messageID
                                             messageSendTime:(NSDate *)messageSendTime
                                           isOutgoingMessage:(BOOL)isOutgoingMessage
                                                    fileType:(NSString *)fileType
                                                fileLocation:(NSString *)fileLocation
                                               encryptionKey:(NSString *)encryptionKey

{
    MessageAttachment *attachment = [[MessageAttachment alloc] init];
    
    attachment.messageID = messageID;
    attachment.messageSendTime = messageSendTime;
    attachment.isOutgoingMessage = isOutgoingMessage;
    attachment.fileType = fileType;
    attachment.fileLocation = fileLocation;
    attachment.encryptionKey = encryptionKey;
    
    return attachment;
}

@end
