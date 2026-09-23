const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const templatePath = path.join(__dirname, '..', 'index.html');

function readTemplate() {
  return fs.readFileSync(templatePath, 'utf8');
}

test('check-in template contains one complete server scriptlet', () => {
  const html = readTemplate();
  const scriptlets = [...html.matchAll(/<\?([\s\S]*?)\?>/g)];
  const htmlWithoutScriptlets = html.replace(/<\?[\s\S]*?\?>/g, '');

  assert.equal(scriptlets.length, 1);
  assert.equal(htmlWithoutScriptlets.includes('<?'), false);
  assert.equal(htmlWithoutScriptlets.includes('?>'), false);
});

test('rendered inline JavaScript is syntactically valid and safely embeds the token', () => {
  const dangerousToken = 'quote" apostrophe\' newline\n closing-script</script>';
  const html = readTemplate();
  const scriptlet = html.match(/<\?([\s\S]*?)\?>/);

  assert.ok(scriptlet);
  assert.equal(scriptlet[1].trimStart().startsWith('!='), true);

  const expression = scriptlet[1].trim().slice(2).trim();
  const renderToken = new Function('token', `return (${expression});`);
  const rendered = html.replace(scriptlet[0], renderToken(dangerousToken));
  const inlineScripts = [...rendered.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
    .map((match) => match[1])
    .filter((source) => source.trim());

  assert.equal(inlineScripts.length, 1);
  assert.equal(rendered.includes('</script>'), true);
  assert.equal(rendered.includes('closing-script</script>'), false);
  assert.doesNotThrow(() => new vm.Script(inlineScripts[0]));
});
