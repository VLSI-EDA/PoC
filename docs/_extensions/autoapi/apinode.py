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
Module that provides the module tree node :class:`APINode`.

This class will load the module identified by ``name`` and recursively build a
tree with all it's submodules and subpackages. In the process, each node
analyze and fetch the public API of that module.

``name`` can be any node, like the root package, or any subpackage or submodule
and a tree will be built from there. ``name`` must follow the standard
"dot notation" for importing a module.

This class will not assume any special naming, or perform any complex analysis
to determine what must be in the public interface. This is because it is not
only a difficult problem, but it involves analyzing deeply the namespace of the
module which can be quite expensive.

In general it is very difficult to determine in a module namespace what
elements are private or public declared locally, private or public but declared
in another module and brought into the module local namespace
(``from x import y``), third party library, Python standard library, etc. At
the end, any algorithm that tries to determine this will eventually fail to
meet the requirements or expectations of the developer, leaving false positives
or removing elements expected to be present in the public API.

For example, a common scenario is that some modules, specially package entry
points ``__init__.py``, can be setup to expose the public API of their sibling
modules, possible causing several objects to be identified as part of the
public API of both modules.

Because of this the approach taken by this module follows the rule in PEP20
"Explicit is better than implicit". In consequence, the node will consider
elements as public if they are explicitly listed in the ``__api__`` or
``__all__`` variables. It is up to the developer to list the elements that must
be published in the public API.

``__api__`` is a special variable introduced by this module, and it exists for
situation were for whatever reason the developer don't want to list in the
``__all__`` variable an element that needs to be published in the public API.

This class will extract all elements identified in ONE of those listings (not
the union), with ``__api__`` having the precedence. If none of those variables
exists in the module then it will be assumed that no public API exists for that
module and no futher actions will be taken.

If any of those variables exists this class will iterate all elements listed in
them and will catalog them in four categories:

- Functions.
- Exceptions.
- Classes.
- Variables.

