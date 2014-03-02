#lang racket/base
(require metapict racket/format racket/match racket/list)

;;; Principles
; 1. Edges should not cross
; 2. All nodes at the same depth should be drawn on a horizontal line. 
; 3. Tree should be drawn as a narrow as possible.

(struct tree (elm children pos contour))

;         A
;     B     C
;    D E   F G
;      H   I
(define a-tree '(a (b (d) (e (h)))
                   (c (f (i)) (g))))

(define (leaf? t)    (not (pair? t)))
(define (element t)  (car t))
(define (children t) (cdr t))

(define (depth t)
  (if (leaf? t)
      1
      (+ 1 (for/fold ([m 0]) ([c (children t)])
             (max m (depth c))))))

(define (minimum-width-tree-positions t)
  ; Minimum width tree, principle 1, 2, and, 3.  
  ; Track positions of subtrees (not elements).
  (def positions (make-hasheq)) 
  ; nexts[i] = next available slot on row i
  (def nexts     (make-hash))
  (define (recur tree depth)
    (def next (hash-ref! nexts depth 0))
    (hash-set! positions tree (pt next depth))
    (hash-set! nexts depth (+ next 1))
    (for ([c (children tree)])
      (recur c (+ depth 1))))
  (recur t 0)
  positions)

;;; Principles 
; 4. A parent should be centered over its children
(define (simple-centered-tree-positions t)
  ; Principle 1, 2, and, 4.  (i.e. narrowness not a goal)
  ; Traversal 1: Use post order traversal (root x-pos is mean of childrens)
  ;              Use mods to store horizontal movements of subtrees.
  ; Traversal 2: Add mods to compute final horizontal placement.
  
  ; Track positions of subtrees (not elements).
  (def positions (make-hasheq))
  (define (posn t)    (hash-ref positions t))
  (define (posn! t p) (hash-set! positions t p))
  ; nexts[i] = next available slot on row i
  (def nexts (make-hash))
  (define (next t)    (hash-ref! nexts t 0))
  (define (next! t n) (hash-set! nexts t n))
  
  (def offsets (make-hash))
  (define (offset d)    (hash-ref! offsets d 0))
  (define (offset! d o) (displayln (list 'offset! d o)) (hash-set! offsets d o))
  
  (def mods (make-hasheq))
  (define (mod t)    (hash-ref! mods t 0))
  (define (mod! t m) (hash-set! mods t m))
  
  ;; Traversal 1
  (define (recur t depth)
    (for ([c (children t)])
      (recur c (+ depth 1)))
    (displayln (list t depth offsets mods))
    (def y depth)
    (def cs (if (leaf? t) '() (children t)))
    (def place (match cs
                 [(list)             (next depth)]
                 [(list c)           (pt-x (posn c))]
                 [(list c0 c ... cn) (/ (+ (pt-x (posn c0)) (pt-x (posn cn))) 2)]))
    (offset! depth (max (offset depth) (- (next depth) place)))
    (def x (+ place (if (empty? cs) 0 (offset depth))))
    (posn! t (pt x y))
    (next! depth (+ (next depth) 2))
    (mod! t (offset depth)))
  
  (define (addmods t modsum)
    (displayln (list modsum t))
    (posn! t (pt+ (posn t) (vec modsum 0)))
    (def newmodsum (+ modsum (mod t)))
    (for ([c (children t)])
      (addmods c newmodsum)))
  
  (recur t 0)
  (addmods t 0)
  (displayln positions)
  (displayln offsets)
  (displayln mods)
  positions)

;;; Principle
; 5. A subtree should be drawn the same no matter where it is in the tree

(define (draw-tree tree positions)
  (define (posn t) (hash-ref positions t))
  (define (recur tree drawing)
    (def p (posn tree))
    (def d (draw drawing (color "red" (draw (label-cnt (~a (element tree)) p)))))
    (cond [(leaf? tree) d]
          [else         (draw d (for/draw ([c (children tree)])
                                          (draw (curve p -- (posn c))
                                                (recur c d))))]))
  (recur tree (draw)))

(set-curve-pict-size 300 300)
(define (draw-example calculate-positions)
  (with-window (window -1 10 -1 10)
    (def t a-tree)
    (draw (color "gray" (grid (pt 0 0) (pt 10 10) (pt 0 0) 1))
          (draw-tree t (calculate-positions t)))))

(draw-example minimum-width-tree-positions)
(draw-example simple-centered-tree-positions)