(use parser.peg)
(use util.match)
(use data.random)
(use gauche.generator)

(define MAX-REPEAT 20)

(define (run str) (eval (read (open-input-string str)) (interaction-environment)))

(define %char ($none-of #[\[\(\|]))
(define %char-class
  ($lift
   (^[cs] (cons 'class (run (string-append "#[" (list->string cs) "]"))))
   ($between ($c #\[) ($many ($none-of #[\]])) ($c #\]))))
(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char %char-class))
(define %piece ($do
                [a %atom]
                [op ($optional ($one-of #[?*+]))]
                ($return
                 (if op (cons ($ string->symbol $ list->string $ list op) (list a)) (cons #f (list a))))))
(define %branch ($many %piece 1))
(define %regex ($lift (^[xs] (cons 'or xs)) ($sep-by %branch ($c #\|))))


(define tgt "[01]+")
(print (peg-parse-string %regex tgt))

(define (pop gen) (car (generator->list gen 1)))
(define (popstr gen len) (list->string (generator->list gen len)))

(define (walk tree)
  (match tree
    [() ""]
    [(? char? c) ($ list->string $ list c)]
    [(#f . c) (walk c)]
    [('class . cs) (popstr (chars$ cs) 1)]
    [('? . xs) (if booleans (walk xs) "")]
    [('+ . xs) (walk (make-list (pop (integers$ MAX-REPEAT 1)) xs))]
    [('* . xs) (walk (make-list (pop (integers$ MAX-REPEAT 0)) xs))]
    [('or . xs) (walk (pop (samples$ xs)))]
    [(x . xs) (string-append (walk x) (walk xs))]))

;(set! (random-data-seed) 4)
(print (walk (peg-parse-string %regex tgt)))
