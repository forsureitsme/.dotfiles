import { Readable } from 'node:stream';
import { createWriteStream, existsSync } from 'node:fs';
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

try {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);

    const profilePage = new URL('https://trackmania.exchange/usershow/51154');
    const html = await fetch(profilePage).then(r => r.text());
    
    const regex = /profile-mapfeature[^]*data-attrs="({[^]+})"/;
    const attrs = html.match(regex)[1].replace(/&quot;/g, '"');
    const { id: mapId } = JSON.parse(attrs);
    
    const manifestFilePath = '/../assets/wallpaper.json';
    let manifest;
    if (existsSync(__dirname + manifestFilePath)) {
        manifest = (await import(__dirname + manifestFilePath, { with: { type: 'json' } })).default;
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
