const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const templatePath = path.join(__dirname, '..', 'index.html');

function readTemplate() {
  return fs.readFileSync(templatePath, 'utf8');
}

test('check-in template contains only complete server scriptlets', () => {
  const html = readTemplate();
  const scriptlets = [...html.matchAll(/<\?([\s\S]*?)\?>/g)];
  const htmlWithoutScriptlets = html.replace(/<\?[\s\S]*?\?>/g, '');

  assert.equal(scriptlets.length, 6);
  assert.match(scriptlets[0][1], /^=\s*googleClientId\s*$/);
  assert.match(scriptlets[1][1], /^=\s*googleLoginUri\s*$/);
  assert.match(scriptlets[2][1], /^=\s*googleLoginNonce\s*$/);
  assert.match(scriptlets[3][1], /^=\s*token\s*$/);
  assert.match(scriptlets[4][1], /^!=/);
  assert.match(scriptlets[5][1], /^!=/);
  assert.equal(htmlWithoutScriptlets.includes('<?'), false);
  assert.equal(htmlWithoutScriptlets.includes('?>'), false);
});

test('rendered inline JavaScript is syntactically valid and safely embeds the token', () => {
  const dangerousToken = 'quote" apostrophe\' newline\n closing-script</script>';
  const html = readTemplate();
  const scriptlet = html.match(/<\?!=([\s\S]*?)\?>/);

  assert.ok(scriptlet);
  const expression = scriptlet[1].trim();
  const renderToken = new Function('token', `return (${expression});`);
  const rendered = html
    .replace('<?= googleClientId ?>', 'test-client.apps.googleusercontent.com')
    .replace('<?= googleLoginUri ?>', 'https://example.test/login')
    .replace('<?= googleLoginNonce ?>', 'test-nonce')
    .replace('<?= token ?>', 'test-state')
    .replace(scriptlet[0], renderToken(dangerousToken))
    .replace(/<\?!=\s*JSON\.stringify\(typeof oauthResult[\s\S]*?\?>/, 'null');
  const inlineScripts = [...rendered.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
    .map((match) => match[1])
    .filter((source) => source.trim());

  assert.equal(inlineScripts.length, 1);
  assert.equal(rendered.includes('</script>'), true);
  assert.equal(rendered.includes('closing-script</script>'), false);
  assert.doesNotThrow(() => new vm.Script(inlineScripts[0]));
});
