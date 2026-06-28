#import <Foundation/Foundation.h>

/* Два свойства-строки с разными атрибутами хранения.
   strongName держит ту же строку, что ей дали.
   safeName при установке делает собственную копию. */
@interface Label : NSObject
@property (nonatomic, strong) NSString *strongName;
@property (nonatomic, copy)   NSString *safeName;
@end

@implementation Label
@end

int main(void) {
    @autoreleasepool {
        Label *label = [[Label alloc] init];

        /* NSMutableString — строка, которую МОЖНО менять после создания. */
        NSMutableString *text = [NSMutableString stringWithString:@"Привет"];

        /* Кладём одну и ту же изменяемую строку в оба свойства. */
        label.strongName = text;
        label.safeName   = text;

        NSLog(@"до правки:");
        NSLog(@"  strongName = %@", label.strongName);
        NSLog(@"  safeName   = %@", label.safeName);

        /* Теперь портим исходную строку у себя за спиной. */
        [text appendString:@", мир!"];

        NSLog(@"после правки исходной строки:");
        NSLog(@"  strongName = %@", label.strongName);   /* изменилось! */
        NSLog(@"  safeName   = %@", label.safeName);      /* осталось прежним */
    }
    return 0;
}
