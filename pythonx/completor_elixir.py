# -*- coding: utf-8 -*-

import sys
import re
import json
import logging
import os.path
import functools

import vim
from completor import Completor


logger = logging.getLogger('completor')
cur_dir = os.path.dirname(os.path.abspath(__file__))
sense_wrapper = os.path.join(cur_dir, '../sense_wrapper/sense_wrapper')
if not os.path.isfile(sense_wrapper):
    sys.exit('sense_wrapper not found, run `make` to build it.')


def _log(func):
    @functools.wraps(func)
    def _wrapper(*args, **kwargs):
        prefix = ''.join(['elixir.', func.__name__])
        try:
            res = func(*args, **kwargs)
            logger.info('%s: %r', prefix, res)
            return res
        except Exception:
            logger.exception(prefix)
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

    def _find_project_path(self, _pathlib=os.path):
        dirs = ['/']
        dirs.extend(_pathlib.dirname(self.filename).split(_pathlib.sep))
        ndirs = len(dirs)
        mix_path = ''
        for level in range(ndirs, 0, -1):
            cur_dir = _pathlib.join(*dirs[:level])
            logger.info('============= %r', cur_dir)
            if _pathlib.isfile(_pathlib.join(cur_dir, 'mix.exs')):
                mix_path = cur_dir
        return mix_path if mix_path else os.getcwd()

    def _get_elixir_ctx(self):
        _, file = os.path.split(self.filename)
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
            cmd=[sense_wrapper],
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
        return json.dumps({
            'type': action,
            'ctx': self._get_elixir_ctx(),
            'code': '\n'.join(vim.current.buffer[:]),
            'line': line,
            'column': col,
        })

    @_log
    def on_complete(self, items):
        data = json.loads(items[0])
        return data.get('data', [])

    @_log
    def on_doc(self, items):
        data = json.loads(items[0])
        doc = data.get('data')
        return [doc] if doc else []

    # TODO(damnever): finish it!
    @_log
    def _on_definition(self, items):
        obj = json.loads(items[0])
        if 'error' in obj:
            return ''
        loc = obj['data']
        return ':'.join(loc['filename'], loc['line'])
