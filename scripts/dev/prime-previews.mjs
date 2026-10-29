// Work around Flutter 3.47.8 returning an empty workspace preview cache at startup.
// Query the documented per-file LSP method through the local DTD; the Flutter
// tool receives its normal update notification and performs a hot reload.
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

async function main() {
  if (typeof WebSocket === 'undefined') {
    throw new Error('The preview startup workaround requires Node.js 22 or newer.');
  }
  const project = process.argv[2];
  const connectionFile = resolve(project, '.widget_preview/lib/src/dtd/dtd_connection_info.dart');
  const source = await readFile(connectionFile, 'utf8');
  const uri = source.match(/kWidgetPreviewDtdUri\s*=\s*'([^']+)'/u)?.[1];
  if (!uri || !['127.0.0.1', 'localhost', '::1'].includes(new URL(uri).hostname)) {
    throw new Error('The SDK did not provide a local DTD connection.');
  }
  const socket = new WebSocket(uri);
  try {
    const response = await new Promise((accept, reject) => {
      const timer = setTimeout(() => reject(new Error('Preview discovery timed out.')), 15000);
      const finish = (callback, value) => {
        clearTimeout(timer);
        callback(value);
      };
      socket.addEventListener('error', () => finish(reject, new Error('Cannot connect to the preview DTD.')));
      socket.addEventListener('open', () => socket.send(JSON.stringify({
        jsonrpc: '2.0',
        id: 1,
        method: 'Lsp.dart/textDocument/getFlutterWidgetPreviews',
        params: {uri: pathToFileURL(resolve(project, 'lib/previews.dart')).href},
      })));
      socket.addEventListener('message', (event) => {
        const message = JSON.parse(event.data);
        if (message.id !== 1) return;
        if (message.error) {
          finish(reject, new Error(message.error.message));
        } else {
          finish(accept, message.result);
        }
      });
    });
    const count = response?.result?.previews?.length ?? 0;
    if (count === 0) throw new Error('No previews were discovered in lib/previews.dart.');
    console.log(`AppUI: loaded ${count} Widget Previews.`);
  } finally {
    socket.close();
  }
}

main().catch((error) => {
  console.error(`AppUI preview discovery: ${error.message}`);
  process.exitCode = 1;
});
