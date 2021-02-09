
#include <stdio.h>
#include "test1.hh"
#include "test2.hh"
#include "exclude/test3.hh"

int main(int argc, char** argv) {
  printf("Hello world");
}

struct Test3 {
  int x;
  int y;
  int z;
};
