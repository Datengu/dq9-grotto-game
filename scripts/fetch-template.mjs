// Fetch only the Windows release member of the official export-template ZIP.
// HTTP ranges avoid downloading the other platforms (over a gigabyte).
import {mkdirSync, writeFileSync} from 'node:fs';
import {inflateRawSync} from 'node:zlib';
const url = 'https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz';
async function range(value) {
  const response = await fetch(url, {headers:{Range:`bytes=${value}`}});
  if (response.status !== 206) { await response.body?.cancel(); throw new Error(`Server must support ranges, got ${response.status}`); }
  return {data:Buffer.from(await response.arrayBuffer()), range:response.headers.get('content-range')};
}
const head = await fetch(url, {method:'HEAD'});
if(!head.ok) throw new Error(`Template header request failed: ${head.status}`);
const archiveSize = Number(head.headers.get('content-length'));
if(!Number.isSafeInteger(archiveSize) || archiveSize < 65557) throw new Error('Invalid archive size');
const tail = await range(`${archiveSize-65557}-${archiveSize-1}`);
let end = -1;
for (let i=tail.data.length-22;i>=0;i--) if(tail.data.readUInt32LE(i)===0x06054b50){end=i;break;}
if(end<0) throw new Error('ZIP end record missing');
const length=tail.data.readUInt32LE(end+12), offset=tail.data.readUInt32LE(end+16);
const central=(await range(`${offset}-${offset+length-1}`)).data;
let entry;
for(let p=0;p+46<=central.length;){
  if(central.readUInt32LE(p)!==0x02014b50) throw new Error('Invalid central directory');
  const nameLen=central.readUInt16LE(p+28), extra=central.readUInt16LE(p+30), comment=central.readUInt16LE(p+32);
  const name=central.subarray(p+46,p+46+nameLen).toString();
  if(name.endsWith('/windows_release_x86_64.exe')) entry={name,method:central.readUInt16LE(p+10),size:central.readUInt32LE(p+20),raw:central.readUInt32LE(p+24),offset:central.readUInt32LE(p+42)};
  p+=46+nameLen+extra+comment;
}
if(!entry) throw new Error('Windows template not found');
console.log('Fetching',entry.name,entry.size,'compressed bytes');
const header=(await range(`${entry.offset}-${entry.offset+29}`)).data;
const start=entry.offset+30+header.readUInt16LE(26)+header.readUInt16LE(28);
const compressed=(await range(`${start}-${start+entry.size-1}`)).data;
const executable=entry.method===8?inflateRawSync(compressed):compressed;
if(executable.length!==entry.raw || executable.toString('ascii',0,2)!=='MZ') throw new Error('Invalid executable');
mkdirSync('.tools/templates',{recursive:true});
writeFileSync('.tools/templates/windows_release_x86_64.exe',executable);
for(const name of ['LICENSE.txt','COPYRIGHT.txt']) {
  const response=await fetch(`https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/${name}`);
  if(!response.ok) throw new Error(`License fetch ${response.status}`);
  writeFileSync(`.tools/templates/GODOT-${name}`,await response.text());
}
console.log('Windows release template and licenses ready.');
