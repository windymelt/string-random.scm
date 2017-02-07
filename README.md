# string-random.scm
A gauche implementation of String::Random

## Usage

``` shell
$ ./string-random2.scm [-n N] [--max-repeat N] [--seed N] 'regex'
```

- `-n N` means size of generated row. (default 10)
- `--max-repeat N` means max limit of repeating e.g. `+`. (default 6)
- `--seed N` means seed of generation. (default 0)

## Supported grammar

- Escaped character literal `\\[sdwSDW^\\.\-]` e.g. `\d\d\d`
- POSIX charset e.g. `[[:alpha:]]`, `[ABC]`
- Character repeating `A{5}`, `A{3,4}`
- Optional operator `A?`
- Plus operator `A+`
- Star operator `A*`
- Grouping `(foo)?`
- Or operator `(A|B)`

## TBD

- Backref e.g. `\1`
- Semi-opened curly range e.g. `{3,}`

## Not supported

- Possessive quantifier e.g. `A++`
- Non-greedy quantifier e.g. `A+?`
