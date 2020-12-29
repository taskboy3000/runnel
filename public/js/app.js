// app code here
function songSearchFormHandler (event) {
    event.preventDefault();
    let term = document.getElementById('song-search').querySelector('input[name=search]').value;
    if (term) {
        let url = new URL(window.location.href);
        url.pathname = 'songs/search';
        let params = url.searchParams;
        params.set('q', term);
        console.log("Search URL is: " + url);
        
        fetch(url)
            .then(response => { return response.text() })
            .then(content => {
                console.info(content);
                let body = document.querySelector("section.songs div.card-body");
                body.innerHTML = content;
                const songSearchForm = document.getElementById('song-search');
                if (songSearchForm) {
                    songSearchForm.onsubmit = songSearchFormHandler;
                }
            });
    } else {
        return loadSongsTable();
    }
}

function loadSongsTable () {
    let body = document.querySelector("section.songs div.card-body");
    if (body) {
        fetch('/songs/songs_table')
            .then((response) => { return response.text() } )
            .then((content) => {
                body.innerHTML = content;
                const songSearchForm = document.getElementById('song-search');
                if (songSearchForm) {
                    songSearchForm.onsubmit = songSearchFormHandler;
                }
            });
    }
};

function init() {
    loadSongsTable();
}

document.addEventListener('DOMContentLoaded', (event) => {
    init();
});
