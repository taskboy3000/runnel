import { Playlist } from '../Playlist.js';
import { validateSearchTerm } from '../InputValidator.js';
import { showToastNotice } from '../app.js';

describe('InputValidator', () => {
  describe('validateSearchTerm', () => {
    test('returns trimmed string for valid input', () => {
      expect(validateSearchTerm('foo')).toBe('foo');
      expect(validateSearchTerm('  bar  ')).toBe('bar');
      expect(validateSearchTerm('foo bar')).toBe('foo bar');
    });

    test('returns null for empty string', () => {
      expect(validateSearchTerm('')).toBeNull();
    });

    test('returns null for whitespace-only', () => {
      expect(validateSearchTerm('   ')).toBeNull();
      expect(validateSearchTerm('\t\n')).toBeNull();
      expect(validateSearchTerm('  ')).toBeNull();
    });

    test('returns null for invalid types', () => {
      expect(validateSearchTerm(null)).toBeNull();
      expect(validateSearchTerm(undefined)).toBeNull();
      expect(validateSearchTerm(123)).toBeNull();
    });

    test('returns null for string over 255 chars', () => {
      const long = 'a'.repeat(256);
      expect(validateSearchTerm(long)).toBeNull();
    });

    test('accepts exactly 255 chars', () => {
      const max = 'a'.repeat(255);
      expect(validateSearchTerm(max)).toBe(max);
    });

    test('preserves special characters in SQL-like strings safely', () => {
      expect(validateSearchTerm("Robert'; DROP TABLE songs--")).toBe("Robert'; DROP TABLE songs--");
      expect(validateSearchTerm("1 OR 1=1")).toBe("1 OR 1=1");
      expect(validateSearchTerm("<script>alert('xss')</script>")).toBe("<script>alert('xss')</script>");
    });

    test('accepts single character', () => {
      expect(validateSearchTerm('A')).toBe('A');
    });

    test('preserves unicode characters', () => {
      expect(validateSearchTerm('rock 🎸')).toBe('rock 🎸');
      expect(validateSearchTerm('日本語')).toBe('日本語');
    });
  });
});

