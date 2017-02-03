(use parser.peg)
(use util.match)

(define %char ($none-of #[\]\)\|]))
(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char))
(define %piece ($do
                [a %atom]
                [op ($optional ($one-of #[?*+]))]
                ($return
                 (if op (cons ($ string->symbol $ list->string $ list op) (list a)) (cons #f (list a))))))
(define %branch ($many %piece 1))
(define %regex ($lift (^[xs] (cons 'or xs)) ($sep-by %branch ($c #\|))))

(define tgt "(nyaa|meow)")
(print (peg-parse-string %regex tgt))

(define s "")
(define (walk tree)
  (match #?=tree
    [() ""]
    [(? char? c) ($ list->string $ list #?=c)]
    [(#f . c) (walk c)]
    [('? . xs) ""]
    [('+ . xs) (walk xs)]
    [('or . xs) (walk (car xs))]
    [(x . xs) (string-append (walk x) (walk xs))]))

(print (walk (peg-parse-string %regex tgt)))
