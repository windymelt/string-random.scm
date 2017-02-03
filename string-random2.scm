(use parser.peg)
(use util.match)
(use data.random)
(use gauche.generator)

;;; const
(define MAX-REPEAT 20)

;;; utility
;; (run "(+ 1 2)") => 3
(define (run str) (eval (read (open-input-string str)) (interaction-environment)))

;;; defining parser
(define %char ($none-of #[\[\(\|?+*{}}]))

(define %char-class
  ($lift
   (^[cs] (cons 'class (run #"#[~(list->string cs)]")))
   ($between ($c #\[) ($many ($none-of #[\]])) ($c #\]))))

(define %atom ($or ($between ($c #\() ($lazy %regex) ($c #\))) %char %char-class))

(define %bracket-form
  ($do
   [_ ($c #\{)]
   [lower-bound ($many1 digit)]
   [_ ($c #\,)]
   [upper-bound ($many1 digit)]
   [_ ($c #\})]
   ($return
    (cons
     'range
     (cons
      ($ string->number $ list->string lower-bound)
      ($ string->number $ list->string upper-bound))))))

(define %piece
  ($do
   [a %atom]
   [quantifier ($optional ($or ($one-of #[?*+]) %bracket-form))]
   ($return
    (cond
     [(char? quantifier) (cons ($ string->symbol $ list->string $ list quantifier) (list a))]
     [(pair? quantifier) (cons quantifier (list a))]
     [else (cons #f (list a))]))))

(define %branch ($many1 %piece))

(define %regex ($lift (cut cons 'or <>) ($sep-by %branch ($c #\|))))

;;; generating string
(define tgt "[カコヵか][ッー]{1,3}?[フヒふひ]{1,3}[ィェー]{1,3}[ズス][ドクグュ][リイ][プブぷぶ]{1,3}[トドォ]{1,2}")
(print (peg-parse-string %regex tgt))

(define (pop gen) (car (generator->list gen 1)))
(define (popstr gen len) (list->string (generator->list gen len)))

(define (walk tree)
  (match tree
    [() ""]
    [(? char? c) ($ list->string $ list c)]
    [(#f . c) (walk c)]
    [('class . cs) (popstr (chars$ cs) 1)]
    [(('range . (a . z)) . xs) (walk (make-list (pop (integers-between$ a z)) xs))]
    [('? . xs) (if booleans (walk xs) "")]
    [('+ . xs) (walk (make-list (pop (integers$ MAX-REPEAT 1)) xs))]
    [('* . xs) (walk (make-list (pop (integers$ MAX-REPEAT 0)) xs))]
    [('or . xs) ($ walk $ pop $ samples$ xs)]
    [(x . xs) (string-append (walk x) (walk xs))]))

;(set! (random-data-seed) 4)
(print (walk (peg-parse-string %regex tgt)))
(print (generator->list
        (generate (^[yield] (let loop ([i 0])
                              (when (< i 10) (yield (walk (peg-parse-string %regex tgt))) (loop (+ i 1))))))
        10))

