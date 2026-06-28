#import <Foundation/Foundation.h>

/* Задача: простой кэш на NSMutableDictionary с правильной copy-семантикой
   ключей. Словарь сам копирует ключи (поэтому ключ должен быть NSCopying);
   мутабельный ключ, изменённый после вставки, иначе «потерял» бы значение. */

@interface Cache : NSObject
- (void)setObject:(id)obj forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (NSUInteger)count;
@end

@implementation Cache {
    NSMutableDictionary<NSString *, id> *_store;
}
- (instancetype)init {
    self = [super init];
    if (self) { _store = [NSMutableDictionary dictionary]; }
    return self;
}
- (void)setObject:(id)obj forKey:(NSString *)key {
    /* setObject:forKey: словаря сам делает [key copy] — ключ замораживается */
    _store[key] = obj;
}
- (id)objectForKey:(NSString *)key { return _store[key]; }
- (NSUInteger)count { return _store.count; }
@end

int main(void) {
    @autoreleasepool {
        Cache *cache = [[Cache alloc] init];

        NSMutableString *key = [NSMutableString stringWithString:@"user:1"];
        [cache setObject:@"Асет" forKey:key];

        /* меняем исходный мутабельный ключ ПОСЛЕ вставки */
        [key appendString:@"-changed"];

        /* значение по-прежнему достаётся по ОРИГИНАЛЬНОМУ ключу:
           словарь хранил КОПИЮ «user:1», а не ссылку на key */
        NSLog(@"по 'user:1':         %@", [cache objectForKey:@"user:1"]);
        NSLog(@"по изменённому ключу: %@", [cache objectForKey:key]);
        NSLog(@"объектов в кэше: %lu", (unsigned long)[cache count]);
    }
    return 0;
}
