import { Player } from './Player.js';
import { Template } from './Template.js';

export class Playlist {
    constructor () {
        this.player = new Player();
        this.Template = new Template("tmpl-playlist-row");
    }

    initialize () {
        let self = this;
        new Promise((fncResolve, fncReject) => {
            fncResolve(this.player.initialize())
        },
        ).then(() => {
                this.renderPlaylist()
        }
        ).then(() => {
            this.player.setCurrentSong(0);
        });
        let playlist = document.getElementById('playlist');
        if (playlist) {
            playlist.addEventListener('runnel.playlist.changed', (event) => {
                self.renderPlaylist();
            });
        }
    }

    renderPlaylist() {
        // @todo: template stuff
        let table = document.getElementById('playlist');
        let tbody = table.querySelector('tbody');
        let newTableBody = document.createDocumentFragment();
        
        let cnt = 0;
 
        for (let song of this.player.playlist) {
            let replacements = [
                {
                    target: '.playlist-set-current',
                    value: song.info.title,
                },
                {
                    target: '.playlist-set-current',
                    value: '/media/' + song.info.partialPath,
                    attr: 'href'
                },
                {
                    target: '.song-details',
                    value: cnt,
                    attr: 'data-idx'
                },
                {
                    target: '.playlist-song',
                    value: cnt,
                    attr: 'data-idx'
                },
                {
                    target: '.artist',
                    value: song.info.artist,
                },
                {
                    target: '.album',
                    value: song.info.album,
                },
                {
                    target: '.track',
                    value: song.info.track,
                },
                {
                    target: '.genre',
                    value: song.info.genre,
                },
                {
                    target: '.duration',
                    value: song.info.time_pretty,
                },
                {
                    target: '.playlist-remove-song',
                    value: song.removeSongFromPlaylist,
                    attr: 'href',
                }
                
            ];
            newTableBody.appendChild(this.Template.render(replacements));
            cnt += 1;
        }

        tbody.innerHTML = '';
        tbody.appendChild(newTableBody);
        this.player.setCurrentSong(this.player.currentPlaylistIdx);
        this.handleMediaPlaylistRemoveAsynchronously();
        this.handleMediaPlaylistSetAsCurrent();

    }

    handleMediaPlaylistSetAsCurrent() {
        let self = this;
        let anchors = document.querySelectorAll("#playlist tbody a.playlist-set-current");
        if (anchors) {
            for (let anchor of anchors) {
                anchor.addEventListener('click', (event) => {
                    event.preventDefault();
                    let target = event.target;
                    this.player.pause();
                    self.player.setCurrentSong(target.parentNode.getAttribute("data-idx"));
                    this.player.play();
                });
            }
        }
    }
    
    handleMediaPlaylistRemoveAsynchronously() {
        let self = this;
        let anchors = document.querySelectorAll("#playlist tbody a.playlist-remove-song");
        if (anchors) {
            for (let anchor of anchors) {
                anchor.addEventListener('click', (event) => {
                    event.preventDefault();
                    let target = event.target;

                    while (target.tagName != 'A') {
                        target = target.parentNode;
                    }
                    let url = target.getAttribute("href");
                    
                    fetch(url, {
                        headers: {"Accept": "application/json"}
                    })
                        .then(response => { return response.json() })
                        .then(json => {
                            new Promise ((res, rej) => {
                                res(self.player.getCurrentPlaylist())
                            }).then(() => {
                                if (self.player.playlist.length > 0) {
                                    self.player.setCurrentSong(0);
                                } else {
                                    self.player.clearCurrentSong();
                                }
                                self.renderPlaylist();
                            });
                        });
                });
            }
        }
        
    }

}
