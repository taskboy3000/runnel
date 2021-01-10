# Runnel, a brain-dead MP3 streamer

## Introduction

(TODO: philosophy, expected use cases, mp3 directory layout, how information is scaped)
        
## System Requirements  

* Modern Mac OS X or Linux
* perl 5.20 or better

I recommend using plenv (https://github.com/tokuhirom/plenv) for
this project, but it is not required.
        
## Installation

* git clone https://github.com/taskboy3000/runnel.git
* cd runnel
* cpanm --installdeps .
* cp runnel-dist.yml runnel.yml
* edit runnel.yml, point mp3BaseDirectory to the root of your mp3 collection
* run script/runnel daemon -l http://*:3000

## Thank You

This project is built on the excellent MVC framework, Mojolicious (https://mojolicious.org/).
    
## Copyright

jQuery 3:
    Author: https://jquery.com/
    Licenses:
        - MIT License (https://jquery.org/license)

Bootstrap 4.5:
    Author: https://getbootstrap.com/
    Licenses:
        - MIT License (https://github.com/twbs/bootstrap/blob/main/LICENSE)

Font Awesome (Free) v5.15.1:
    Author: https://fontawesome.com
    Licenses:
        - Icons are CC BY 4.0
        - Fonts are SIL OFL 1.1
        - Code is MIT License

sortable:
    Author: https://github.com/tofsjonas/sortable
    Licenses:
        - Unlicense

All other code:
    Author: Joe Johnston <jjohn@taskboy.com>
    Licenses:
        - CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/legalcode)
