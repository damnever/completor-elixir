# -*- coding: utf-8 -*-

import json
import logging
import os.path
import functools
import re
import subprocess

import vim
from completor import Completor


pathlib = os.path

logger = logging.getLogger('completor')
cur_dir = pathlib.dirname(pathlib.abspath(__file__))
sense_wrapper_dir = pathlib.join(cur_dir, '../sense_wrapper')
# FIXME: ...
sense_wrapper_cmd = 'sh -c "cd {} && MIX_ENV=prod mix run --no-compile"'
sense_wrapper_cmd = sense_wrapper_cmd.format(sense_wrapper_dir)
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
            raise
    return _wrapper


class Elixir(Completor):
    filetype = 'elixir'
    daemon = True
    trigger = r'([0-9a-zA-Z?!_]{2,}[0-9a-zA-Z?!_]*|\.\w*)$'

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
        data = self._load_data_from(items, {})
        suggestions = data.get('suggestions', None)
        if not suggestions:
            return []
        module = data.get('module', '')
        input_data = self.input_data.split()[-1]
        if '.' in input_data or module == '':
            return suggestions

        if module.startswith(':'):
            module = module[1:]

        for sugg in suggestions:
            if sugg['kind'] != 'func':
                continue
            word = ''.join([module, sugg['word']])
            sugg['word'] = word
            sugg['abbr'] = word
        return suggestions

    @_log
    def on_doc(self, items, _no_doc='No documentation available'):
        doc = self._load_data_from(items, '')
        # Check if doc available, if not and starts with ':', use erl -man.
        lines = doc.split('\n')
        if len(lines) > 2 and _no_doc == lines[2] and lines[0].startswith(':'):
            erlmod = lines[0][1:].split('.')[0]
            doc = _exec_cmd('erl -man ' + erlmod) or doc
        return [doc]

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
        for item in items:
            if not item:
                break

            # Ignore the fucking warning message from elixir-lang..
            try:
                data = json.loads(item)
            except json.JSONDecodeError:
                logger.warn('json decode failed: %r', item)
                continue

            errmsg = data.get('error', None)
            if errmsg is not None:
                logger.warn('error response: %r', errmsg)
                return default
            return data.get('data', default)

        logger.warn('no response data found')
        return default


def _exec_cmd(cmd):
    try:
        out = subprocess.check_output(cmd, shell=True)
        return _rm0x08(out)
    except subprocess.CalledProcessError:
        return None


def _rm0x08(content, _p=re.compile(b'.{1}\x08')):
    return _p.sub(b'', content)
