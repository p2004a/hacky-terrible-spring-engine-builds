#!/usr/bin/env python3

import urllib.request as request
import json
from jinja2 import Environment, FileSystemLoader, select_autoescape
import os.path
import os
import re
import argparse
from dataclasses import dataclass
from enum import Enum
from typing import List, Optional
from git import Repo, Commit

engine_build_re = re.compile(
    r'engine_(?P<os>linux|windows)64_(?P<version>.*-g(?P<commit>.*))\.7z')
env = Environment(loader=FileSystemLoader(os.path.dirname(__file__)),
                  autoescape=select_autoescape())

@dataclass
class Artifact:
    path: str
    os: str
    version: str
    commit: str


@dataclass
class CommitArtifact:
    commit: Commit
    short_commit: str
    version: Optional[str]
    win_path: Optional[str]
    lin_path: Optional[str]


def get_artifacts(path: str) -> List[Artifact]:
    res = []
    for file in os.listdir(path):
        m = engine_build_re.match(file)
        if m is None:
            continue
        res.append(
            Artifact(file, m.group('os'), m.group('version'), m.group('commit')))
    return res

def get_commits(repo_path: str):
    repo = Repo(repo_path)
    return reversed([repo.commit(c) for c in 
            repo.git.rev_list('origin/BAR105').split()])

def main():
    parser = argparse.ArgumentParser(description='Build site.')
    parser.add_argument('path', type=str, help='Path to dir with artifacts')
    parser.add_argument('repo', type=str, help='Path to repo')
    args = parser.parse_args()

    commit_artifacts = []
    commit_map = dict()
    for commit in get_commits(args.repo):
        for l in range(7, len(str(commit))):
            short_commit = str(commit)[0:l]
            if short_commit not in commit_map:
                ca = CommitArtifact(commit, short_commit, None, None, None)
                commit_artifacts.append(ca)
                commit_map[short_commit] = ca
                break
        else:
            assert(False)

    for a in get_artifacts(args.path):
        assert(a.commit in commit_map)
        ca = commit_map[a.commit]
        assert(ca.version == None or ca.version == a.version)
        ca.version = a.version
        match a.os:
            case 'linux':
                ca.lin_path = a.path
            case 'windows':
                ca.win_path = a.path

    strip_prefix = 0
    while commit_artifacts[strip_prefix].version is None:
        strip_prefix += 1
    output_artifacts = reversed(commit_artifacts[strip_prefix:])

    template = env.get_template('index.html')
    template.stream(commit_artifacts=output_artifacts).dump(os.path.join(args.path, 'index.html'))

if __name__ == '__main__':
    main()
