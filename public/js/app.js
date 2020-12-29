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
                handleMediaAddsAsynchronously();

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
                handleMediaAddsAsynchronously();

            });
    }
};

function handleMediaAddsAsynchronously() {
    let anchors = document.querySelectorAll("section.songs table#song-list tbody a");
    if (anchors) {
        for (let anchor of anchors) {
            anchor.addEventListener('click', (event) => {
                event.preventDefault();
                let target = event.target;
                let url = target.getAttribute("href");
                fetch(url, {
                    headers: {"Accept": "application/json"}
                })
                    .then(response => { return response.json() })
                    .then(json => {
                        showToastNotice(json.msg);
                    });
            });
        }
    }
}

function showToastNotice (msg) {
    const toast = document.getElementById("toast-notice");
    toast.querySelector(".toast-body").innerHTML = msg;
    $(toast).toast('show');
}


function init() {
    loadSongsTable();
}

document.addEventListener('DOMContentLoaded', (event) => {
    init();
});
