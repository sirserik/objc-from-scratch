// Objective-C++ (.mm): в ОДНОМ классе держим C++-объекты как ivar
// и зовём C++ прямо из методов Objective-C.
// Файл .mm компилируется как Objective-C++ (clang++ -ObjC++).
// Сборка:
//   clang++ -ObjC++ -fobjc-arc -framework Foundation -Wall -Wextra -O2 \
//       g-interop.mm -o /tmp/t && /tmp/t
#import <Foundation/Foundation.h>
#include <string>
#include <vector>
#include <numeric>      // std::accumulate
#include <algorithm>    // std::sort

// Обычный C++-класс — ничего объективно-сишного в нём нет.
class Stats {
public:
    void add(double v) { _data.push_back(v); }
    double sum()  const { return std::accumulate(_data.begin(), _data.end(), 0.0); }
    double mean() const { return _data.empty() ? 0.0 : sum() / _data.size(); }
    std::vector<double> sorted() const {
        std::vector<double> c = _data;
        std::sort(c.begin(), c.end());
        return c;
    }
private:
    std::vector<double> _data;
};

@interface Sample : NSObject
- (void)addValue:(double)v;
- (double)mean;
- (NSString *)describe;
@end

@implementation Sample {
    // C++-объекты как поля ObjC-класса. Их деструкторы runtime вызовет
    // при уничтожении объекта — в скрытом методе .cxx_destruct, который
    // сгенерировал компилятор (см. главу 14).
    Stats       _stats;
    std::string _label;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _label = "sample";   // присваиваем C++-строке прямо здесь
    }
    return self;
}

- (void)addValue:(double)v {
    _stats.add(v);            // зовём C++-метод из ObjC-метода
}

- (double)mean { return _stats.mean(); }

- (NSString *)describe {
    // Туда-обратно между мирами: C++ std::string -> NSString, и наоборот.
    std::vector<double> s = _stats.sorted();
    NSMutableString *line = [NSMutableString string];
    for (double v : s) [line appendFormat:@"%.1f ", v];

    return [NSString stringWithFormat:@"%s: mean=%.2f, sorted=[%@]",
            _label.c_str(), _stats.mean(), line];
}

@end

int main(void) {
    @autoreleasepool {
        Sample *s = [[Sample alloc] init];
        for (double v : {3.0, 1.0, 4.0, 1.5, 9.0}) [s addValue:v];

        NSLog(@"mean = %.2f", [s mean]);
        NSLog(@"%@", [s describe]);
    }
    return 0;
}
