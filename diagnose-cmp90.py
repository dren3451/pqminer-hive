#!/usr/bin/env python3
"""Read-only, bounded flight-sheet diagnostics. No wallet/config/token dump."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
import urllib.request

API = 'http://127.0.0.1:44068/'
EXPECTED_ELF = '03f3d9f7975f7d0e08eb1a82f8dbdfd36d2e14b68264620939f6c339640ebc01'


def clean(value):
    text = str(value)
    text = re.sub(r'(?:github_pat_|ghp_)[A-Za-z0-9_]+', '<redacted>', text)
    return re.sub(r'[A-Za-z][A-Za-z0-9+.-]*://\S+', '<url>', text)


def selected_state(state, elapsed):
    keys = ('index','pci','kernel','temp','mem_temp','fan','power','power_limit',
            'core_clock','mem_clock','util','accepted','rejected','stale')
    gpus = []
    for gpu in state.get('gpus', []):
        item = {k:clean(gpu[k]) if isinstance(gpu.get(k),str) else gpu.get(k) for k in keys}
        item['ths_10s'] = round(gpu.get('hashrate',0)/1e12,3)
        item['ths_60s'] = round(gpu.get('hashrate_60s',0)/1e12,3)
        gpus.append(item)
    pool = state.get('pool') or {}
    return dict(kind='api',elapsed=elapsed,version=clean(state.get('version','unknown')),
                uptime=state.get('uptime'),pool_connected=pool.get('connected'),ping_ms=pool.get('ping_ms'),
                accepted=state.get('accepted'),rejected=state.get('rejected'),
                ths_10s=round(state.get('hashrate',0)/1e12,3),
                ths_60s=round(state.get('hashrate_60s',0)/1e12,3),gpus=gpus)


def emit(value):
    print(json.dumps(value,ensure_ascii=False,sort_keys=True),flush=True)


def files():
    root = Path('/hive/miners/custom/pqminer')
    values = {'kind':'installed'}
    for name in ('.binver','.validated-version'):
        path = root/name
        values[name] = clean(path.read_text()[:100].strip()) if path.is_file() else None
    path = root/'h-manifest.conf'
    if path.is_file():
        match = re.search(r'^CUSTOM_VERSION=(.*)$',path.read_text(),re.MULTILINE)
        values['loader_manifest'] = clean(match[1].strip()) if match else None
    path = root/'pqminer'
    if path.is_file() and path.stat().st_size <= 32_000_000:
        with path.open('rb') as source:
            digest = hashlib.sha256()
            for block in iter(lambda:source.read(65536),b''):
                digest.update(block)
        values['binary_sha256'] = digest.hexdigest()
        values['release_020_binary'] = digest.hexdigest()==EXPECTED_ELF
    emit(values)


def nvidia():
    queries = {
        'gpu':'--query-gpu=index,memory.used,power.draw,temperature.gpu,clocks.sm,clocks.mem,utilization.gpu,utilization.memory',
        'compute_processes':'--query-compute-apps=gpu_uuid,pid,used_gpu_memory',
    }
    for kind,query in queries.items():
        try:
            result = subprocess.run(['/usr/bin/nvidia-smi',query,'--format=csv'],
                                    capture_output=True,text=True,timeout=8)
            emit(dict(kind=kind,exit=result.returncode,rows=clean(result.stdout).splitlines(),
                      error=clean(result.stderr[:300]) if result.returncode else None))
        except (OSError,subprocess.TimeoutExpired) as error:
            emit(dict(kind=kind,error=type(error).__name__))


def log_checks():
    path = Path('/var/log/miner/pqminer/pqminer.log')
    if not path.is_file():
        emit(dict(kind='log',available=False));return
    with path.open('rb') as source:
        source.seek(max(0,path.stat().st_size-262144))
        lines = source.read(262144).decode('utf-8','replace').splitlines()
    ready = [clean(line) for line in lines if 'ready compact self-test ok' in line][-4:]
    errors = {
        'cpu_verification_failed':sum('failed CPU verification' in line for line in lines),
        'cuda_deadline':sum('CUDA' in line and 'timed out' in line for line in lines),
        'selftest_failed':sum('self-test FAILED' in line for line in lines),
        'module_data_unavailable':sum('compact module data is unavailable' in line for line in lines),
    }
    emit(dict(kind='log',available=True,tail_bytes=262144,ready=ready,counts=errors))


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):
        raise OSError('Local API redirect refused')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seconds',type=int,default=180)
    args = parser.parse_args()
    if not 0 <= args.seconds <= 300:
        raise SystemExit('Expected 0..300 seconds')
    files()
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}),NoRedirect)
    start = time.monotonic()
    first = last = None
    sample = 0
    while True:
        target = min(sample*30,args.seconds)
        pause = start+target-time.monotonic()
        if pause>0:
            time.sleep(pause)
        try:
            with opener.open(API,timeout=3) as response:
                raw = response.read(250001)
            if len(raw)>250000:
                raise ValueError('Local API response size')
            result = selected_state(json.loads(raw),round(time.monotonic()-start,1))
            emit(result)
            if first is None:
                first=result
            last=result
        except (OSError,ValueError,TypeError) as error:
            emit(dict(kind='api',elapsed=round(time.monotonic()-start,1),error=type(error).__name__))
        if sample%3==0 or target==args.seconds:
            nvidia()
        if target==args.seconds:
            break
        sample+=1
    log_checks()
    if first is not None and last is not None:
        emit(dict(kind='summary',accepted_delta=(last['accepted'] or 0)-(first['accepted'] or 0),
                  rejected_delta=(last['rejected'] or 0)-(first['rejected'] or 0),
                  final_ths_60s=last['ths_60s'],pool_connected=last['pool_connected'],
                  version=last['version'],samples_seconds=args.seconds))


if __name__=='__main__':
    main()
