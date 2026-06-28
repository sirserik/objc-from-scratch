// Как в C++: std::vector — value-тип. Присваивание = ГЛУБОКАЯ КОПИЯ.
// Два имени — два независимых контейнера.
// Сборка:
//   clang++ -std=c++17 -Wall -Wextra -O2 g-copy-semantics.cpp -o /tmp/t && /tmp/t
#include <iostream>
#include <vector>
#include <string>

int main() {
    std::vector<std::string> a{"apple", "banana"};
    std::vector<std::string> b = a;   // КОПИЯ всех элементов

    b.push_back("cherry");            // меняем только b
    b[0] = "APPLE";

    std::cout << "a.size() = " << a.size()
              << ", a[0] = " << a[0] << "\n";   // 2, apple — не тронут
    std::cout << "b.size() = " << b.size()
              << ", b[0] = " << b[0] << "\n";   // 3, APPLE

    // Адреса буферов разные — это разные объекты в памяти:
    std::cout << "&a[0] == &b[0]? "
              << (&a[0] == &b[0] ? "yes" : "no") << "\n";   // no
    return 0;
}
