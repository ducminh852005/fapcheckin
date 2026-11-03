import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const files=fs.readdirSync(path.join(root,'firebase/functions/test')).filter(x=>x.endsWith('.test.js')).map(x=>path.join(root,'firebase/functions/test',x));
const summary=[];
for(let run=1;run<=3;run++){
 const r=spawnSync(process.execPath,['--test',...files],{encoding:'utf8',cwd:root});
 fs.writeFileSync(path.join(import.meta.dirname,'results', 'functions-run-'+run+'.tap'),r.stdout+r.stderr);
 const read=k=>Number(r.stdout.match(new RegExp('# '+k+' (\\d+)'))?.[1]||0);
 summary.push({run,exitCode:r.status,pass:read('pass'),fail:read('fail'),skipped:read('skipped')});
}
fs.writeFileSync(path.join(import.meta.dirname,'results','regression-summary.json'),JSON.stringify({scope:'Node unit/regression, NOT Android E2E',runs:summary},null,2));
console.log(summary);if(summary.some(x=>x.exitCode!==0))process.exitCode=1;
