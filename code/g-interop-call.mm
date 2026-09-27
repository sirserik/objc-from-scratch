// Objective-C++ (.mm): обратное направление — зовём Objective-C
// из обычной C++-функции. C++-код держит ObjC-объект, шлёт ему
// сообщения и читает результат.
// Сборка:
//   clang++ -ObjC++ -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-interop-call.mm -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>
#include <cstdio>
#include <string>
#include <vector>

// Чисто C++-функция. Внутри свободно пользуется Foundation:
// создаёт NSString, шлёт ему сообщения, конвертирует обратно в std::string.
static std::string normalize(const std::string &input) {
    @autoreleasepool {
        NSString *s = [NSString stringWithUTF8String:input.c_str()];
        NSString *trimmed = [s stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
        NSString *upper = [trimmed uppercaseString];
        return std::string([upper UTF8String]);   // NSString -> std::string
    }
}

// Ещё одна C++-функция: считает длину через ObjC-сообщение [s length].
static std::size_t objcLength(const std::string &input) {
    @autoreleasepool {
        NSString *s = [NSString stringWithUTF8String:input.c_str()];
        return static_cast<std::size_t>([s length]);
    }
}

int main() {
    std::vector<std::string> raw{"  привет  ", "Objective-C++", "  mix  "};
    for (const std::string &item : raw) {
        std::string out = normalize(item);
        // out.size() посчитал бы БАЙТЫ UTF-8 (у «ПРИВЕТ» их 12). Длину
        // в символах берём у NSString: -length считает UTF-16-единицы,
        // для кириллицы и латиницы это и есть символы.
        printf("'%s' -> '%s' (len=%zu)\n",
               item.c_str(), out.c_str(), objcLength(out));
    }
    return 0;
}
