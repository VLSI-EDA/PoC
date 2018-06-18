# -*- coding: utf-8 -*-
#
# Copyright (C) 2015 Carlos Jenkins <carlos@jenkins.co.cr>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

"""
Glue for Sphinx API.
"""

from __future__ import unicode_literals, absolute_import
from __future__ import print_function, division

from inspect    import getdoc
from logging    import getLogger
from traceback  import format_exc
from os.path    import join, dirname, abspath, exists
from os         import environ

from jinja2.sandbox     import SandboxedEnvironment
from sphinx.util.osutil import ensuredir
from sphinx.jinja2glue  import BuiltinTemplateLoader

from . import __version__
from .apinode import APINode


log = getLogger(__name__)


def handle_exception(func):
    """
    Utility decorator to report all exceptions in module without making Sphinx
    to die.
    """
    def wrapper(app):
        try:
            func(app)
        except Exception:
            app.warn(
                'Unhandled exception in autoapi module: \n{}'.format(
                    format_exc()
                )
            )

    # Preserve docstring
    if hasattr(func, '__doc__'):
        wrapper.__doc__ = func.__doc__

    return wrapper


def filter_summary(obj):
    """
    Jinja2 filter that allows to extract the documentation summary of an
    object.
    """
    try:
        doc = getdoc(obj)
        if doc is None:
            return 'Undocumented.'

        summary = doc.split('\n').pop(0)
        summary.replace('\\', '\\\\')  # Escape backslash in RST
        return summary
    except:
        log.error(
            'AutoApi failed to determine autosummary for obj: {}'.format(obj)
        )
        log.error(format_exc())

    return 'AutoApi: Unable to determine summary.'


def get_template_env(app):
    """
    Get the template environment.

    .. note::

       Template should be loaded as a package_data using
       :py:function:`pkgutil.get_data`, but because we want the user to
       override the default template we need to hook it to the Sphinx loader,
       and thus a file system approach is required as it is implemented like
       that.
    """
    template_dir = [join(dirname(abspath(__file__)), 'templates')]
    template_loader = BuiltinTemplateLoader()
    template_loader.init(app.builder, dirs=template_dir)
    template_env = SandboxedEnvironment(loader=template_loader)
    template_env.filters['summary'] = filter_summary
    return template_env


@handle_exception
def builder_inited(app):
    """
    autoapi Sphinx extension hook for the ``builder-inited`` event.

    This hook will read the configuration value ``autoapi_modules`` and render
    the modules described in it.

    See http://sphinx-doc.org/extdev/appapi.html#event-builder-inited
    """
    # Get modules to build documentation for
    modules = app.config.autoapi_modules
    if not modules:
        return

    # Overwrite all files in an ReadTheDocs environment when the first builder runs (pickle)
    overrideDefault = True
    if (environ.get('READTHEDOCS') == "True"):
      #if (app.buildername != "pickle"):
        overrideDefault = False

    # Get template environment
    template_env = get_template_env(app)

    print("===============================")
    print("overrideDefault set to: {0!s}".format(overrideDefault))
    print("===============================")

    for module, overrides in modules.items():

        # Get options
        options = {
            'prune': False,
            'override': overrideDefault,
            'template': 'module',
            'output': module
        }
        if overrides:
            options.update(overrides)

        # Get template
        template = template_env.get_template(
            'autoapi/{}.rst'.format(options['template'])
        )

        # Build API tree
        tree = APINode(module)

        # Gather nodes to document
        if options['prune']:
            nodes = [
                node for node in tree.directory.values()
                if node.is_relevant()
            ]
        else:
            nodes = tree.directory.values()

        if not nodes:
            continue

        # Define output directory
        out_dir = join(app.env.srcdir, options['output'])
        ensuredir(out_dir)

        # Iterate nodes and render them
        for node in nodes:
            out_file = join(out_dir, node.name + app.config.source_suffix[0])

            # Skip file if it override is off and it exists
            if not options['override'] and exists(out_file):
                continue

            # Consider only subnodes that are relevant if prune is enabled
            subnodes = node.subnodes
            if options['prune']:
                subnodes = [
                    subnode for subnode in node.subnodes
                    if subnode.is_relevant()
                ]

            # Write file
            with open(out_file, 'w') as fd:
                fd.write(
                    template.render(
                        node=node,
                        subnodes=subnodes
                    )
                )


def setup(app):
    """
    autoapi Sphinx extension setup.

    See http://sphinx-doc.org/extdev/tutorial.html#the-setup-function
    """
    # autodoc is required
    app.setup_extension('sphinx.ext.autodoc')
    app.add_config_value('autoapi_modules', {}, True)
    app.connect(str('builder-inited'), builder_inited)
    return {'version': __version__}


__all__ = ['builder_inited', 'setup']
