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
                                      attachmentDataFileType:(NSString *)attachmentDataFileType
                                              attachmentData:(NSData *)attachmentData

{
    MessageAttachment *attachment = [[MessageAttachment alloc] init];
    
    attachment.messageID = messageID;
    attachment.messageSendTime = messageSendTime;
    attachment.isOutgoingMessage = isOutgoingMessage;
    attachment.attachmentDataFileType = attachmentDataFileType;
    attachment.attachmentData = attachmentData;
    
    return attachment;
}

@end
