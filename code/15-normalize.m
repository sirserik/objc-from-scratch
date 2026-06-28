#import <Foundation/Foundation.h>

/* Нормализация логина: убрать пробелы по краям, перевести в нижний
   регистр, снять ведущую '@' (если её ввели), отвергнуть пустое. */
NSString *normalizeUsername(NSString *raw) {
    NSCharacterSet *ws =
        [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *s = [raw stringByTrimmingCharactersInSet:ws];
    s = [s lowercaseString];
    if ([s hasPrefix:@"@"]) {
        s = [s substringFromIndex:1];
    }
    if ([s length] == 0) {
        return nil;
    }
    return s;
}

int main(void) {
    @autoreleasepool {
        NSArray<NSString *> *inputs = @[
            @"  @Ivan_KZ  ",
            @"SERIK",
            @"@Astana2026",
            @"     ",
        ];
        for (NSString *in in inputs) {
            NSString *out = normalizeUsername(in);
            if (out) {
                NSLog(@"'%@' -> '%@'", in, out);
            } else {
                NSLog(@"'%@' -> ОТКЛОНЁН (пусто)", in);
            }
        }
    }
    return 0;
}
