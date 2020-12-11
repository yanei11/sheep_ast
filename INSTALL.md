To install the sheep_ast, proceding following steps:

```
1. git clone this repository
2. install ruby. The version in the development is >= 2.4.1p111. You can use rbenv to install the ruby version you want
3. execute `rbenv exec bundle install`
4. export RBENV_COM="rbenv exec"
5. rake srbinit
```

If you use rbenv command, procedure 3 and 4 are required.
`rake srbinit` initialize sorbet.  

After steps 1 ~ 5, then you can use `rake xxx` commands.  
The well using command will be:

```
rake -> execute rspec command
rake tc -> execute type check using sorbet
rake exampleX -> execute example no X program
```
