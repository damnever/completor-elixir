# -*- coding: utf-8 -*-

import sys
import re
import json
import logging
import os.path
import functools

import vim
from completor import Completor


pathlib = os.path

logger = logging.getLogger('completor')
cur_dir = pathlib.dirname(pathlib.abspath(__file__))
sense_wrapper_dir = pathlib.join(cur_dir, '../sense_wrapper')
sense_wrapper_cmd = ['mix', 'run', '--no-halt']
if not pathlib.isdir(pathlib.join(sense_wrapper_dir, 'deps')):
    raise RuntimeError('!!! No deps found, run `make` to resolve it!')


def _log(func):
    @functools.wraps(func)
    def _wrapper(*args, **kwargs):
        prefix = ''.join(['elixir.', func.__name__])
        try:
            res = func(*args, **kwargs)
            logger.info('%s: %r', prefix, res)
            return res
        except Exception as e:
            if len(args) == 2 and isinstance(args[1], vim.List):
                args = list(args[1])
            logger.exception('%s(%r, %r)', prefix, args, kwargs)
            # FIXME(damnever): ignore compiling information
            if not isinstance(e, json.decoder.JSONDecodeError):
                raise
    return _wrapper


class Elixir(Completor):
    filetype = 'elixir'
    daemon = True
    trigger = r'(\w{2,}\w*|\.\w*)$'

    _ACTION_MAP = {
        b'doc': 'doc',
        b'complete': 'complete',
        b'definition': 'definition',
    }
    _ENV_DEV = 'dev'
    _ENV_TEST = 'test'

    def __init__(self, *args, **kwargs):
        super(self.__class__, self).__init__(*args, **kwargs)
        self._elixir_ctx = None

    def _find_project_path(self):
        dirs = ['/']
        dirs.extend(pathlib.dirname(self.filename).split(pathlib.sep))
        ndirs = len(dirs)
        mix_path = ''
        for level in range(ndirs, 0, -1):
            cur_dir = pathlib.join(*dirs[:level])
            if pathlib.isfile(pathlib.join(cur_dir, 'mix.exs')):
                mix_path = cur_dir
        return mix_path if mix_path else os.getcwd()

    def _get_elixir_ctx(self):
        _, file = pathlib.split(self.filename)
        env = self._ENV_DEV
        if file == 'test_helper.exs' or file.endswith('_test.exs'):
            env = self._ENV_TEST

        if self._elixir_ctx is None:
            self._elixir_ctx = {
                'env': env,
                'cwd': self._find_project_path(),
            }
            return self._elixir_ctx

        if env != self._elixir_ctx['env']:
            self._elixir_ctx['env'] = env
            return self._elixir_ctx
        return None

    def get_cmd_info(self, _action):
        return vim.Dictionary(
            cmd=sense_wrapper_cmd,
            cwd=sense_wrapper_dir,
            ftype=self.filetype,
            is_daemon=self.daemon,
            is_sync=self.sync,
        )

    @_log
    def prepare_request(self, action):
        action = self._ACTION_MAP.get(action)
        if not action:
            return ''

        line, _ = self.cursor
        col = len(self.input_data) + 1
        code = '\n'.join(vim.current.buffer[:])

        return json.dumps({
            'type': action,
            'ctx': self._get_elixir_ctx(),
            'code': code,
            'line': line,
            'column': col,
        })

    @_log
    def on_complete(self, items):
        return self._load_data_from(items, [])

    @_log
    def on_doc(self, items):
        return [self._load_data_from(items, '')]

    @_log
    def on_definition(self, items):
        loc = self._load_data_from(items)
        if not loc:
            return []
        line = loc.pop('line')
        loc.update({
            'name': 'elixir',
            'lnum': line,
            'col': 3,  # FIXME(damnever)
        })
        return [loc]

    def _load_data_from(self, items, default=None):
        raw = items[-1] # FIXME(damnever): ignore compiling information
        if not raw:
            logger.warn('no response data found')
            return None

        data = json.loads(raw)
        errmsg = data.get('error', None)
        if errmsg is not None:
            logger.warn('error response: %r', errmsg)
            return None

        return data.get('data', default)
