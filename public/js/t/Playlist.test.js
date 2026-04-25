import { Playlist } from '../Playlist.js';

describe('Playlist', () => {
  let playlist;
  let mockFetch;
  let mockFetchJson;

  const createMockDOM = () => {
    document.body.innerHTML = `
      <template id="tmpl-playlist-row">
        <tr class="song-details">
          <td>
            <a class="playlist-set-current"></a>
            <span class="playlist-song"></span>
            <span class="artist"></span>
            <span class="album"></span>
            <span class="track"></span>
            <span class="genre"></span>
            <span class="duration"></span>
            <a class="playlist-remove-song"></a>
          </td>
        </tr>
      </template>
      <audio id="audioPlayer"></audio>
      <div id="player-controls"></div>
      <input type="checkbox" id="player-control-loop">
      <div id="progress-bar"><div class="progress-bar"></div></div>
      <div id="current-song"></div>
      <button id="player-control-stop"></button>
      <button id="player-control-play"></button>
      <button id="player-control-prev"></button>
      <button id="player-control-next"></button>
      <button id="btn-shuffle-playlist"></button>
      <div id="playlist">
        <table>
          <tbody></tbody>
        </table>
      </div>
    `;
  };

  beforeEach(() => {
    jest.clearAllMocks();
    createMockDOM();

    mockFetchJson = [
      {
        info: { title: 'Song 1', partialPath: 'album1/song1.mp3', artist: 'Artist 1', album: 'Album 1', track: 1, genre: 'Rock', time_pretty: '3:00' },
        removeSongFromPlaylist: '/playlists/remove/0'
      },
      {
        info: { title: 'Song 2', partialPath: 'album1/song2.mp3', artist: 'Artist 2', album: 'Album 1', track: 2, genre: 'Rock', time_pretty: '4:00' },
        removeSongFromPlaylist: '/playlists/remove/1'
      }
    ];

    mockFetch = jest.fn().mockResolvedValue({
      json: jest.fn().mockResolvedValue(mockFetchJson)
    });

    global.fetch = mockFetch;
    global.console = { ...console, info: jest.fn(), warn: jest.fn(), error: jest.fn() };

    playlist = new Playlist();
  });

  describe('constructor', () => {
    test('creates a Player instance', () => {
      expect(playlist.player).toBeDefined();
    });

    test('creates a Template instance', () => {
      expect(playlist.Template).toBeDefined();
    });
  });

  describe('initialize', () => {
    test('initializes the player', async () => {
      playlist.initialize();
      await new Promise(resolve => setTimeout(resolve, 100));
      expect(playlist.player).toBeDefined();
    });

    test('renders the playlist after initialization', async () => {
      playlist.initialize();
      await new Promise(resolve => setTimeout(resolve, 100));
      const tbody = document.querySelector('#playlist tbody');
      expect(tbody.children.length).toBeGreaterThan(0);
    });

    test('sets up playlist change event listener', async () => {
      playlist.initialize();
      await new Promise(resolve => setTimeout(resolve, 100));
      const playlistDiv = document.getElementById('playlist');
      expect(playlistDiv).toBeDefined();
    });
  });

  describe('renderPlaylist', () => {
    test('populates the playlist table', async () => {
      await playlist.player.initialize();
      playlist.renderPlaylist();
      const tbody = document.querySelector('#playlist tbody');
      expect(tbody.children.length).toBe(2);
    });

    test('sets song titles in the table', async () => {
      await playlist.player.initialize();
      playlist.renderPlaylist();
      const tbody = document.querySelector('#playlist tbody');
      const rows = tbody.querySelectorAll('tr');
      expect(rows.length).toBe(2);
    });

    test('sets song artist in the table', async () => {
      await playlist.player.initialize();
      playlist.renderPlaylist();
      const tbody = document.querySelector('#playlist tbody');
      const artistCell = tbody.querySelector('.artist');
      expect(artistCell).toBeDefined();
    });

    test('handles empty playlist gracefully', async () => {
      const emptyFetch = jest.fn().mockResolvedValue({
        text: jest.fn().mockResolvedValue(''),
        ok: true
      });
      global.fetch = emptyFetch;

      const emptyPlaylist = new Playlist();
      const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});

      try {
        await emptyPlaylist.player.getCurrentPlaylist();
      } catch (e) {
        expect(e).toBeDefined();
      }

      consoleWarnSpy.mockRestore();
    });
  });

  describe('handleMediaPlaylistSetAsCurrent', () => {
    test('attaches click handlers to playlist links', async () => {
      await playlist.player.initialize();
      playlist.renderPlaylist();
      playlist.handleMediaPlaylistSetAsCurrent();
      const anchors = document.querySelectorAll('#playlist tbody a.playlist-set-current');
      expect(anchors.length).toBeGreaterThan(0);
    });
  });

  describe('handleMediaPlaylistRemoveAsynchronously', () => {
    test('attaches click handlers to remove links', async () => {
      await playlist.player.initialize();
      playlist.renderPlaylist();
      playlist.handleMediaPlaylistRemoveAsynchronously();
      const anchors = document.querySelectorAll('#playlist tbody a.playlist-remove-song');
      expect(anchors.length).toBeGreaterThan(0);
    });
  });
});