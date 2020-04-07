;;; emacspeak-vuiet.el --- Speech-enable VUIET  -*- lexical-binding: t; -*-
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable VUIET An Emacs Interface to vuiet
;;; Keywords: Emacspeak,  Audio Desktop vuiet
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
;;; MERCHANTABILITY or FITNVUIET FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; VUIET ==  Emacs Music Explorer And Player with last.fm integration
;;; This module speech-enables vuiet.

;;; Code:

;;}}}
;;{{{  Required modules

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

;;}}}
;;{{{ Interactive Commands:
(defadvice vuiet-update-mode-line (after emacspeak pre act comp)
  "Provide auditory feedback."
  (dtk-notify-speak (vuiet-playing-track-str)))

(defadvice vuiet-love-track (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (dtk-notify-say "loved strack")))


(defadvice vuiet-unlove-track (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (dtk-notify-say "UnLoved strack")))


(cl-loop
 for f in 
 '(
   vuiet-playing-track-lyrics vuiet-loved-tracks-info
   vuiet-playing-artist-info vuiet-playing-artist-lastfm-page
   vuiet-album-info-search vuiet-artist-info
   vuiet-artist-info-search vuiet-artist-lastfm-page)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (emacspeak-speak-line)))))

(cl-loop
 for f in 
 '(vuiet-disable-scrobbling vuiet-enable-scrobbling)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon
        (if vuiet-scrobble-enabled 'on 'off))
       (dtk-speak (format "Turned %s scrobbling"
                          (if vuiet-scrobble-enabled "on" "off")))))))



;;}}}
;;{{{Additional Commands:

;;; Will be removed once added to vuiet:
(defun vuiet-play-artist-loved-tracks (artist random)
  "Play all the tracks from the user loved tracks filtered by
artist. If RANDOM is t, play the tracks at random, indefinitely. The
user loved tracks list is the one associated with the username given
in the setup of the lastfm.el package."
  (interactive
   (list
    (read-from-minibuffer "Artist:")
    (y-or-n-p "Play random? ")))
  (vuiet-play
   (cl-loop
    for track in 
    (lastfm-user-get-loved-tracks :limit vuiet-loved-tracks-limit)
    when (string-match artist (car track))
    collect track) :random random))


;;}}}

(provide 'emacspeak-vuiet)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}