// Как в C++: вызов метода у nullptr — неопределённое поведение.
// Поэтому ПЕРЕД вызовом надо проверить указатель руками.
// Сборка:
//   clang++ -std=c++17 -Wall -Wextra -O2 g-nil-vs-null.cpp -o /tmp/t && /tmp/t
#include <cctype>
#include <iostream>
#include <string>

struct Greeter {
    std::string name;
    std::size_t length() const { return name.size(); }
    std::string upper() const {
        std::string r = name;
        for (char &c : r)   // toupper ждёт unsigned char, иначе UB
            c = static_cast<char>(
                std::toupper(static_cast<unsigned char>(c)));
        return r;
    }
};

int main() {
    Greeter *g = nullptr;   // объекта нет — голый указатель в никуда

    // Прямой вызов g->length() здесь — UB (разыменование nullptr),
    // на практике почти всегда мгновенный краш. Защищаемся вручную:
    if (g != nullptr) {
        std::cout << "length = " << g->length() << "\n";
    } else {
        std::cout << "g == nullptr, метод НЕ вызван (иначе UB/краш)\n";
    }

    Greeter real{"hello"};
    g = &real;
    if (g != nullptr) {
        std::cout << "length = " << g->length()
                  << ", upper = " << g->upper() << "\n";
    }
    return 0;
}
