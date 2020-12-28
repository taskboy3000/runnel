// app code here
function songSearchFormHandler (event) {
    event.preventDefault();
    let term = document.getElementById('song-search').querySelector('input[name=search]').value.toLowerCase();

    if (term) {
        let s = new Date();
        let start = s.getTime();

        console.log("begin filter");
        for (let tr of document.querySelectorAll("#song-list tbody tr")) {
            let found = false;
            for (let td of tr.children) {
                if (td.innerText.toLowerCase().indexOf(term) > -1) {
                    found=true
                }
            }

            if (found) {
                tr.classList.remove('d-none');
            } else {
                tr.classList.add('d-none');
            }
        }
        let e = new Date();
        let end = e.getTime();
        console.log("end filter.  Took: " + ((end - start)/1000.0) + " seconds");
        
    } else {
        document.querySelectorAll("#song-search tbody .d-none").forEach((e) => { e.classList.remove('d-none') });
    }
    return false;
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
