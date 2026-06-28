#import <Foundation/Foundation.h>

/* Тонкая настройка того, как ObjC-имена выглядят в Swift.
   NS_SWIFT_NAME переименовывает класс/метод для Swift,
   NS_SWIFT_NOTHROW отменяет автоматический перевод error: -> throws. */

NS_ASSUME_NONNULL_BEGIN

@interface PaletteColor : NSObject

@property (nonatomic, readonly) double red;
@property (nonatomic, readonly) double green;
@property (nonatomic, readonly) double blue;

/* Фабричный метод. Без аннотации Swift увидел бы громоздкое
   PaletteColor.color(red:green:blue:). С NS_SWIFT_NAME(init(...))
   он становится обычным инициализатором: PaletteColor(red:green:blue:). */
+ (instancetype)colorWithRed:(double)red
                       green:(double)green
                        blue:(double)blue
    NS_SWIFT_NAME(init(red:green:blue:));

/* Длинное имя метода ужимаем для Swift до hexString(). */
- (NSString *)hexStringRepresentation NS_SWIFT_NAME(hexString());

@end


@interface ConfigLoader : NSObject

/* Метод с error: последним параметром.
   В Swift автоматически станет throwing: try loader.load(from: text). */
- (nullable NSDictionary<NSString *, NSString *> *)loadFromString:(NSString *)text
                                                            error:(NSError **)error
    NS_SWIFT_NAME(load(from:));

/* Тоже принимает error:, но возвращает BOOL как настоящий результат,
   а не как «успех/провал». NS_SWIFT_NOTHROW оставляет его обычным
   методом, возвращающим Bool, а не throwing. */
- (BOOL)isValidConfig:(NSString *)text error:(NSError **)error NS_SWIFT_NOTHROW;

@end

NS_ASSUME_NONNULL_END


static NSString *const ConfigErrorDomain = @"ConfigErrorDomain";


@implementation PaletteColor

+ (instancetype)colorWithRed:(double)red
                       green:(double)green
                        blue:(double)blue {
    PaletteColor *c = [[self alloc] init];
    if (c) {
        c->_red = red;
        c->_green = green;
        c->_blue = blue;
    }
    return c;
}

- (NSString *)hexStringRepresentation {
    int r = (int)(self.red * 255.0 + 0.5);
    int g = (int)(self.green * 255.0 + 0.5);
    int b = (int)(self.blue * 255.0 + 0.5);
    return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

@end


@implementation ConfigLoader

- (nullable NSDictionary<NSString *, NSString *> *)loadFromString:(NSString *)text
                                                            error:(NSError **)error {
    if (text.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:ConfigErrorDomain
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Пустая строка конфигурации"
            }];
        }
        return nil;
    }
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary dictionary];
    for (NSString *pair in [text componentsSeparatedByString:@";"]) {
        NSArray<NSString *> *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count == 2) {
            result[kv[0]] = kv[1];
        }
    }
    return [result copy];
}

- (BOOL)isValidConfig:(NSString *)text error:(NSError **)error {
    (void)error;   /* здесь error не используем — просто демонстрация сигнатуры */
    return [text containsString:@"="];
}

@end


int main(void) {
    @autoreleasepool {
        /* Фабричный метод (в Swift это был бы init(red:green:blue:)) */
        PaletteColor *lime = [PaletteColor colorWithRed:0.6 green:0.9 blue:0.2];
        NSLog(@"Цвет в hex: %@", [lime hexStringRepresentation]);

        ConfigLoader *loader = [[ConfigLoader alloc] init];

        /* Успешная загрузка */
        NSError *err = nil;
        NSDictionary<NSString *, NSString *> *cfg =
            [loader loadFromString:@"host=localhost;port=5432" error:&err];
        if (cfg) {
            NSLog(@"host = %@, port = %@", cfg[@"host"], cfg[@"port"]);
        }

        /* Ошибка загрузки */
        NSError *err2 = nil;
        NSDictionary<NSString *, NSString *> *bad =
            [loader loadFromString:@"" error:&err2];
        if (bad == nil) {
            NSLog(@"Ошибка: %@", err2.localizedDescription);
        }

        /* Метод с BOOL-результатом */
        BOOL ok = [loader isValidConfig:@"a=b" error:NULL];
        NSLog(@"Конфиг валиден: %@", ok ? @"да" : @"нет");
    }
    return 0;
}
