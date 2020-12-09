To install the sheep_ast, proceding following steps:

```
1. git clone this repository
2. install ruby. The version in the development is >= 2.4.1p111. You can use rbenv to install the ruby version you want
3. execute `rbenv exec bundle install`
4. export RBENV_COM="rbenv exec"
5. make srbinit
```

If you use rbenv command, procedure 3 and 4 are required.
`make srbinit` initialize sorbet.  

After steps 1 ~ 5, then you can use `make xxx` commands.  
The well using command will be:

```
make -> execute rspec command
make tc -> execute type check using sorbet
make exampleX -> execute example no X program
```
