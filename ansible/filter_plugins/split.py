#!/usr/bin/python

from functools import partial
from ansible.module_utils.six import text_type
from ansible.utils.unicode import unicode_wrap

class FilterModule(object):
    def filters(self):
        return {
            'split': partial(unicode_wrap, text_type.split),
        }
