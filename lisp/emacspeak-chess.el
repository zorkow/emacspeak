;;; emacspeak-chess.el --- Speech-enable CHESS  -*- lexical-binding: t; -*-
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable CHESS An Emacs Interface to chess
;;; Keywords: Emacspeak,  Audio Desktop chess
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-05-03 18:13:44 -0700 (Thu, 03 May 2007) $ |
;;;  $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2007, 2019, T. V. Raman
;;; All Rights Reserved.
;;;
;;; This file is not part of GNU Emacs, but the same permissions apply.
;;;
;;; GNU Emacs is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.
;;;
;;; GNU Emacs is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNCHESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;;
;;; The Emacs Chess package provides a rich environment for playing and
;;; exploring Chess Games.
;;; That package comes with a light-weight module that announces
;;; moves.
;;;
;;; This module aims do do much more, including:
;;; @itemize @bullet
;;; @item Navigate the board along various axies with audio-formatted  output.
;;;  @item Browse games via  rich audio-formatted   output.
;;; @item Speech-enable all interactive commands  provided by the Chess
;;; package.
;;; @item Enable various means of exploring the state of game, perhaps with
;;; a view to being able to spot patterns   from listening to the
;;; output.
;;; @end itemize 
;;; @subsection Board Navigation:
;;; The board can be navigated along the 8 compass directions.
;;; Arrow keys move to the appropriate squares on the board.
;;; @kbd{/} and @kbd{\} move down the diagonals.
;;; @kbd{[} and @kbd{]} move up the respective diagonals.
;;; @itemize  @bullet
;;; @item  Move North: @code{emacspeak-chess-north} bound to @kbd{up}.
;;; @item  Move South: @code{emacspeak-chess-south} bound to
;;; @kbd{down}.
;;; @item  Move West: @code{emacspeak-chess-west} bound to @kbd{left}.
;;; @item  Move East: @code{emacspeak-chess-east} bound to @kbd{right}.
;;; @end itemize
;;; You can also move along the diagonals:
;;; @itemize @bullet
;;; @item  Move Northeast: @code{emacspeak-chess-northeast} bound to  @kbd{]}.
;;; @item  Move Northwest: @code{emacspeak-chess-northwest} bound to
;;; @kbd{[}.
;;; @item  Move Southwest: @code{emacspeak-chess-southwest} bound to
;;; @kbd{/}.
;;; @item  Move Southeast: @code{emacspeak-chess-southeast} bound to
;;; @kbd{\}.
;;; @end itemize
;;; You can also jump to a given board position by:
;;; @itemize @bullet
;;; @item  Jump: @code{emacspeak-chess-jump} bound to @kbd{j}.
;;; @end itemize
;;; finally, you can review the current square  with @kbd{;}.

;;; Code:

;;}}}
;;{{{  Required modules

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(eval-when-compile
  (require 'chess-pos nil 'noerror)
  (require 'chess-display nil 'noerror))

;;}}}
;;{{{ Map Faces:

(voice-setup-add-map
 '(
   (chess-display-black-face voice-bolden)
   (chess-display-white-face voice-lighten)
   (chess-ics1-black-face voice-bolden)
   (chess-ics1-highlight-face voice-animate)
   (chess-ics1-white-face voice-lighten)
   (chess-plain-black-face voice-bolden)
   (chess-plain-highlight-face voice-animate)
   (chess-plain-white-face voice-lighten)))

;;}}}
;;{{{Helpers:

(defvar emacspeak-chess-piece-names
  '((?q . "queen")
    (?k . "king")
    (?b . "bishop")
    (?n . "knight")
    (?r . "rook")
    (?p . "pawn")
    (?\  . " "))
  "Piece-char to piece-name mapping.")

(defsubst emacspeak-chess-piece-name (char)
  "Return piece name."
  (cdr (assq (downcase char) emacspeak-chess-piece-names)))

(defun emacspeak-chess-describe-square (index)
  "Return an audio formatted description of square at given index.
  Argument index is an integer between 0 and 63 as in package chess."
  (cl-assert (eq major-mode 'chess-display-mode) t "Not in a Chess  display.")
  (let ((position (chess-display-position nil))
        (piece nil)
        (white nil)
        (light nil)
        (rank nil)
        (file nil)
        (coord nil))
    (cl-assert position t "Could not retrieve game position.")
    (setq coord (chess-index-to-coord index)
          piece (chess-pos-piece position index)
          rank (chess-index-rank index)
          file (chess-index-file index)
          light                         ; square color
          (or
           (and (cl-evenp rank ) (cl-evenp file))
           (and (cl-oddp rank) (cl-oddp file)))
          white (memq piece '(?R ?N ?B ?K ?Q ?P)) ;upper-case is white
          piece (emacspeak-chess-piece-name  piece))
    (unless white (setq piece (propertize  piece 'personality voice-bolden)))
    (if light ;;; square color
        (setq coord (propertize  coord 'personality voice-lighten-extra ))
        (setq coord (propertize  coord 'personality voice-monotone)))
    (list coord  piece)))

;;;###autoload
(defun emacspeak-chess-speak-this-square ()
  "Speak square under point."
  (interactive)
  (cl-assert (eq major-mode 'chess-display-mode) t "Not in a Chess  display.")
  (let ((index (get-text-property (point) 'chess-coord)))
    (cl-assert index t "Not on a valid square.")
    (dtk-speak-list  (emacspeak-chess-describe-square index) 2)))


(defun emacspeak-chess-speak-that-square (coord)
  "Speak square at specified coord."
  (interactive "sCoord: ")
  (cl-assert (eq major-mode 'chess-display-mode) t "Not in a Chess  display.")
  (let ((index (chess-coord-to-index coord)))
    (cl-assert index t "Not  a valid square.")
    (dtk-speak-list  (emacspeak-chess-describe-square index) 2)))
;;}}}
;;{{{emacspeak Handler:

(defun chess-emacspeak-handler (game event &rest args)
  "Speak the move."
  (cond
   ((eq event 'initialize)
    (emacspeak-auditory-icon 'open-object)
    t)
   ((eq event 'move)
    (emacspeak-auditory-icon 'time)
    (let* ((ply (chess-game-ply game (1- (chess-game-index game))))
           (pos (chess-ply-pos ply)))
      (unless
          (let* ((source (chess-ply-source ply))
                 (target (chess-ply-target ply))
                 (s-piece (and source (chess-pos-piece pos source)))
                 (t-piece (and target (chess-pos-piece pos target)))
                 (which (chess-ply-keyword ply :which))
                 text)
            (if which
                (setq which (char-to-string which)))
            (cond
             ((chess-ply-keyword ply :castle)
              (setq text "short castle"))
             ((chess-ply-keyword ply :long-castle)
              (setq text "long castle"))
             ((and s-piece t-piece (= t-piece ? ) target)
              (setq text
                    (concat which
                            (format "%s to %s"
                                    (emacspeak-chess-piece-name s-piece)
                                    (chess-index-to-coord target)))))
             ((and s-piece t-piece target)
              (setq text
                    (concat which
                            (format "%s takes %s at %s"
                                    (emacspeak-chess-piece-name s-piece)
                                    (emacspeak-chess-piece-name t-piece)
                                    (chess-index-to-coord target))))))

            (let ((promotion (chess-ply-keyword ply :promote)))
              (if promotion
                  (setq text
                        (concat text ", "
                                (message "promotes  to %s"
                                         (emacspeak-chess-piece-name promotion))))))
            (if (chess-ply-keyword ply :en-passant)
                (setq text (concat text ", " "on possont")))
            (if (chess-ply-keyword ply :check)
                (setq text (concat text ", " "check")))
            (if (chess-ply-keyword ply :checkmate)
                (setq text (concat text ", " "checkmate ")))
            (if (chess-ply-keyword ply :stalemate)
                (setq text (concat text ", " "stalemate ")))

            (message text)))))
   ((eq event 'kibitz)
    (message (car args)))))

(provide 'chess-emacspeak)
;;}}}
;;{{{Emacspeak Setup:
;;; Forward Declaration to help documentation builder.
(defvar chess-default-modules)

(defun emacspeak-chess-setup ()
  "Emacspeak setup for Chess."
  (cl-declare (special chess-default-modules
                       chess-display-mode-map))
;;; silence commas for better intonation on blank squares
  (emacspeak-pronounce-add-dictionary-entry 'chess-display-mode "," "")
  (emacspeak-pronounce-refresh-pronunciations)
  (setq chess-default-modules
        (cl-remove
         '(chess-sound chess-announce)
         chess-default-modules :test 'equal))
  (cl-pushnew 'chess-emacspeak chess-default-modules)
  (cl-loop
   for binding in 
   '(
     ( ";" emacspeak-chess-speak-this-square)
     ("<up>" emacspeak-chess-north)
     ("<down>" emacspeak-chess-south)
     ("<left>" emacspeak-chess-west)
     ("<right>" emacspeak-chess-east)
     ("[" emacspeak-chess-northwest)
     ("]" emacspeak-chess-northeast)
     ("\\" emacspeak-chess-southeast)
     ("/" emacspeak-chess-southwest)
     ("t" emacspeak-chess-speak-that-square)
     ("j" emacspeak-chess-jump))
   do
   (emacspeak-keymap-update chess-display-mode-map binding)))

;;; Setup on load:

(emacspeak-chess-setup)

;;}}}
;;{{{Board Navigation:
;;;###autoload
(defun emacspeak-chess-jump (coord)
  "Jump to square specified as coord."
  (interactive "sCoord: ")
  (goto-char
   (chess-display-index-pos
    (current-buffer) (chess-coord-to-index coord)))
  (emacspeak-auditory-icon 'large-movement)
  (emacspeak-chess-speak-this-square))

(defun emacspeak-chess-move (direction)
  "Move in direction by one step."
  (let ((index (get-text-property (point) 'chess-coord))
        (target nil))
    (cl-assert index t "Not on a valid square.")
    (setq target (chess-next-index  index direction))
    (unless target (error "Edge of board"))
    (goto-char (chess-display-index-pos (current-buffer) target))
    (emacspeak-auditory-icon 'item)
    (emacspeak-chess-speak-this-square)))

(defun emacspeak-chess-north ()
  "Move north one step."
  (interactive)
  (cl-declare (special chess-direction-north))
  (emacspeak-chess-move chess-direction-north))

(defun emacspeak-chess-south ()
  "Move south one step."
  (interactive)
  (cl-declare (special chess-direction-south))
  (emacspeak-chess-move chess-direction-south))

(defun emacspeak-chess-west ()
  "Move west one step."
  (interactive)
  (cl-declare (special chess-direction-west))
  (emacspeak-chess-move chess-direction-west))

(defun emacspeak-chess-east ()
  "Move east one step."
  (interactive)
  (cl-declare (special chess-direction-east))
  (emacspeak-chess-move chess-direction-east))

(defun emacspeak-chess-northwest ()
  "Move northwest one step."
  (interactive)
  (cl-declare (special chess-direction-northwest))
  (emacspeak-chess-move chess-direction-northwest))

(defun emacspeak-chess-southwest ()
  "Move southwest one step."
  (interactive)
  (cl-declare (special chess-direction-southwest))
  (emacspeak-chess-move chess-direction-southwest))

(defun emacspeak-chess-northeast ()
  "Move northeast one step."
  (interactive)
  (cl-declare (special chess-direction-northeast))
  (emacspeak-chess-move chess-direction-northeast))

(defun emacspeak-chess-southeast ()
  "Move southeast one step."
  (interactive)
  (cl-declare (special chess-direction-southeast))
  (emacspeak-chess-move chess-direction-southeast))

;;}}}
;;{{{ Interactive Commands:

'(
  chess
  chess-debug-position
  chess-display-abort
  chess-display-accept
  chess-display-annotate
  chess-display-call-flag
  chess-display-chat
  chess-display-check-autosave
  chess-display-clear-board
  chess-display-create
  chess-display-decline
  chess-display-draw
  chess-display-duplicate
  chess-display-edit-board
  chess-display-force
  chess-display-highlight-passed-pawns
  chess-display-invert
  chess-display-kill-board
  chess-display-list-buffers
  chess-display-manual-move
  chess-display-match
  chess-display-mode
  chess-display-mouse-select-piece
  chess-display-mouse-set-piece
  chess-display-move-backward
  chess-display-move-first
  chess-display-move-forward
  chess-display-move-last
  chess-display-move-menu
  chess-display-pass
  chess-display-quit
  chess-display-redraw
  chess-display-remote
  chess-display-resign
  chess-display-restore-board
  chess-display-retract
  chess-display-search
  chess-display-search-again
  chess-display-search-backward
  chess-display-search-delete
  chess-display-search-forward
  chess-display-search-key
  chess-display-select-piece
  chess-display-send-board
  chess-display-set-from-fen
  chess-display-set-piece
  chess-display-shuffle
  chess-display-undo
  chess-display-yank-board
  chess-ics
  chess-images-decrease-size
  chess-images-increase-size
  chess-images-set-directory
  chess-input-shortcut
  chess-input-shortcut-delete
  chess-link
  chess-pgn-complete-move
  chess-pgn-insert-and-show-position
  chess-pgn-mode
  chess-pgn-mouse-show-position
  chess-pgn-read
  chess-pgn-show-position
  chess-plain-customize
  chess-polyglot-book-close
  chess-puzzle
  chess-session
  chess-tutorial
  )

;;}}}
(provide 'emacspeak-chess)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
