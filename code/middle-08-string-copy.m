#import <Foundation/Foundation.h>

/* Задача: copy-семантика NSString-свойства. Если свойство объявлено
   strong, а присвоить ему NSMutableString — объект сохранит ССЫЛКУ на
   мутабельную строку, и она поменяется «за спиной». copy снимает
   неизменяемый снимок. */

@interface Profile : NSObject
@property (nonatomic, strong) NSString *strongName;  /* опасно */
@property (nonatomic, copy)   NSString *safeName;    /* правильно */
@end

@implementation Profile
@end

int main(void) {
    @autoreleasepool {
        NSMutableString *src = [NSMutableString stringWithString:@"Айгуль"];

        Profile *p = [[Profile alloc] init];
        p.strongName = src;   /* strong сохранил ссылку на src */
        p.safeName   = src;   /* copy снял снимок «Айгуль» */

        NSLog(@"до мутации:");
        NSLog(@"  strongName = %@", p.strongName);   /* Айгуль */
        NSLog(@"  safeName   = %@", p.safeName);      /* Айгуль */

        /* меняем исходную строку «за спиной» объекта */
        [src appendString:@" Сергеевна"];

        NSLog(@"после мутации src:");
        NSLog(@"  strongName = %@", p.strongName);   /* Айгуль Сергеевна! */
        NSLog(@"  safeName   = %@", p.safeName);      /* Айгуль (снимок) */
    }
    return 0;
}
