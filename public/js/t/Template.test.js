import { Template } from '../Template.js';

describe('Template', () => {
  let template;
  let consoleErrorSpy;
  let consoleWarnSpy;

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
    `;
  };

  beforeEach(() => {
    createMockDOM();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
    consoleWarnSpy.mockRestore();
  });

  describe('constructor', () => {
    test('initializes with template node ID', () => {
      const tmpl = new Template('tmpl-playlist-row');
      expect(tmpl.templateNode).toBeDefined();
    });

    test('returns null templateNode for missing template', () => {
      const tmpl = new Template('nonexistent-template');
      expect(tmpl.templateNode).toBeNull();
    });
  });

  describe('render', () => {
    test('renders template with replacements', () => {
      const tmpl = new Template('tmpl-playlist-row');
      const replacements = [
        { target: '.playlist-set-current', value: 'Test Song' },
        { target: '.artist', value: 'Test Artist' },
        { target: '.album', value: 'Test Album' }
      ];

      const result = tmpl.render(replacements);
      expect(result).toBeInstanceOf(DocumentFragment);
    });

    test('sets innerHTML when no attr specified', () => {
      const tmpl = new Template('tmpl-playlist-row');
      const replacements = [
        { target: '.artist', value: 'My Artist' }
      ];

      const result = tmpl.render(replacements);
      const tr = result.querySelector('tr');
      const artistSpan = tr.querySelector('.artist');
      expect(artistSpan.innerHTML).toBe('My Artist');
    });

    test('sets text content when type is text', () => {
      const tmpl = new Template('tmpl-playlist-row');
      const replacements = [
        { target: '.artist', value: 'My Artist', type: 'text' }
      ];

      const result = tmpl.render(replacements);
      const tr = result.querySelector('tr');
      const artistSpan = tr.querySelector('.artist');
      expect(artistSpan.innerText).toBe('My Artist');
    });

    test('sets attribute when attr specified', () => {
      const tmpl = new Template('tmpl-playlist-row');
      const replacements = [
        { target: '.playlist-set-current', value: '/media/song.mp3', attr: 'href' }
      ];

      const result = tmpl.render(replacements);
      const tr = result.querySelector('tr');
      const anchor = tr.querySelector('.playlist-set-current');
      expect(anchor.getAttribute('href')).toBe('/media/song.mp3');
    });

    test('handles nonexistent target gracefully', () => {
      const tmpl = new Template('tmpl-playlist-row');
      const replacements = [
        { target: '.nonexistent', value: 'test' }
      ];

      const result = tmpl.render(replacements);
      expect(result).toBeInstanceOf(DocumentFragment);
    });

    test('renders with empty replacement list', () => {
      const tmpl = new Template('tmpl-playlist-row');
      const replacements = [];

      const result = tmpl.render(replacements);
      expect(result).toBeInstanceOf(DocumentFragment);
      const tr = result.querySelector('tr');
      expect(tr).toBeDefined();
    });

    test('renders with no replacements parameter', () => {
      const tmpl = new Template('tmpl-playlist-row');

      expect(() => tmpl.render()).toThrow('replacementList is not iterable');
    });
  });
});