"""Cooperative machine lease for local native jobs; no credential operations."""
import argparse,fcntl,json,os,signal,subprocess,sys
from pathlib import Path

def run(lock_file,command):
    if not command:raise ValueError('A command is required')
    with Path(lock_file).open('rb') as lease:
        try:fcntl.flock(lease,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            print('Shared native lease busy; no child started.',file=sys.stderr);return 75
        child=None
        try:
            print('Shared native lease acquired.',file=sys.stderr,flush=True)
            env=dict(os.environ);env['JABLAB_NATIVE_LEASE_FD']=str(lease.fileno())
            child=subprocess.Popen(command,start_new_session=True,env=env,pass_fds=(lease.fileno(),))
            try:return child.wait()
            except KeyboardInterrupt:
                os.killpg(child.pid,signal.SIGTERM);return child.wait()
        finally:
            if child is not None and child.poll() is None:
                os.killpg(child.pid,signal.SIGTERM)
                try:child.wait(timeout=10)
                except subprocess.TimeoutExpired:os.killpg(child.pid,signal.SIGKILL);child.wait()
            fcntl.flock(lease,fcntl.LOCK_UN)
            print('Shared native lease released.',file=sys.stderr,flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--lock-file',required=True,type=Path);p.add_argument('command',nargs=argparse.REMAINDER);a=p.parse_args();cmd=a.command[1:] if a.command[:1]==['--'] else a.command
    try:raise SystemExit(run(a.lock_file,cmd))
    except (OSError,ValueError) as e:print(type(e).__name__+': '+str(e),file=sys.stderr);raise SystemExit(2)
