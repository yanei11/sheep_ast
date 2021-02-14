# Install from GitHub

To install the sheep_ast, there is two way.

# For just using sheep_ast

You can download from this link all in one package: https://github.com/yanei11/sheep_ast/releases.  
You should just add execute permission to the file and execute it.  
The example command is listed in [bin/bin_test.rb](https://github.com/yanei11/sheep_ast/blob/master/spec/bin/bin_test.rb)

# For the library user, or developer

proceding following steps:

```
- git clone this repository
- install ruby. The version in the development is 3.0.0 and 2.7.2. You can use rbenv to install the ruby version you want
- rake srbinit
```

`rake srbinit` initialize sorbet.  

The frequently used command are:

```
rake unit -> execute rspec command
rake bin -> execute executable test command using bin/run-sheep-ast
rake bin-appimage -> execute executable test command using AppImage. This is tested on Ubuntu 20.04
rake tc -> execute type check using sorbet
rake exampleX -> execute example no X program
```

# Other packages

gem installation is supported. Please see here: https://github.com/yanei11?tab=packages&repo_name=sheep_ast
