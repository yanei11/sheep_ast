#include <stdio.h>

namespace abc {

class test3 {
  test3() {}
};

namespace bbb {


class test2 {
  test2() {}
};

namespace ccc {

class test {
  test() {}
};

}  // namespace ccc
}  // namespace bbb
}  // namespace abc

int main(int argc, char** argv) {
  printf("test");
}