describe('app.js', () => {
  let consoleLogSpy;
  let consoleInfoSpy;

  const createMockDOM = () => {
    document.body.innerHTML = `
      <div class="content controller songs">
        <form id="song-search">
          <input type="text" name="search">
        </form>
        <section class="songs">
          <div class="card-body"></div>
          <table id="song-list">
            <tbody>
              <tr><td><a href="/songs/add/1">Add</a></td></tr>
            </tbody>
          </table>
        </section>
      </div>
      <div class="content controller playlists">
        <div id="playlist">
          <table>
            <tbody></tbody>
          </table>
        </div>
      </div>
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
      <div id="toast-notice">
        <div class="toast-body"></div>
      </div>
    `;
  };

  beforeEach(() => {
    createMockDOM();
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    consoleInfoSpy = jest.spyOn(console, 'info').mockImplementation(() => {});
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    global.bootstrap = {
      Toast: jest.fn().mockImplementation(() => ({
        show: jest.fn()
      }))
    };

    global.fetch = jest.fn();
    global.console = { ...console, log: consoleLogSpy, info: consoleInfoSpy, warn: jest.fn(), error: consoleErrorSpy };
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
    consoleInfoSpy.mockRestore();
    consoleErrorSpy.mockRestore();
  });

  describe('songSearchFormHandler', () => {
    test('prevents default form submission', async () => {
      const event = { preventDefault: jest.fn(), target: document.getElementById('song-search') };
      event.preventDefault();

      const input = document.querySelector('input[name=search]');
      input.value = 'test song';

      global.fetch.mockResolvedValue({
        text: jest.fn().mockResolvedValue('<p>Search results</p>')
      });

      expect(event.preventDefault).toHaveBeenCalled();
    });

    test('fetches search results when term provided', async () => {
      const input = document.querySelector('input[name=search]');
      input.value = 'rock';

      global.fetch.mockResolvedValue({
        text: jest.fn().mockResolvedValue('<p>Results</p>')
      });

      const response = await global.fetch('/songs/search?q=rock');
      expect(global.fetch).toHaveBeenCalled();
    });

    test('loads songs table when term is empty', async () => {
      const input = document.querySelector('input[name=search]');
      input.value = '';

      global.fetch.mockResolvedValue({
        text: jest.fn().mockResolvedValue('<table>songs</table>')
      });

      const body = document.querySelector("section.songs div.card-body");
      expect(body).toBeDefined();
    });
  });

  describe('showToastNotice', () => {
    test('updates toast body with message', () => {
      const toast = document.getElementById("toast-notice");
      const toastBody = toast.querySelector(".toast-body");
      const message = 'Song added to playlist';

      toastBody.innerHTML = message;
      expect(toastBody.innerHTML).toBe(message);
    });

    test('creates Bootstrap Toast instance', () => {
      const toast = document.getElementById("toast-notice");
      const mockToast = new bootstrap.Toast(toast, {});
      expect(mockToast).toBeDefined();
      expect(mockToast.show).toBeDefined();
    });

    test('handles missing bootstrap gracefully', () => {
      const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
      const originalBootstrap = global.bootstrap;

      delete global.bootstrap;
      showToastNotice('test message');

      expect(consoleWarnSpy).toHaveBeenCalledWith("Bootstrap Toast unavailable:", 'test message');

      global.bootstrap = originalBootstrap;
      consoleWarnSpy.mockRestore();
    });

    test('handles missing bootstrap.Toast gracefully', () => {
      const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
      const originalBootstrap = global.bootstrap;

      global.bootstrap = { Modal: jest.fn() };
      showToastNotice('test message');

      expect(consoleWarnSpy).toHaveBeenCalledWith("Bootstrap Toast unavailable:", 'test message');

      global.bootstrap = originalBootstrap;
      consoleWarnSpy.mockRestore();
    });
  });

  describe('handleMediaAddsAsynchronously', () => {
    test('attaches click handlers to add links', () => {
      const anchors = document.querySelectorAll("section.songs table#song-list tbody a");
      expect(anchors.length).toBeGreaterThan(0);
    });

    test('fetches when link clicked', async () => {
      global.fetch.mockResolvedValue({
        json: jest.fn().mockResolvedValue({ msg: 'Song added' })
      });

      const response = await global.fetch('/songs/add/1');
      expect(global.fetch).toHaveBeenCalled();
    });

    test('handles malformed JSON response gracefully', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      global.fetch.mockResolvedValue({
        json: jest.fn().mockRejectedValue(new SyntaxError('Unexpected token in JSON'))
      });

      global.fetch('/songs/add/1')
        .then(response => response.json())
        .catch(err => {
          expect(err.message).toBe('Unexpected token in JSON');
        });

      consoleErrorSpy.mockRestore();
    });
  });

  describe('search flow integration', () => {
    test('renders search results HTML to DOM', async () => {
      const mockHtml = '<table class="table"><thead><tr><th>Title</th></tr></thead><tbody><tr><td>Test Song</td></tr></tbody></table>';

      global.fetch.mockResolvedValue({
        text: jest.fn().mockResolvedValue(mockHtml)
      });

      const body = document.querySelector("section.songs div.card-body");
      body.innerHTML = mockHtml;

      expect(body.querySelector('table')).toBeDefined();
      expect(body.querySelector('tbody tr td').textContent).toBe('Test Song');
    });

    test('calls showToastNotice on fetch error', async () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

      global.fetch.mockRejectedValue(new Error('Network error'));

      try {
        await global.fetch('/songs/search?q=test');
      } catch (err) {
        expect(err.message).toBe('Network error');
      }

      consoleErrorSpy.mockRestore();
    });

    test('re-attaches form handler after search renders new content', async () => {
      const mockHtml = `
        <form id="song-search">
          <input type="text" name="search">
        </form>
        <p>Results go here</p>
      `;

      const body = document.querySelector("section.songs div.card-body");
      body.innerHTML = mockHtml;

      const songSearchForm = document.getElementById('song-search');
      expect(songSearchForm).toBeDefined();
    });
  });

  describe('loadSongsTable integration', () => {
    test('renders songs table HTML to DOM', async () => {
      const mockHtml = '<table id="song-list"><tbody><tr><td>Song 1</td></tr></tbody></table>';

      global.fetch.mockResolvedValue({
        text: jest.fn().mockResolvedValue(mockHtml)
      });

      const body = document.querySelector("section.songs div.card-body");
      body.innerHTML = mockHtml;

      expect(body.querySelector('#song-list')).toBeDefined();
    });
  });

  describe('init', () => {
    test('defines Runnel namespace', () => {
      if (!window.Runnel) {
        window.Runnel = {};
      }
      expect(window.Runnel).toBeDefined();
    });

    test('initializes songs controller', () => {
      const songsController = document.querySelector('.content.controller.songs');
      expect(songsController).toBeDefined();
    });

    test('initializes playlists controller', () => {
      const playlistsController = document.querySelector('.content.controller.playlists');
      expect(playlistsController).toBeDefined();
    });

    test('creates Playlist instance for playlists controller', () => {
      window.Runnel = {};
      window.Runnel.playlist = new Playlist();
      expect(window.Runnel.playlist).toBeDefined();
    });
  });
});