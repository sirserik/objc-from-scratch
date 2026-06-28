// Как в C++: полиморфизм через virtual + общий базовый класс.
// Чтобы вызов разрешался динамически, метод должен быть virtual,
// а объекты — связаны наследованием. RTTI (dynamic_cast/typeid)
// ограничен и требует включённого -frtti (по умолчанию включён).
// Сборка:
//   clang++ -std=c++17 -Wall -Wextra -O2 g-poly.cpp -o /tmp/t && /tmp/t
#include <iostream>
#include <vector>
#include <memory>
#include <typeinfo>

struct Animal {
    virtual ~Animal() = default;
    virtual std::string speak() const = 0;   // чисто виртуальный -> абстрактный
};
struct Dog : Animal { std::string speak() const override { return "гав"; } };
struct Cat : Animal { std::string speak() const override { return "мяу"; } };

int main() {
    std::vector<std::unique_ptr<Animal>> zoo;
    zoo.push_back(std::make_unique<Dog>());
    zoo.push_back(std::make_unique<Cat>());

    for (const auto &a : zoo) {
        // Динамическая диспетчеризация — но ТОЛЬКО потому, что speak() virtual
        // и все элементы общего базового типа Animal.
        std::cout << a->speak();

        // RTTI: проверить реальный тип можно через dynamic_cast.
        if (dynamic_cast<Dog *>(a.get())) std::cout << " (это Dog)";
        std::cout << "\n";
    }
    return 0;
}
