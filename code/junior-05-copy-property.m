#import <Foundation/Foundation.h>

/* strong хранит ту же ссылку, что ему дали. Если дали NSMutableString и
   потом её изменили — изменится и то, что «видит» свойство.
   copy делает снимок при присваивании: исходную потом хоть как меняй. */
@interface Profile : NSObject
@property (nonatomic, strong) NSString *strongName;
@property (nonatomic, copy)   NSString *copiedName;
@end

@implementation Profile
@end

int main(void) {
    @autoreleasepool {
        NSMutableString *m = [NSMutableString stringWithString:@"Анна"];

        Profile *p = [[Profile alloc] init];
        p.strongName = m;   /* сохранили саму изменяемую строку */
        p.copiedName = m;   /* сохранили НЕизменяемый снимок     */

        [m appendString:@" Каренина"];   /* меняем исходную строку */

        NSLog(@"strong: %@", p.strongName);   /* изменилось вместе с m */
        NSLog(@"copy:   %@", p.copiedName);   /* остался снимок «Анна» */
    }
    return 0;
}
