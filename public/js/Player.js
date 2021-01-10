export class Player {
    constructor () {
        this.playlist = [];
        this.playerNodeName = 'audioPlayer';
        this.playerControlsNodeName = 'player-controls';
        this.currentSongNodeName = 'current-song';
        this.loopControlNodeName = 'player-control-loop';
        this.progressBarNodeName = 'progress-bar';
        
        this.currentPlaylistIdx = 0;        
        this.lastPBUpdate = 0;
    }

    initialize () {
        
        this.playerNode = document.getElementById(this.playerNodeName);
        this.playerControlsNode = document.getElementById(this.playerControlsNodeName);
        this.loopControlNode = document.getElementById(this.loopControlNodeName);
        this.progressBarNode = document.getElementById(this.progressBarNodeName);
        this.currentSongNode = document.getElementById(this.currentSongNodeName);
       
        this.playerNode.addEventListener('ended', (event) => { this.handleEndedEvent(event) });
        this.playerNode.addEventListener('timeupdate', (event) => { this.handleTimeUpdateEvent(event) });
        
        // Initialize player transport buttons
        document.getElementById('player-control-stop').addEventListener('click', (event) => {
            this.pause();
        });
        
        document.getElementById('player-control-play').addEventListener('click', (event) => {
            this.play();
        });
        
        document.getElementById('player-control-prev').addEventListener('click', (event) => {
            this.pause();
            this.back();
            this.play();
        });
        
        document.getElementById('player-control-next').addEventListener('click', (event) => {
            this.pause();
            this.next();
            this.play();
        });
        
        return new Promise((res, rej) => {
            res(this.getCurrentPlaylist())
        });
    }

    async getCurrentPlaylist () {
        let url = '/playlists/current';
        await fetch(url, {
            headers: {
                'Accept': 'application/json'
            },
        })
            .then((response) => { return response.json() })
            .then((json) => { this.playlist = json});
    }

                           
    handleEndedEvent (event) {
        // When a track ends, play the next one, if there is one to play.
        // Reset to begining if looping is enabled.
        if (this.next()) {
            this.play();
            return true;
        } else if (this.loopControlNode.checked) {
            this.setCurrentSong(0);
            this.play();
            return true;
        }

        console.info('Reached the end of the play list: ' + this.currentPlaylistIdx);
        return false;
    }

    handleTimeUpdateEvent (event) {
        let target = event.target;

        let D = new Date();
        let now = D.getTime();
        if (now - this.lastPBUpdate < 250) {
            return;
        }
        this.lastPBUpdate = now;
          
        this.progressBarNode.setAttribute('aria-valuenow', target.currentTime);
        this.progressBarNode.setAttribute('aria-valuemax', target.duration);
        let width = Math.floor( (target.currentTime / target.duration) * 100);

        this.progressBarNode.querySelector('.progress-bar').style.width = width + '%';
    }

    play () {
        this.playerNode.play();
    }

    pause () {
        this.playerNode.pause();
    }

    // Advance playlist by one, if possible
    next() {
        if (this.currentPlaylistIdx + 1 >= this.playlist.length) {
            console.info('Declining to set the current playlist idx past the end of the list');
            return false;
        }

        this.currentPlaylistIdx += 1;
        this.setCurrentSong(this.currentPlaylistIdx);
        return true;
    }

    // Set the current playlist song to the previous song on the list, if possible
    back() {
        if (this.currentPlaylistIdx - 1 < 0) {
            console.info('Declining to set the current playlist idx past the beginning of the list');
            return false;
        }

        this.currentPlaylistIdx -= 1;
        this.setCurrentSong(this.currentPlaylistIdx);
        return true;
    }

    setCurrentSong(trgIdx) {
        if (this.playlist.length == 0) {
            return;
        }

        if (trgIdx < 0) {
            console.error('Attempt to use a negative index for currentSong');
            return;
        } else if (trgIdx > (this.playlist.length - 1)) {
            console.error('Attempt to see idx past length of playlist: ', trgIdx);
            return;
        }

        this.currentPlaylistIdx = trgIdx;
        let song = this.playlist[ trgIdx ];
        if (!song) {
            console.error('Cannot find a song in playlist at idx ', trgIdx);
            return;
        }

        // console.info('Setting current song to idx ', trgIdx, ' which is ', song.info.title);

        this.playerNode.setAttribute('src', '/media/' + song.info.partialPath);
        this.currentSongNode.innerHTML = song.info.title;

        let trs = document.querySelectorAll('tr.song-details.active');
        for (let tr of trs) {
            tr.classList.remove('active');
        }

        let sel = "tr.song-details[data-idx='" + this.currentPlaylistIdx + "']";
        let trg = document.querySelector(sel);
        if (trg) {
            trg.classList.add("active");
        } else {
            console.warn('Cannot find row for idx ', this.currentPlaylistIdx, sel);
        }
    }

    clearCurrentSong() {
        this.currentPlaylistIdx = 0;
        this.playerNode.setAttribute('src', '');
        this.currentSongNode.innerHTML = '';        
    }
}
