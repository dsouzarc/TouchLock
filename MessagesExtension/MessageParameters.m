//
//  MessageParameters.m
//  TouchLock
//
//  Created by Ryan D'souza on 4/11/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "MessageParameters.h"

@implementation MessageParameters

- (instancetype) initWithEncryptionKey:(NSString *)encryptionKey
                        attachmentName:(NSString *)attachmentName
                             messageID:(NSString *)messageID
                         numberOfItems:(int)numberOfItems
{
    self = [super init];
    
    if(self) {
        self.encryptionKey = encryptionKey;
        self.attachmentName = attachmentName;
        self.messageID = messageID;
        self.numberOfItems = numberOfItems;
    }
    
    return self;
}

- (instancetype) initWithNSURLComponents:(NSURLComponents *)urlComponents
{
    NSString *encryptionKey = @"";
    NSString *fileName = @"";
    NSString *messageID = @"";
    int numberOfAttachments = 0;
    
    for(NSURLQueryItem *queryItem in [urlComponents queryItems]) {
        if([[queryItem name] isEqualToString:@"encryption_key"]) {
            encryptionKey = [queryItem value];
        }
        
        else if([[queryItem name] isEqualToString:@"send_name"]) {
            fileName = [queryItem value];
        }
        
        else if([[queryItem name] isEqualToString:@"message_id"]) {
            messageID = [queryItem value];
        }
        
        else if([[queryItem name] isEqualToString:@"num_attachments"]) {
            numberOfAttachments = [[queryItem value] intValue];
        }
    }
    
    return [self initWithEncryptionKey:encryptionKey
                        attachmentName:fileName
                             messageID:messageID
                         numberOfItems:numberOfAttachments];
}

- (NSURLComponents*) generateURLComponents
{
    
    NSURLQueryItem *encryptionItem = [[NSURLQueryItem alloc] initWithName:@"encryption_key" value:self.encryptionKey];
    NSURLQueryItem *sendNameItem = [[NSURLQueryItem alloc] initWithName:@"send_name" value:self.attachmentName];
    NSURLQueryItem *messageIDItem = [[NSURLQueryItem alloc] initWithName:@"message_id" value:self.messageID];
    NSURLQueryItem *numberOfItems = [[NSURLQueryItem alloc] initWithName:@"num_attachments" value:[NSString stringWithFormat:@"%d", self.numberOfItems]];
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    [urlComponents setQueryItems:@[encryptionItem, sendNameItem, messageIDItem, numberOfItems]];
    
    return urlComponents;
}

@end
