// Как в C++: лямбды. Захват по значению [=], по ссылке [&],
// мутирование захваченного — через mutable. Тип хранения —
// std::function или auto.
// Сборка:
//   clang++ -std=c++17 -Wall -Wextra -O2 g-blocks.cpp -o /tmp/t && /tmp/t
#include <iostream>
#include <functional>
#include <vector>
#include <string>
#include <algorithm>   // std::for_each

int main() {
    int base = 10;

    // Захват по значению: внутри лежит КОПИЯ base.
    auto addByValue = [base](int x) { return base + x; };

    // Захват по ссылке: лямбда видит ИЗМЕНЕНИЯ base снаружи.
    auto addByRef = [&base](int x) { return base + x; };

    base = 100;
    std::cout << "byValue(5) = " << addByValue(5) << "\n";  // 15 (старое base)
    std::cout << "byRef(5)   = " << addByRef(5)   << "\n";  // 105 (новое base)

    // Изменяемое состояние внутри лямбды требует mutable.
    auto counter = [n = 0]() mutable { return ++n; };
    // Порядок вычисления слева направо у << гарантирован с C++17.
    std::cout << "counter: " << counter() << counter() << counter()
              << "\n";                                     // 123

    // Лямбду можно хранить в std::function и передавать.
    std::function<void(const std::string &)> greet =
        [](const std::string &who) {
            std::cout << "Привет, " << who << "!\n";
        };
    greet("C++");

    // Передача лямбды в алгоритм:
    std::vector<int> v{1, 2, 3, 4};
    int sum = 0;
    std::for_each(v.begin(), v.end(), [&sum](int e) { sum += e; });
    std::cout << "sum = " << sum << "\n";   // 10
    return 0;
}
