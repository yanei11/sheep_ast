# For just using sheep_ast
  
sheep_ast supports [AppImage](https://appimage.org/) format.  
You can download from this link all in one package at [release page](https://github.com/yanei11/sheep_ast/releases).  
You should just add execute permission to the file and you can try sheep_ast to execute the file.   
  
The example command is listed in [bin/bin_test.rb](https://github.com/yanei11/sheep_ast/blob/master/spec/bin/bin_test.rb)  
This AppImage is just executing [bin/run-sheep-ast](https://github.com/yanei11/sheep_ast/blob/master/bin/run-sheep-ast) file.

# For the library user, or developer

proceding following steps:

```
- git clone this repository
- install ruby. # The version in the development is 3.0.0 and 2.7.2. You can use rbenv to install the ruby version you want
- rake srbinit  # This command only works for 2.7.2. This is current limitation on sorbet. After this command "rake tc" command becomes to work.
```

The frequently used command are:

```
rake unit -> execute rspec command
rake bin -> execute executable test command using bin/run-sheep-ast
rake bin-appimage -> execute executable test command using AppImage. This is tested on Ubuntu 20.04. Some library might be needed to install.
rake tc -> execute type check using sorbet
rake exampleX -> execute example no X program
```

# Other packages

gem installation is supported. Please see [gem release](https://github.com/yanei11?tab=packages&repo_name=sheep_ast).
