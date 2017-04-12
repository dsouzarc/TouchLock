//
//  MessageParameters.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/11/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represents the parameters that get sent with each Messge
*/

@interface MessageParameters : NSObject

- (instancetype) initWithNSURLComponents:(NSURLComponents*)urlComponents;
- (instancetype) initWithEncryptionKey:(NSString*)encryptionKey
                        attachmentName:(NSString*)attachmentName
                             messageID:(NSString*)messageID
                         numberOfItems:(int)numberOfItems;

- (NSURLComponents*) generateURLComponents;

@property (strong, nonatomic) NSString *encryptionKey;
@property (strong, nonatomic) NSString *attachmentName;
@property (strong, nonatomic) NSString *messageID;

@property int numberOfItems;

@end
