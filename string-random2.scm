(use parser.peg)
(use util.match)
(use data.random)
(use gauche.generator)

(define %char ($none-of #[\]\)\|]))
(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char))
(define %piece ($do
                [a %atom]
                [op ($optional ($one-of #[?*+]))]
                ($return
                 (if op (cons ($ string->symbol $ list->string $ list op) (list a)) (cons #f (list a))))))
(define %branch ($many %piece 1))
(define %regex ($lift (^[xs] (cons 'or xs)) ($sep-by %branch ($c #\|))))

(define tgt "(ルイズ！)+((ルイズ！?)+|(ぅ*う*わぁ+あ+ん！+)|あ+ぁ+|ぅ+)+")
(print (peg-parse-string %regex tgt))

(define s "")
(define (walk tree)
  (match tree
    [() ""]
    [(? char? c) ($ list->string $ list c)]
    [(#f . c) (walk c)]
    [('? . xs) (if booleans (walk xs) "")]
    [('+ . xs) (walk (make-list (car (generator->list (integers$ 6 1) 1)) xs))]
    [('* . xs) (walk (make-list (car (generator->list (integers$ 6 0) 1)) xs))]
    [('or . xs) (walk (car (generator->list (samples$ xs) 1)))]
    [(x . xs) (string-append (walk x) (walk xs))]))

;(set! (random-data-seed) 42)
(print (walk (peg-parse-string %regex tgt)))
