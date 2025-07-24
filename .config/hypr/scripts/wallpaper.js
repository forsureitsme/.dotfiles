import { Readable } from 'node:stream';
import { createWriteStream, existsSync } from 'node:fs';
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

try {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);

    const manifestFilePath = '/../assets/wallpaper.json';

    const mapsApi = new URL('https://trackmania.exchange/api/maps')
    mapsApi.search = new URLSearchParams({
        count: 1,
        author: 'ForSureItsMe',
        fields: ['MapId'],
        order1: 6 // Newest Uploaded
    }).toString();

    const data = await fetch(mapsApi).then(r => r.json());

    const mapId = data.Results[0].MapId;

    let manifest;
    if (existsSync(__dirname + manifestFilePath)) {
        manifest = (await import(__dirname + manifestFilePath, { assert: { type: 'json' } })).default;
    }

    if (!mapId || mapId === manifest?.mapId) {
        process.exit();
    }

    const response = await fetch(`https://trackmania.exchange/mapimage/${mapId}/1`);
    const stream = Readable.fromWeb(response.body);
    const wallpaper = createWriteStream(__dirname + '/../assets/wallpaper');
    await stream.pipe(wallpaper);

    await writeFile(__dirname + manifestFilePath, JSON.stringify({ mapId }));
} catch (e) {
    console.log(String(e));
    process.exit();
}
