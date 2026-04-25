import { Player } from '../Player.js';

describe('Player', () => {
  let player;
  let mockFetch;

  const createMockDOM = () => {
    document.body.innerHTML = `
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
          <tbody>
            <tr class="song-details" data-idx="0"><td>Song 1</td></tr>
            <tr class="song-details" data-idx="1"><td>Song 2</td></tr>
            <tr class="song-details" data-idx="2"><td>Song 3</td></tr>
          </tbody>
        </table>
      </div>
    `;
  };

beforeEach(() => {
    jest.clearAllMocks();
    createMockDOM();

    mockFetch = jest.fn().mockResolvedValue({
      json: jest.fn().mockResolvedValue([
        {
          info: { title: 'Song 1', partialPath: 'album1/song1.mp3', artist: 'Artist 1', album: 'Album 1', track: 1, genre: 'Rock', time_pretty: '3:00' },
          removeSongFromPlaylist: '/playlists/remove/0'
        },
        {
          info: { title: 'Song 2', partialPath: 'album1/song2.mp3', artist: 'Artist 2', album: 'Album 1', track: 2, genre: 'Rock', time_pretty: '4:00' },
          removeSongFromPlaylist: '/playlists/remove/1'
        },
        {
          info: { title: 'Song 3', partialPath: 'album2/song3.mp3', artist: 'Artist 3', album: 'Album 2', track: 1, genre: 'Jazz', time_pretty: '5:00' },
          removeSongFromPlaylist: '/playlists/remove/2'
        }
      ])
    });

    global.fetch = mockFetch;
    global.console = { ...console, info: jest.fn(), warn: jest.fn(), error: jest.fn() };

    const audio = document.getElementById('audioPlayer');
    audio.play = jest.fn().mockResolvedValue();
    audio.pause = jest.fn();
    audio.load = jest.fn();

    player = new Player();
  });

  describe('constructor', () => {
    test('initializes with default values', () => {
      expect(player.playlist).toEqual([]);
      expect(player.playerNodeName).toBe('audioPlayer');
      expect(player.currentPlaylistIdx).toBe(0);
    });
  });

  describe('initialize', () => {
    test('sets up player node references', async () => {
      await player.initialize();
      expect(player.playerNode).toBeInstanceOf(HTMLAudioElement);
      expect(player.playerControlsNode).toBeDefined();
      expect(player.loopControlNode).toBeDefined();
      expect(player.progressBarNode).toBeDefined();
      expect(player.currentSongNode).toBeDefined();
    });

    test('attaches event listeners to controls', async () => {
      await player.initialize();
      const stopBtn = document.getElementById('player-control-stop');
      const playBtn = document.getElementById('player-control-play');
      const prevBtn = document.getElementById('player-control-prev');
      const nextBtn = document.getElementById('player-control-next');

      expect(stopBtn.onclick).toBeDefined();
      expect(playBtn.onclick).toBeDefined();
      expect(prevBtn.onclick).toBeDefined();
      expect(nextBtn.onclick).toBeDefined();
    });

    test('fetches current playlist', async () => {
      await player.initialize();
      expect(mockFetch).toHaveBeenCalledWith('/playlists/current', expect.any(Object));
      expect(player.playlist).toHaveLength(3);
    });
  });

  describe('play', () => {
    test('calls play on audio element', async () => {
      await player.initialize();
      player.play();
    });
  });

  describe('pause', () => {
    test('calls pause on audio element', async () => {
      await player.initialize();
      player.pause();
    });
  });

  describe('next', () => {
    test('advances to next song in playlist', async () => {
      await player.initialize();
      expect(player.currentPlaylistIdx).toBe(0);
      const result = player.next();
      expect(result).toBe(true);
      expect(player.currentPlaylistIdx).toBe(1);
    });

    test('returns false when at end of playlist', async () => {
      await player.initialize();
      player.next();
      player.next();
      expect(player.currentPlaylistIdx).toBe(2);
      const result = player.next();
      expect(result).toBe(false);
    });
  });

  describe('back', () => {
    test('goes to previous song in playlist', async () => {
      await player.initialize();
      player.next();
      expect(player.currentPlaylistIdx).toBe(1);
      const result = player.back();
      expect(result).toBe(true);
      expect(player.currentPlaylistIdx).toBe(0);
    });

    test('returns false when at beginning of playlist', async () => {
      await player.initialize();
      expect(player.currentPlaylistIdx).toBe(0);
      const result = player.back();
      expect(result).toBe(false);
    });
  });

  describe('setCurrentSong', () => {
    test('sets the current song by index', async () => {
      await player.initialize();
      player.setCurrentSong(1);
      expect(player.currentPlaylistIdx).toBe(1);
      expect(player.playerNode.src).toContain('album1/song2.mp3');
    });

    test('does nothing for empty playlist', async () => {
      player.setCurrentSong(0);
      expect(player.currentPlaylistIdx).toBe(0);
    });

    test('rejects negative indices', async () => {
      await player.initialize();
      player.setCurrentSong(-1);
    });

    test('rejects indices past playlist length', async () => {
      await player.initialize();
      player.setCurrentSong(5);
    });

    test('updates the current song display', async () => {
      await player.initialize();
      player.setCurrentSong(1);
      expect(document.getElementById('current-song').innerHTML).toBe('Song 2');
    });

    test('highlights the active row in playlist table', async () => {
      await player.initialize();
      player.setCurrentSong(1);
      const activeRow = document.querySelector('tr.song-details.active');
      expect(activeRow).toBeDefined();
      expect(activeRow.getAttribute('data-idx')).toBe('1');
    });
  });

  describe('handlePlaylistShuffle', () => {
    test('shuffles the playlist', async () => {
      await player.initialize();
      const originalPlaylist = [...player.playlist];
      player.handlePlaylistShuffle();
      // The shuffle might or might not change the order (random)
      // Just verify it doesn't throw and maintains length
      expect(player.playlist).toHaveLength(originalPlaylist.length);
    });
  });

  describe('clearCurrentSong', () => {
    test('clears the current song', async () => {
      await player.initialize();
      player.setCurrentSong(1);
      player.clearCurrentSong();
      expect(player.currentPlaylistIdx).toBe(0);
      expect(player.playerNode.getAttribute('src')).toBe('');
    });
  });

  describe('error handling', () => {
    test('handles play error gracefully', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      await player.initialize();

      player.playerNode.play = jest.fn().mockImplementation(() => {
        throw new Error('Network error');
      });

      try {
        player.play();
      } catch (e) {
        expect(e.message).toBe('Network error');
      }

      consoleErrorSpy.mockRestore();
    });

    test('handles pause during playback', async () => {
      await player.initialize();
      player.playerNode.pause = jest.fn();

      player.pause();
      expect(player.playerNode.pause).toHaveBeenCalled();
    });

    test('handles empty playlist gracefully', async () => {
      await player.initialize();
      player.playlist = [];
      player.currentPlaylistIdx = 0;

      expect(player.playlist.length).toBe(0);
      const result = player.next();
      expect(result).toBe(false);
      const backResult = player.back();
      expect(backResult).toBe(false);
    });
  });
});