// Как в C++: перегрузка функций (одно имя — разные сигнатуры) и
// перегрузка операторов. Компилятор выбирает версию по типам аргументов.
// В Objective-C нет ни того, ни другого: имя метода с двоеточиями —
// уникальный селектор, поэтому методы называют длинно и по-разному
// (initWithName:, initWithName:age: — это РАЗНЫЕ имена, не «перегрузка»).
// Сборка:
//   clang++ -std=c++17 -Wall -Wextra -O2 g-overload.cpp -o /tmp/t && /tmp/t
#include <iostream>
#include <string>

// Перегрузка функций: одно имя area, выбор по типам/числу аргументов.
double area(double side)            { return side * side; }
double area(double w, double h)     { return w * h; }
std::string area(const std::string &s) { return "площадь фигуры " + s; }

// Перегрузка оператора + для своего типа.
struct Vec2 {
    double x, y;
    Vec2 operator+(const Vec2 &o) const { return {x + o.x, y + o.y}; }
};

int main() {
    std::cout << area(3.0)        << "\n";   // квадрат: 9
    std::cout << area(2.0, 5.0)   << "\n";   // прямоугольник: 10
    std::cout << area(std::string("X")) << "\n";

    Vec2 a{1, 2}, b{3, 4};
    Vec2 c = a + b;                          // operator+
    std::cout << "(" << c.x << ", " << c.y << ")\n";  // (4, 6)
    return 0;
}