Being Variables the default if it cannot be determined that an element belongs
to any of other categories.
"""

from __future__ import unicode_literals, absolute_import
from __future__ import print_function, division

from logging import getLogger
from traceback import format_exc
from importlib import import_module
from pkgutil import iter_modules
from inspect import isclass, isfunction
from collections import OrderedDict


log = getLogger(__name__)


class APINode(object):
    """
    Tree node class for module instrospection.

    :param str name: Name of the module to build the tree from. It must follow
     the "dot notation" of the import mechanism.
    :param dict directory: Directory to store the index of all the modules.
     If None, the default, the root node will create one a pass it to the
     subnodes.

    **Attributes:**

    :var name: Name of the current module.
    :var subname: Last part of the name of this module. For example if name is
     ``my.module.another`` the subname will be ``another``.
    :var directory: Directory of the tree. This is a :py:class:`OrderedDict`
     that will register all modules name with it's associated node
     :class:`APINode`. All nodes of a tree share this index and thus
     the whole tree can be queried from any node.
    :var module: The loaded module.
    :var subnodes: A list of :class:`APINode` with all child submodules
     and subpackages.
    :var subnodes_failed: A list of submodules and subpackages names that
     failed to import.

    **Public API categories:**

    :var functions: A :py:class:`OrderedDict` of all functions found in the
     public API of the module.
    :var classes: A :py:class:`OrderedDict` of all classes found in the
     public API of the module.
    :var exceptions: A :py:class:`OrderedDict` of all exceptions found in the
     public API of the module.
    :var variables: A :py:class:`OrderedDict` of all other elements found in
     the public API of the module.

    In all categories the order on which the elements are listed is preserved.
    """

    def __init__(self, name, directory=None):
        self.module = import_module(name)
        self.name = name
        self.subname = name.split('.')[-1]

        self.functions = OrderedDict()
        self.classes = OrderedDict()
        self.exceptions = OrderedDict()
        self.variables = OrderedDict()
        self.api = OrderedDict((
            ('functions', self.functions),
            ('classes', self.classes),
            ('exceptions', self.exceptions),
            ('variables', self.variables),
        ))

        self.subnodes = []
        self.subnodes_failed = []

        self.directory = OrderedDict()
        if directory is not None:
            self.directory = directory

        self._relevant = None

        # Now that all node public attributes exists and module was imported
        # register itself in the directory
        self.directory[self.name] = self

        # Check if package and iterate over subnodes
        if hasattr(self.module, '__path__'):
            for _, subname, ispkg in iter_modules(
                    self.module.__path__, self.module.__name__ + '.'):
                log.info('Recursing into {}'.format(subname))

                try:
                    subnode = APINode(subname, self.directory)
                    self.subnodes.append(subnode)
                except:  # Overbroad exception handling on purpose
                    log.error('Failed to import {}'.format(subname))
                    log.debug(format_exc())
                    self.subnodes_failed.append(subname)

        # Fetch all public objects
        public = OrderedDict()
        for public_key in ['__api__', '__all__']:
            if not hasattr(self.module, public_key):
                continue

            for obj_name in getattr(self.module, public_key):
                if not hasattr(self.module, obj_name):
                    log.warning(
                        'Module {} doesn\'t have a element {}'.format(
                            self.name, obj_name
                        )
                    )
                    continue
                public[obj_name] = getattr(self.module, obj_name)
            break

        # Categorize objects
        for obj_name, obj in public.items():
            if isclass(obj):
                if issubclass(obj, Exception):
                    self.exceptions[obj_name] = obj
                    continue
                self.classes[obj_name] = obj
                continue
            if isfunction(obj):
                self.functions[obj_name] = obj
                continue
            self.variables[obj_name] = obj

        # Flag to mark if this branch is relevant
        # For self._relevant, None means undertermined
        if self.is_root():
            self.is_relevant()

    def has_public_api(self):
        """
        Check if this node has a public API.

        :rtype: bool
        :return: True if any category has at least one element.
        """
        return any(self.api.values())

    def is_leaf(self):
        """
        Check if the current node is a leaf in the tree.

        A leaf node not necessarily is a module, it can be a package without
        modules (just the entry point ``__init__.py``).

        :rtype: bool
        :return: True if no other subnodes exists for this node.
        """
        return not self.subnodes

    def is_root(self):
        """
        Check if the current node is the root node.

        :rtype: bool
        :return: True if the current node is the root node.
        """
        for key in self.directory.keys():
            return key == self.name
        raise Exception('Empty directory!')

    def is_relevant(self):
        """
        Check if this branch of the tree is relevant.

        A branch is relevant if the current node has a public API or if any of
        its subnodes is relevant (in order to reach relevant nodes).

        Relevancy is determined at initialization by the root node.

        :rtype: bool
        :return: True if the current node is relevant.
        """
        if self._relevant is not None:
            return self._relevant

        relevant = False
        if self.has_public_api() or \
                any(s.is_relevant() for s in self.subnodes):
            relevant = True

        self._relevant = relevant

        return self._relevant

    def depth(self):
        """
        Get the depth of the current node in the tree.

        :rtype: int
        :return: The depth of the node. For example, for node ``my.add.foo``
         the depth is 3.
        """
        return len(self.name.split('.'))

    def get_module(self, name):
        """
        Get a module node by it's name.

        This is just a helper that does lookup on the directory index.

        :rtype: :class:`APINode` or None
        :return: The module node identified by ``name`` in the tree. ``None``
         if the name doesn't exists.
        """
        return self.directory.get(name, None)

    def walk(self):
        """
        Traverse the tree top-down.

        :return: This method will yield tuples ``(node, [leaves])`` for each
         node in the tree.
        """
        if self.is_leaf():
            raise StopIteration()

        yield (self, [n for n in self.subnodes if n.is_leaf()])

        for subnode in [n for n in self.subnodes if not n.is_leaf()]:
            for step in subnode.walk():
                yield step

    def __iter__(self):
        return self.walk

    def tree(self, level=0, fullname=True):
        """
        Pretty print the subtree at the current node.

        For example, for the module ``confspec``:

        ::

           confspec
               confspec.manager [c]
               confspec.options [c]
               confspec.providers [c, v]
                   confspec.providers.dict [c]
                   confspec.providers.ini [c]
                   confspec.providers.json [c]
               confspec.utils [f]
               confspec.validation [f]

        The tags at the right of the name shows what kind of elements are
        present in the public interfaces of those modules.

        :param int level: Indentation level.
        :param bool fullname: Plot the full name of the module or just it's
         subname.
        """
        name = [('    ' * level)]
        if fullname:
            name.append(self.name)
        else:
            name.append(self.subname)

        tags = []
        for tag, category in zip(['f', 'c', 'e', 'v'], self.api.values()):
            if category:
                tags.append(tag)
        if tags:
            name.append(' [{}]'.format(', '.join(tags)))

        output = [''.join(name)]
        for subnode in self.subnodes:
            output.append(subnode.tree(level=level + 1, fullname=fullname))
        return '\n'.join(output)

    def __str__(self):
        return self.tree()

    def __repr__(self):
        return self.name


__all__ = ['APINode']
__api__ = []
