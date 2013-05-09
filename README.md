Unsatisfied with my audiobook creation options, I created this script to quickly and cleanly convert all mp3s in a directory into an iTunes audiobook, complete with chapters, tags, and artwork.

# Requirements
* Ruby + ruby-mp3info, wriggle
* Sox, Faac, mp4v2

## Mac
* gem install ruby-mp3info wriggle
* brew install sox faac mp4v2

# Usage

    ruby MakeBookz.rb source_dir [target_dir]

Tags will be set, and any jpeg or png in the source directory will be embedded as artwork. Any image in same directory as MakeBookz.rb will be used as default cover art. Quality is 64kbps/32khz.

## Known Limitations
* Faac's display can inaccurately report quality settings and sometimes ETA.
* No manual sorting. Filenames must reflect chapter order.
* Mp3s can't be of mixed frequency.

# TODO
* User selected bitrate and sample rate
* Optionally divide chapters by time interval
* Extract artwork from MP3s
* Proper command-line output, input
