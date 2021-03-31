#import "AFTestCase.h"

SecTrustRef AFUTTrustChainForCertsInDirectory(NSString *directoryPath) {
    NSArray *certFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *certs  = [NSMutableArray arrayWithCapacity:[certFileNames count]];
    for (NSString *path in certFileNames) {
        NSData *certData = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:path]];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
        [certs addObject:(__bridge_transfer id)(cert)];
    }
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)(certs), policy, &trust);
    CFRelease(policy);
    
    return trust;
}

@implementation AFTestCase

- (void)setUp {
    [super setUp];
    self.networkTimeout = 20.0;
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark -

- (NSURL *)baseURL {
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    return [NSURL URLWithString:environment[@"HTTPBIN_BASE_URL"] ?: @"https://httpbin.org"];
}

- (NSURL *)pngURL {
    return [self.baseURL URLByAppendingPathComponent:@"image/png"];
}

- (NSURL *)jpegURL {
    return [self.baseURL URLByAppendingPathComponent:@"image/jpeg"];
}

- (NSURL *)delayURL {
    return [self.baseURL URLByAppendingPathComponent:@"delay/1"];
}

- (NSURL *)URLWithStatusCode:(NSInteger)statusCode {
    return [self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"status/%@", @(statusCode)]];
}

- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

// 在这里, 应该就是设置, 自己创建的期望的过期时间, 应该就是多久之后期望没能达成就算失败了.
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:self.networkTimeout handler:handler];
}

- (NSData *)archivedDataWithRootObject:(id)object {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSKeyedArchiver archivedDataWithRootObject:object];
#pragma clang diagnostic pop
}

- (id)unarchivedObjectOfClass:(Class)class fromData:(NSData *)data {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
}

@end
