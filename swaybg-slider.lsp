#!/bin/env newlisp

;; Set the seed for amb
(seed (time-of-day))

(constant
	'wallpaper-directory "/home/maddix/Photos/Wallpapers"
	'wallpaper-extensions '("jpg" "jpeg" "png")
	'change-time (* 1000 60 30)
	'SIGINT 2
	'SIGQUIT 3
	'SIGKILL 4
	'SIGCHLD 17)

(define (get-swaybg-path) (first (exec "which swaybg")))
(define (join-str) (join (args) " "))
(define (join-path) (join (args) "/"))
(define (double-quote str) (string "\"" str "\""))

(define (get-outputs)
	(map
		(curry lookup "name")
		(json-parse (join (exec "swaymsg -t get_outputs")))))

(define (set-wallpaper output wallpaper)
	(process (join-str (get-swaybg-path) "-o" output "-m stretch -i" (double-quote wallpaper))))

(define (valid-file? file)
	(when
		(not (empty? (filter (curry ends-with file) wallpaper-extensions)))
		file))

(define (get-images)
	(map
		(curry join-path wallpaper-directory)
		(filter valid-file? (directory wallpaper-directory))))

(let
	(current-pids (list)
	new-pids(list)
	image-lst (list))

	;; Specific methods 
	(define (cleanup process-lst) 
		(map destroy process-lst))
	(define (cleanup-and-exit)
		(println "Cleanup and exit...")
		(cleanup current-pids)
		(cleanup new-pids)
		(exit 0))
	(define (create-swaybg-processes)
		(map 
			(fn (output) (set-wallpaper output (apply amb image-lst)))
			(get-outputs)))

	;; Set the signal handlers
	(signal SIGINT 'cleanup-and-exit)
	(signal SIGQUIT 'cleanup-and-exit)
	(signal SIGKILL 'cleanup-and-exit)
	(signal SIGCHLD "ignore") 


	(while true
		(set 'image-lst (get-images))
		(setq new-pids (create-swaybg-processes))
		(sleep 1000)
		(cleanup current-pids)
		(setq current-pids new-pids)
		(setq new-pids (list))
		(sleep change-time)))

(exit 0)
