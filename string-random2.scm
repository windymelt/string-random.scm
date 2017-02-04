(use parser.peg)
(use util.match)
(use data.random)
(use gauche.generator)

;;; const
(define MAX-REPEAT 20)

;;; utility
;; (run "(+ 1 2)") => 3
(define (run str) (eval (read (open-input-string str)) (interaction-environment)))
(define (char->symbol c) (string->symbol (list->string (list c))))

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
   [quantifier ($many ($or ($one-of #[?*+]) %bracket-form))]
   ($return
    (fold
     (^[q body]
       (cond
        [(char? q) (cons (char->symbol q) body)]
        [(pair? q) (cons q body)]
        [else (cons #f body)]))
     (list a)
     quantifier))))

(define %branch ($many1 %piece))

(define %regex ($lift (cut cons 'or <>) ($sep-by %branch ($c #\|))))

;;; generating string

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
(define sep-by-nl (cut string-join <> "\n"))

;;; main
(define (main *argv*)
  (let1
   tgt (cadr *argv*)
   (print (peg-parse-string %regex tgt))
   ($ print
      $ sep-by-nl
      $ generator->list
      $ generate
      (^[yield]
        (let loop ([i 0])
          (when (< i 10) ($ yield $ walk $ peg-parse-string %regex tgt) (loop (+ i 1)))
          )))))

